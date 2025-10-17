/// Contact API models matching backend Pydantic schemas
/// These models are used for communication with the EPANSA backend

/// Contact metadata matching backend ContactMetadata
class ContactMetadata {
  final String name;
  final String telephoneNumber;

  ContactMetadata({
    required this.name,
    required this.telephoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'telephone_number': telephoneNumber,
    };
  }

  factory ContactMetadata.fromJson(Map<String, dynamic> json) {
    return ContactMetadata(
      name: json['name'] as String,
      telephoneNumber: json['telephone_number'] as String,
    );
  }
}

/// Contact payload matching backend ContactPayload
class ContactPayload {
  final String contact; // Contact ID (uses alias "contact" in backend)
  final String sourceApp;
  final ContactMetadata metadata;
  final String kind;

  ContactPayload({
    required this.contact,
    required this.sourceApp,
    required this.metadata,
    this.kind = 'contact',
  });

  Map<String, dynamic> toJson() {
    return {
      'contact': contact,
      'source_app': sourceApp,
      'metadata': metadata.toJson(),
      'kind': kind,
    };
  }

  factory ContactPayload.fromJson(Map<String, dynamic> json) {
    return ContactPayload(
      contact: json['contact'] as String,
      sourceApp: json['source_app'] as String,
      metadata: ContactMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      kind: json['kind'] as String? ?? 'contact',
    );
  }
}
