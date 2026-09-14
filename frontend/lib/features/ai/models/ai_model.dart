import 'package:flutter/material.dart';
import 'package:frontend/features/ingestion/models/ingestion_model.dart';

enum StudyModeEnum {
  chat('chat', 'Ask AI', Icons.chat_bubble_outline_rounded, Color(0xFF6366F1)),
  quiz('quiz', 'Practice Quiz', Icons.quiz_outlined, Color(0xFF0EA5E9)),
  flashcards('flashcards', 'Flashcards', Icons.style_outlined, Color(0xFFF59E0B)),
  summary('summary', 'Exam Summary', Icons.auto_stories_outlined, Color(0xFF10B981));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StudyModeEnum(this.value, this.label, this.icon, this.color);

  static StudyModeEnum fromString(String val) {
    return StudyModeEnum.values.firstWhere(
      (e) => e.value == val,
      orElse: () => StudyModeEnum.chat,
    );
  }
}

class CitationItemModel {
  final String chunkId;
  final String sourceId;
  final String sourceName;
  final SourceTypeEnum sourceType;
  final String? subjectId;
  final String? pageOrSection;
  final String snippet;
  final double similarityScore;

  CitationItemModel({
    required this.chunkId,
    required this.sourceId,
    required this.sourceName,
    required this.sourceType,
    this.subjectId,
    this.pageOrSection,
    required this.snippet,
    this.similarityScore = 0.0,
  });

