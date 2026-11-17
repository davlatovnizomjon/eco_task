import 'package:eco_task/domain/common/enums/legal_kind.dart';
import 'package:eco_task/helpers/response_helper.dart';

import '../common/api_links.dart';
import '../common/dio_client.dart';
import '../dto/models/legal_document.dart';

/// Source of the legal texts (terms of use, privacy policy) the sign-in screen shows. Each text is fetched once per app
/// language and then served from memory; a missing or failed answer is not remembered, so the next opening asks again.
class LegalRepository {
  /// Fetched documents by `<language>|<kind>`.
  final Map<String, LegalDocument> _cache = {};

  /// Cache key of [kind] in the language the API is currently asked in.
  String _key(LegalKind kind) => '${DioClient.language}|${kind.name}';

  /// The document fetched earlier in this language, or null when the sheet still has to ask the backend.
  LegalDocument? cached(LegalKind kind) => _cache[_key(kind)];

  /// Fetches [kind]. A backend with that text not published (404) answers null so the sheet can show its empty state;
  /// every other failure propagates.
  Future<LegalDocument?> get(LegalKind kind) async {
    final key = _key(kind);
    try {
      final response = await dioClient.get(kind == LegalKind.terms ? ApiLinks.legalTerms : ApiLinks.legalPrivacy);
      return _cache[key] = LegalDocument.fromJson(response.data as Map<String, dynamic>);
    } on MessageErrorResponse catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
