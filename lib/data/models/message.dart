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
  final Map<String, dynamic>? usage;
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  Message._({
    required this.type,
    this.text,
    this.processing_time,
    this.mcqIsTrue = false,
    List<Mcq>? mcqs,
    this.fromDocuments = false,
    this.docReferenceCount = 0,
    this.usage,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  }) : mcqs = mcqs ?? const [];

  factory Message.text(
    String? text, {
    String? processing_time,
    bool mcqIsTrue = false,
    List<Mcq>? mcqs,
    bool fromDocuments = false,
    int docReferenceCount = 0,
    Map<String, dynamic>? usage,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
  }) {
    return Message._(
      type: MessageType.text,
      text: text,
      processing_time: processing_time,
      mcqIsTrue: mcqIsTrue,
      mcqs: mcqs,
      fromDocuments: fromDocuments,
      docReferenceCount: docReferenceCount,
      usage: usage,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    final usage = _toStringKeyedMap(json['usage']);

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Get token counts from usage['totals'] or usage['answer']
    final usageTotals = _toStringKeyedMap(usage?['totals']) ??
        _toStringKeyedMap(usage?['answer']);

    final promptTokens = json['prompt_tokens'] as int? ??
        parseInt(usageTotals?['prompt_tokens']);
    final completionTokens = json['completion_tokens'] as int? ??
        parseInt(usageTotals?['completion_tokens']);
    final totalTokens = json['total_tokens'] as int? ??
        parseInt(usageTotals?['total_tokens']);

    return Message.text(
      json['text'] as String?,
      processing_time: json['processing_time'] as String?,
      mcqIsTrue: json['mcq_is_true'] as bool? ?? false,
      mcqs: (json['mcqs'] as List?)
              ?.map((e) => Mcq.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      usage: usage,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
    );
  }

  static Map<String, dynamic>? _toStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, v) => MapEntry(key.toString(), v));
    }
    return null;
  }
}