  factory CitationItemModel.fromJson(Map<String, dynamic> json) {
    return CitationItemModel(
      chunkId: json['chunk_id'] ?? '',
      sourceId: json['source_id'] ?? '',
      sourceName: json['source_name'] ?? 'Course Document',
      sourceType: SourceTypeEnum.fromString(json['source_type'] ?? 'file'),
      subjectId: json['subject_id'],
      pageOrSection: json['page_or_section'],
      snippet: json['snippet'] ?? '',
      similarityScore: (json['similarity_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chunk_id': chunkId,
      'source_id': sourceId,
      'source_name': sourceName,
      'source_type': sourceType.value,
      'subject_id': subjectId,
      'page_or_section': pageOrSection,
      'snippet': snippet,
      'similarity_score': similarityScore,
    };
  }
}

class ChatMessageModel {
  final String role; // 'user' or 'assistant'
  final String content;
  final List<CitationItemModel> citations;
  final DateTime createdAt;

  ChatMessageModel({
    required this.role,
    required this.content,
    this.citations = const [],
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => CitationItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'citations': citations.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ChatResponseModel {
  final String sessionId;
  final String reply;
  final List<CitationItemModel> citations;
  final StudyModeEnum mode;
  final DateTime createdAt;

  ChatResponseModel({
    required this.sessionId,
    required this.reply,
    this.citations = const [],
    this.mode = StudyModeEnum.chat,
    required this.createdAt,
  });

  factory ChatResponseModel.fromJson(Map<String, dynamic> json) {
    return ChatResponseModel(
      sessionId: json['session_id'] ?? '',
      reply: json['reply'] ?? '',
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => CitationItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mode: StudyModeEnum.fromString(json['mode'] ?? 'chat'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'reply': reply,
      'citations': citations.map((e) => e.toJson()).toList(),
      'mode': mode.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class QuizQuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final CitationItemModel? citation;
  int? selectedOptionIndex;

  QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.citation,
    this.selectedOptionIndex,
  });

  bool get isAnswered => selectedOptionIndex != null;
  bool get isCorrect => selectedOptionIndex == correctOptionIndex;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      correctOptionIndex: json['correct_option_index'] ?? 0,
      explanation: json['explanation'] ?? '',
      citation: json['citation'] != null
          ? CitationItemModel.fromJson(json['citation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct_option_index': correctOptionIndex,
      'explanation': explanation,
      'citation': citation?.toJson(),
    };
  }
}

class QuizResponseModel {
  final String title;
  final String? subjectId;
  final List<QuizQuestionModel> questions;
  final int totalQuestions;
  final DateTime createdAt;

  QuizResponseModel({
    required this.title,
    this.subjectId,
    required this.questions,
    required this.totalQuestions,
    required this.createdAt,
  });

  factory QuizResponseModel.fromJson(Map<String, dynamic> json) {
    return QuizResponseModel(
      title: json['title'] ?? 'Practice Quiz',
      subjectId: json['subject_id'],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalQuestions: json['total_questions'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject_id': subjectId,
      'questions': questions.map((e) => e.toJson()).toList(),
      'total_questions': totalQuestions,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FlashcardItemModel {
  final String id;
  final String front;
  final String back;
  final String category;
  final CitationItemModel? citation;
  bool isMastered;

  FlashcardItemModel({
    required this.id,
    required this.front,
    required this.back,
    this.category = 'General',
    this.citation,
    this.isMastered = false,
  });

  factory FlashcardItemModel.fromJson(Map<String, dynamic> json) {
    return FlashcardItemModel(
      id: json['id'] ?? '',
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      category: json['category'] ?? 'General',
      citation: json['citation'] != null
          ? CitationItemModel.fromJson(json['citation'] as Map<String, dynamic>)
          : null,
      isMastered: json['is_mastered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'category': category,
      'citation': citation?.toJson(),
      'is_mastered': isMastered,
    };
  }
}

class FlashcardResponseModel {
  final String title;
  final String? subjectId;
  final List<FlashcardItemModel> cards;
  final int totalCards;
  final DateTime createdAt;

  FlashcardResponseModel({
    required this.title,
    this.subjectId,
    required this.cards,
    required this.totalCards,
    required this.createdAt,
  });

  factory FlashcardResponseModel.fromJson(Map<String, dynamic> json) {
    return FlashcardResponseModel(
      title: json['title'] ?? 'Flashcard Deck',
      subjectId: json['subject_id'],
      cards: (json['cards'] as List<dynamic>?)
              ?.map((e) => FlashcardItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCards: json['total_cards'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject_id': subjectId,
      'cards': cards.map((e) => e.toJson()).toList(),
      'total_cards': totalCards,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class SummaryResponseModel {
  final String title;
  final String? subjectId;
  final String overview;
  final List<String> keyConcepts;
  final List<String> importantFormulasOrTakeaways;
  final List<String> examTips;
  final List<CitationItemModel> citations;
  final DateTime createdAt;

  SummaryResponseModel({
    required this.title,
    this.subjectId,
    required this.overview,
    required this.keyConcepts,
    required this.importantFormulasOrTakeaways,
    required this.examTips,
    this.citations = const [],
    required this.createdAt,
  });

  factory SummaryResponseModel.fromJson(Map<String, dynamic> json) {
    return SummaryResponseModel(
      title: json['title'] ?? 'Revision Summary',
      subjectId: json['subject_id'],
      overview: json['overview'] ?? '',
      keyConcepts: (json['key_concepts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      importantFormulasOrTakeaways: (json['important_formulas_or_takeaways'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      examTips: (json['exam_tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => CitationItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subject_id': subjectId,
      'overview': overview,
      'key_concepts': keyConcepts,
      'important_formulas_or_takeaways': importantFormulasOrTakeaways,
      'exam_tips': examTips,
      'citations': citations.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ConversationSessionModel {
  final String id;
  final String userId;
  final String title;
  final String? subjectId;
  final int messagesCount;
  final String lastMessagePreview;
  final DateTime updatedAt;

  ConversationSessionModel({
    required this.id,
    required this.userId,
    required this.title,
    this.subjectId,
    required this.messagesCount,
    required this.lastMessagePreview,
    required this.updatedAt,
  });

  factory ConversationSessionModel.fromJson(Map<String, dynamic> json) {
    return ConversationSessionModel(
      id: json['id'] ?? json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? 'Study Session',
      subjectId: json['subject_id'],
      messagesCount: json['messages_count'] ?? 0,
      lastMessagePreview: json['last_message_preview'] ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subject_id': subjectId,
      'messages_count': messagesCount,
      'last_message_preview': lastMessagePreview,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ConversationListResponseModel {
  final List<ConversationSessionModel> sessions;
  final int total;

  ConversationListResponseModel({
    required this.sessions,
    required this.total,
  });

  factory ConversationListResponseModel.fromJson(Map<String, dynamic> json) {
    return ConversationListResponseModel(
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((e) => ConversationSessionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }
}
