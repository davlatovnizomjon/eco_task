import 'package:eco_task/helpers/response_helper.dart';

import '../common/api_links.dart';
import '../common/dio_client.dart';
import '../dto/models/support_contact.dart';

/// Source of the dispatcher contacts the sign-in help sheet shows. The contacts are fetched once per app run and then
/// served from memory; an empty answer or a failure is not remembered, so the next opening asks again.
class SupportRepository {
  /// Contacts of the last successful, non-empty answer; null until one arrives.
  SupportContact? _cached;

  /// Contacts already fetched in this run, or null when the sheet still has to ask the backend.
  SupportContact? get cached => _cached;

  /// Fetches the published contacts. A backend with none published (404) is not a failure: it answers
  /// [SupportContact.none] so the sheet can show its empty state. Every other failure propagates.
  Future<SupportContact> getContact() async {
    try {
      final response = await dioClient.get(ApiLinks.supportContact);
      final contact = SupportContact.fromJson(response.data as Map<String, dynamic>);
      if (!contact.isEmpty) _cached = contact;
      return contact;
    } on MessageErrorResponse catch (e) {
      if (e.statusCode == 404) return SupportContact.none;
      rethrow;
    }
  }
}
