import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

/// Repository for managing contacts locally
/// Stores contacts in SharedPreferences
class ContactRepository {
  static const String _contactsKey = 'contacts';
  static const String _lastSyncKey = 'contacts_last_sync';

  /// Get all contacts
  Future<List<Contact>> getAllContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList(_contactsKey) ?? [];
    
    return contactsJson
        .map((json) => Contact.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  /// Get a single contact by ID
  Future<Contact?> getContact(String id) async {
    final contacts = await getAllContacts();
    try {
      return contacts.firstWhere((contact) => contact.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save a contact (create or update)
  Future<void> saveContact(Contact contact) async {
    final contacts = await getAllContacts();
    
    // Remove existing contact with same ID if present
    contacts.removeWhere((c) => c.id == contact.id);
    
    // Add the contact
    contacts.add(contact);
    
    // Save to storage
    await _saveAllContacts(contacts);
  }

  /// Save multiple contacts (bulk operation)
  Future<void> saveContacts(List<Contact> newContacts) async {
    final existingContacts = await getAllContacts();
    
    // Create a map of existing contacts by ID for quick lookup
    final contactMap = {for (var c in existingContacts) c.id: c};
    
    // Update or add new contacts
    for (var contact in newContacts) {
      contactMap[contact.id] = contact;
    }
    
    // Save all contacts
    await _saveAllContacts(contactMap.values.toList());
  }

  /// Delete a contact
  Future<void> deleteContact(String id) async {
    final contacts = await getAllContacts();
    contacts.removeWhere((contact) => contact.id == id);
    await _saveAllContacts(contacts);
  }

  /// Clear all contacts
  Future<void> clearAllContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_contactsKey);
    await prefs.remove(_lastSyncKey);
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  /// Get contacts count
  Future<int> getContactsCount() async {
    final contacts = await getAllContacts();
    return contacts.length;
  }

  /// Check if a contact exists
  Future<bool> contactExists(String id) async {
    final contact = await getContact(id);
    return contact != null;
  }

  /// Get only unsynced contacts (not yet sent to backend)
  Future<List<Contact>> getUnsyncedContacts() async {
    final allContacts = await getAllContacts();
    return allContacts.where((contact) => !contact.isSyncedToBackend).toList();
  }

  /// Mark a contact as synced to backend
  Future<void> markAsSynced(String contactId) async {
    final contact = await getContact(contactId);
    if (contact != null) {
      final syncedContact = contact.copyWith(
        isSyncedToBackend: true,
        lastSyncedAt: DateTime.now(),
      );
      await saveContact(syncedContact);
    }
  }

  /// Mark multiple contacts as synced (bulk operation)
  Future<void> markMultipleAsSynced(List<String> contactIds) async {
    final contacts = await getAllContacts();
    final updatedContacts = contacts.map((contact) {
      if (contactIds.contains(contact.id)) {
        return contact.copyWith(
          isSyncedToBackend: true,
          lastSyncedAt: DateTime.now(),
        );
      }
      return contact;
    }).toList();
    
    await _saveAllContacts(updatedContacts);
  }

  // Private helper to save all contacts
  Future<void> _saveAllContacts(List<Contact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = contacts
        .map((contact) => jsonEncode(contact.toJson()))
        .toList();
    await prefs.setStringList(_contactsKey, contactsJson);
  }
}
