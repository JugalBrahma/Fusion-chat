enum MessageType {
  text
}

class Mcq {
  final String question;
  final List<String> options;
  final String answer;

  const Mcq({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory Mcq.fromJson(Map<String, dynamic> json) {
    return Mcq(
      question: json['question'] as String? ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answer': answer,
      };
}

class Message {
  final MessageType type;
  final String? text;
  final String? processing_time;
  final bool mcqIsTrue;
  final List<Mcq> mcqs;
  final bool fromDocuments;
  final int docReferenceCount;

  Message._({
    required this.type,
    this.text,
    this.processing_time,
    this.mcqIsTrue = false,
    List<Mcq>? mcqs,
    this.fromDocuments = false,
    this.docReferenceCount = 0,
  }) : mcqs = mcqs ?? const [];

  factory Message.text(
    String? text, {
    String? processing_time,
    bool mcqIsTrue = false,
    List<Mcq>? mcqs,
    bool fromDocuments = false,
    int docReferenceCount = 0,
  }) {
    return Message._(
      type: MessageType.text,
      text: text,
      processing_time: processing_time,
      mcqIsTrue: mcqIsTrue,
      mcqs: mcqs,
      fromDocuments: fromDocuments,
      docReferenceCount: docReferenceCount,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message.text(
      json['text'] as String?,
      processing_time: json['processing_time'] as String?,
      mcqIsTrue: json['mcq_is_true'] as bool? ?? false,
      mcqs: (json['mcqs'] as List?)
              ?.map((e) => Mcq.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
