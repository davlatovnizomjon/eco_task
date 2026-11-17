import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:eco_task/helpers/response_helper.dart';

import '../repository/session_repository.dart';
import 'api_links.dart';

/// The single wrapped HTTP client every repository calls. Assigned once in
/// `main()` — either a real [DioClient] or the offline [MockDioClient].
late DioClient dioClient;

/// Wraps Dio so repositories only ever see the happy path: this class
/// attaches the bearer token, and converts every transport/HTTP failure into
/// a typed [ScreenResponse] that the bloc catches and the UI presents.
///
/// The Django backend answers every error as `{"error": {"code", "message"}}`
/// (`message` is a sentence in the `Accept-Language` language, or a field-to-messages map for validation errors).
/// The older RFC 7807 shape (`{title, status, detail}`) is still understood, as
/// the mock backend emits it. The wording is written for humans, so it is
/// surfaced verbatim rather than replaced with text invented here.
class DioClient {
  /// Session the token is read from, and cleared on a 401.
  final SessionRepository session;

  /// Wraps [session]; the underlying Dio is built lazily on first use.
  DioClient(this.session);

  /// Backing Dio instance, created on first access.
  Dio? _dio;

  /// Configured Dio instance — base URL, timeouts and the debug logger.
  Dio get dio {
    if (_dio != null) return _dio!;
    final instance = Dio(
      BaseOptions(
        baseUrl: ApiLinks.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {HttpHeaders.acceptHeader: 'application/json'},
      ),
    );
    instance.interceptors.add(
      PrettyDioLogger(
        requestHeader: kDebugMode,
        requestBody: kDebugMode,
        responseBody: kDebugMode,
        responseHeader: false,
        error: kDebugMode,
      ),
    );
    return _dio = instance;
  }

