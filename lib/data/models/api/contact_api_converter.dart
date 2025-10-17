import '../contact.dart';
import 'contact_api_models.dart';

/// Converter to transform local Contact model to backend ContactPayload
class ContactApiConverter {
  /// Convert a local Contact to API ContactPayload
  static ContactPayload toApiPayload(Contact contact) {
    return ContactPayload(
      contact: contact.id,
      sourceApp: 'epansa_app',
      metadata: ContactMetadata(
        name: contact.name,
        telephoneNumber: contact.phoneNumber,
      ),
      kind: 'contact',
    );
  }

  /// Convert API ContactPayload to local Contact
  /// Note: This is mainly for consistency; typically we read contacts from device
  static Contact fromApiPayload(ContactPayload payload) {
    final now = DateTime.now();
    return Contact(
      id: payload.contact,
      name: payload.metadata.name,
      phoneNumber: payload.metadata.telephoneNumber,
      createdAt: now,
      updatedAt: now,
    );
  }
}
