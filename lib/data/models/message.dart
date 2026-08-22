enum MessageType {
  text
}

class Message {
  final MessageType type;
  final String? text;
  final bool fromDocuments;
  final int docReferenceCount;

  Message._({
    required this.type,
    this.text,
    this.fromDocuments = false,
    this.docReferenceCount = 0,
  });

  factory Message.text(
    String? text, {
    bool fromDocuments = false,
    int docReferenceCount = 0,
  }) {
    return Message._(
      type: MessageType.text,
      text: text,
      fromDocuments: fromDocuments,
      docReferenceCount: docReferenceCount,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message.text(
      json['text'] as String?,
      fromDocuments: json['from_documents'] as bool? ?? false,
      docReferenceCount: json['doc_reference_count'] as int? ?? 0,
    );
  }
}
