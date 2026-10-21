import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/dialog_icon.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'dialog_helpers.dart';

/// Base of every typed outcome the network layer throws and the UI presents.
/// Blocs store it in their state's `response` field; nothing above the
/// repository ever sees a `DioException` or a raw map.
sealed class ScreenResponse {
  /// Allows the subtypes to have const constructors.
  const ScreenResponse();
}

/// 401 — the token was rejected and has already been cleared; the user must
/// sign in again.
final class UnAuthorizedResponse extends ScreenResponse {
  /// Builds the unauthorized outcome.
  const UnAuthorizedResponse();
}

/// 403 — the account is valid but lacks the permission for this action.
final class ForbiddenResponse extends ScreenResponse {
  /// Builds the forbidden outcome.
  const ForbiddenResponse();
}

/// The device could not reach the server (timeout, no network, bad cert).
final class ConnectionErrorResponse extends ScreenResponse {
  /// Builds the connection outcome.
  const ConnectionErrorResponse();
}

/// 5xx — the backend failed while handling a well-formed request.
final class ServerErrorResponse extends ScreenResponse {
  /// Builds the server-error outcome.
  const ServerErrorResponse();
}

/// Anything the client could not classify.
final class UnExpectedErrorResponse extends ScreenResponse {
  /// Builds the fallback outcome.
  const UnExpectedErrorResponse();
}

/// 400 — a field-level validation failure. The screen shows [message] under
/// the offending field instead of opening a dialog over the form.
final class ValidationErrorResponse extends ScreenResponse {
  /// Backend `detail` text, already human-readable.
  final String message;

  /// Builds a validation outcome carrying the backend's `detail`.
  const ValidationErrorResponse(this.message);
}

/// 404/409 and other 4xx — carries the backend's RFC 7807 `detail`, which is
/// shown verbatim. The app never invents its own wording for these.
final class MessageErrorResponse extends ScreenResponse {
  /// Backend `detail` text, already human-readable.
  final String message;

  /// Optional extra line rendered in the dialog's highlighted block.
  final String? description;

  /// HTTP status the failure came from, so a screen can react to the CODE
  /// (404 vs 409) instead of pattern-matching the message text. Null when
  /// the failure was raised locally rather than by the backend.
  final int? statusCode;

  /// Builds a message outcome from the backend's `detail`.
  const MessageErrorResponse(this.message, {this.description, this.statusCode});
}

/// A completed action worth confirming to the user.
final class MessageSuccessResponse extends ScreenResponse {
  /// Text shown as the dialog body.
  final String message;

  /// Optional extra line rendered in the dialog's highlighted block.
  final String? description;

  /// Builds a success outcome.
  const MessageSuccessResponse(this.message, {this.description});
}

/// Plain text of [response], for UI that shows a failure inline — under a
/// form field or inside a sheet, where a second dialog would cover what the
/// user is reading.
String screenResponseText(ScreenResponse response) => switch (response) {
  ValidationErrorResponse() => response.message,
  MessageErrorResponse() => response.message,
  MessageSuccessResponse() => response.message,
  UnAuthorizedResponse() => TrWords.msgLoginRequired.tr(),
  ForbiddenResponse() => TrWords.msgForbidden.tr(),
  ConnectionErrorResponse() => TrWords.msgConnection.tr(),
  ServerErrorResponse() => TrWords.msgServer.tr(),
  UnExpectedErrorResponse() => TrWords.msgUnexpected.tr(),
};

/// Shows [response] in the matching dialog — the single presenter every
/// screen uses, so no feature branches on the failure type itself.
///
/// [onTap] runs after the dialog closes. For an expired session it defaults
/// to sending the user to sign-in, because the 401 already cleared the token.
/// [onRetry], when given, adds a retry button to the connection-error dialog.
void showScreenResponse(BuildContext context, ScreenResponse response, {VoidCallback? onTap, VoidCallback? onRetry}) {
  switch (response) {
    case UnAuthorizedResponse():
      showCenterDialog(
        PublicDialog(
          title: TrWords.msgTitleError.tr(),
          subTitle: TrWords.msgLoginRequired.tr(),
          activeBtnText: TrWords.cOk.tr(),
          onActiveBtnPressed: onTap ?? () => context.go(Routes.signIn.path),
        ),
        context,
        isCancelable: false,
      );
    case ConnectionErrorResponse():
      showCenterDialog(
        PublicDialog(
          title: TrWords.msgTitleError.tr(),
          subTitle: TrWords.msgConnection.tr(),
          unActiveBtnText: onRetry == null ? null : TrWords.cClose.tr(),
          activeBtnText: onRetry == null ? TrWords.cOk.tr() : TrWords.cRetry.tr(),
          onActiveBtnPressed: onRetry ?? onTap,
        ),
        context,
      );
    case MessageSuccessResponse():
      showCenterDialog(
        PublicDialog(
          icon: DialogIcon.green(),
          title: TrWords.msgTitleSuccess.tr(),
          subTitle: response.message,
          warningText: response.description,
          activeBtnText: TrWords.cOk.tr(),
          onActiveBtnPressed: onTap,
        ),
        context,
      );
    case ValidationErrorResponse():
    case ForbiddenResponse():
    case ServerErrorResponse():
    case UnExpectedErrorResponse():
    case MessageErrorResponse():
      showCenterDialog(
        PublicDialog(
          title: TrWords.msgTitleError.tr(),
          subTitle: screenResponseText(response),
          warningText: response is MessageErrorResponse ? response.description : null,
          activeBtnText: TrWords.cOk.tr(),
          onActiveBtnPressed: onTap,
        ),
        context,
      );
  }
}
