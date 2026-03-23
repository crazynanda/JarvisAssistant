import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final bool isUser;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? sessionId;

  @HiveField(5)
  final List<String>? quickActions;

  @HiveField(6)
  final bool hasAttachment;

  @HiveField(7)
  final String? attachmentType;

  MessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sessionId,
    this.quickActions,
    this.hasAttachment = false,
    this.attachmentType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'quickActions': quickActions,
      'hasAttachment': hasAttachment,
      'attachmentType': attachmentType,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String?,
      quickActions: (json['quickActions'] as List<dynamic>?)?.cast<String>(),
      hasAttachment: json['hasAttachment'] as bool? ?? false,
      attachmentType: json['attachmentType'] as String?,
    );
  }
}

@HiveType(typeId: 1)
class ChatSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime lastModified;

  @HiveField(4)
  final int messageCount;

  @HiveField(5)
  final String? summary;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    this.messageCount = 0,
    this.summary,
  });
}