  /// Issues a `GET` and returns the raw response for the caller to parse.
  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) =>
      request(path, queryParameters: queryParameters);

  /// Issues a `POST`; pass a `FormData` [data] for multipart uploads.
  Future<Response<dynamic>> post(String path, {Object? data}) => request(path, method: 'POST', data: data);

  /// Issues a `PATCH`.
  Future<Response<dynamic>> patch(String path, {Object? data}) => request(path, method: 'PATCH', data: data);

  /// Downloads a file as bytes (authorized like every other call); used for photos and documents.
  Future<List<int>> bytes(String path) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes, headers: authHeaders()),
      );
      return response.data ?? const [];
    } on DioException catch (e) {
      throw await mapError(e);
    }
  }

  /// Issues a `PUT`.
  Future<Response<dynamic>> put(String path, {Object? data}) => request(path, method: 'PUT', data: data);

  /// Issues a `DELETE`.
  Future<Response<dynamic>> delete(String path, {Object? data}) => request(path, method: 'DELETE', data: data);

  /// Performs the request and translates any failure into a
  /// [ScreenResponse]. Repositories never catch — they read the happy path
  /// off the returned response and let this throw through to the bloc.
  Future<Response<dynamic>> request(
    String path, {
    String method = 'GET',
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final sentToken = session.token;
    try {
      return await _send(path, method, data, queryParameters);
    } on DioException catch (e) {
      if (e.response?.statusCode != 401 || !session.canRefresh || _authPaths.contains(e.requestOptions.path)) {
        throw await mapError(e);
      }
      // The access token expired: renew the pair once (unless another request already did) and replay the call.
      if (session.token == sentToken) await session.refreshTokens();
      try {
        return await _send(path, method, data, queryParameters);
      } on DioException catch (retry) {
        throw await mapError(retry);
      }
    }
  }

  /// One raw Dio round trip carrying the session's current token.
  Future<Response<dynamic>> _send(String path, String method, Object? data, Map<String, dynamic>? queryParameters) =>
      dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: authHeaders(),
          contentType: data is FormData ? 'multipart/form-data' : null,
        ),
      );

  /// UI language tag (`uz`, `uz-Cyrl`, `ru`) sent as `Accept-Language`; the app root keeps it in step with the locale.
  static String language = 'uz';

  /// Headers sent with every request: the bearer token once signed in, plus
  /// the UI language so the backend localizes its `detail` text.
  @protected
  Map<String, String> authHeaders() {
    final headers = <String, String>{HttpHeaders.acceptHeader: 'application/json', 'Accept-Language': language};
    final token = session.token;
    if (token.isNotEmpty) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  /// The sign-in endpoint. A 401 from it is a credential answer, not an
  /// expired session — there is nothing to clear and the router must stay on
  /// the form.
  static const _loginPaths = {ApiLinks.authLogin, '${ApiLinks.authLogin}/'};

  /// Sign-in and refresh calls: a 401 from them never triggers another refresh.
  static const _authPaths = {..._loginPaths, ApiLinks.authRefresh, '${ApiLinks.authRefresh}/'};

  /// Turns a [DioException] into the typed failure the UI knows how to show.
  /// A 401 clears the session here — except on a sign-in call, where it
  /// means bad credentials — so the presenter only has to navigate.
  /// `MockDioClient` routes its scripted failures through this same method,
  /// so offline error handling matches the live one exactly.
  @protected
  Future<ScreenResponse> mapError(DioException e) async {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.badCertificate:
        return const ConnectionErrorResponse();
      case DioExceptionType.cancel:
      case DioExceptionType.badResponse:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        break;
    }

    final status = e.response?.statusCode ?? 0;
    final detail = problemDetail(e.response?.data);
    // A 401 from the sign-in call itself means "wrong credentials", not an
    // expired session, so the backend's wording is shown as a plain message.
    if (status == 401 && _loginPaths.contains(e.requestOptions.path)) {
      return detail == null ? const UnExpectedErrorResponse() : MessageErrorResponse(detail, statusCode: status);
    }
    if (status == 401) {
      await session.clearSession(revokeRemotely: false);
      return const UnAuthorizedResponse();
    }
    if (status == 403) return const ForbiddenResponse();
    if (status >= 500) return const ServerErrorResponse();

    if (detail == null) return const UnExpectedErrorResponse();
    return status == 400 ? ValidationErrorResponse(detail) : MessageErrorResponse(detail, statusCode: status);
  }

  /// Extracts the human-readable text out of an RFC 7807 body, falling back
  /// to the field errors and finally to `title`. Returns null when the body
  /// carries no wording, so the caller can use the app's generic message.
  @protected
  String? problemDetail(Object? body) {
    if (body is! Map) return null;
    final envelope = body['error'];
    if (envelope is Map) return _envelopeDetail(envelope['message']);
    for (final key in const ['detail', 'message']) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    // A model-validation body carries no `detail` at all: its wording sits
    // per field in `errors`, under a fixed English `title` — so the first
    // field message is read before falling back to that title.
    final fieldError = _firstFieldError(body['errors']);
    if (fieldError != null) return fieldError;
    final title = body['title'];
    return title is String && title.trim().isNotEmpty ? title.trim() : null;
  }

  /// Text of a Django `error.message`: a sentence, a list of sentences or a
  /// `{field: [messages]}` map (the first message wins).
  String? _envelopeDetail(Object? detail) {
    if (detail is String) return detail.trim().isEmpty ? null : detail.trim();
    if (detail is List && detail.isNotEmpty) return _envelopeDetail(detail.first);
    if (detail is Map && detail.isNotEmpty) return _envelopeDetail(detail.values.first);
    return null;
  }

  /// First message inside an ASP.NET `errors` map, or null when [errors] is
  /// not one or holds nothing readable.
  String? _firstFieldError(Object? errors) {
    if (errors is! Map) return null;
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty) {
        final first = '${value.first}'.trim();
        if (first.isNotEmpty) return first;
      }
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
