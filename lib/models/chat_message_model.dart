import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced Chat Message Model
class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderImageUrl;
  final String? senderRole; // 'user', 'asha', 'admin'
  final MessageType type;
  final String content;
  final String? imageUrl;
  final String? audioUrl;
  final String? documentUrl;
  final String? documentName;
  final int? documentSize;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final List<String> readBy;
  final String? replyToMessageId;
  final ChatMessageModel? replyToMessage; // Nested message for replies
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final MessageStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    this.senderRole,
    required this.type,
    required this.content,
    this.imageUrl,
    this.audioUrl,
    this.documentUrl,
    this.documentName,
    this.documentSize,
    this.metadata,
    required this.timestamp,
    this.readBy = const [],
    this.replyToMessageId,
    this.replyToMessage,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.status = MessageStatus.sent,
    this.deliveredAt,
    this.readAt,
  });

  // Getters
  bool get hasMedia => imageUrl != null || audioUrl != null || documentUrl != null;
  bool get isReply => replyToMessageId != null;
  bool get isSystemMessage => type == MessageType.system;
  bool get isFromUser => senderRole == 'user';
  bool get isFromAsha => senderRole == 'asha';
  
  String get displayContent {
    if (isDeleted) return 'This message was deleted';
    if (type == MessageType.image) return '📷 Image';
    if (type == MessageType.audio) return '🎵 Audio message';
    if (type == MessageType.document) return '📎 ${documentName ?? 'Document'}';
    if (type == MessageType.location) return '📍 Location shared';
    return content;
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  // Factory constructor from Firestore
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderImageUrl: data['senderImageUrl'],
      senderRole: data['senderRole'],
      type: MessageType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => MessageType.text,
      ),
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      documentUrl: data['documentUrl'],
      documentName: data['documentName'],
      documentSize: data['documentSize'],
      metadata: data['metadata'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
      replyToMessageId: data['replyToMessageId'],
      // Note: replyToMessage would be fetched separately if needed
      isEdited: data['isEdited'] ?? false,
      editedAt: data['editedAt'] != null 
          ? (data['editedAt'] as Timestamp).toDate() 
          : null,
      isDeleted: data['isDeleted'] ?? false,
      status: MessageStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      deliveredAt: data['deliveredAt'] != null 
          ? (data['deliveredAt'] as Timestamp).toDate() 
          : null,
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'senderRole': senderRole,
      'type': type.toString(),
      'content': content,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'documentUrl': documentUrl,
      'documentName': documentName,
      'documentSize': documentSize,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'replyToMessageId': replyToMessageId,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
      'status': status.toString(),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  // Copy with method
  ChatMessageModel copyWith({
    String? content,
    List<String>? readBy,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    MessageStatus? status,
    DateTime? deliveredAt,
    DateTime? readAt,
    ChatMessageModel? replyToMessage,
  }) {
    return ChatMessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderImageUrl: senderImageUrl,
      senderRole: senderRole,
      type: type,
      content: content ?? this.content,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      documentUrl: documentUrl,
      documentName: documentName,
      documentSize: documentSize,
      metadata: metadata,
      timestamp: timestamp,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      status: status ?? this.status,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

// Typing Indicator Model
class TypingIndicator {
  final String userId;
  final String userName;
  final String chatId;
  final DateTime timestamp;

  TypingIndicator({
    required this.userId,
    required this.userName,
    required this.chatId,
    required this.timestamp,
  });

  bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 5;

  factory TypingIndicator.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TypingIndicator(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      chatId: data['chatId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'chatId': chatId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// Message Status for delivery tracking
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Message Type (enhanced from the original)
enum MessageType {
  text,
  image,
  audio,
  document,
  location,
  system,
  appointment,
  vitals,
  reminder,
}

// Extensions for better display
extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.audio:
        return 'Voice Message';
      case MessageType.document:
        return 'Document';
      case MessageType.location:
        return 'Location';
      case MessageType.system:
        return 'System Message';
      case MessageType.appointment:
        return 'Appointment';
      case MessageType.vitals:
        return 'Vitals Shared';
      case MessageType.reminder:
        return 'Reminder';
    }
  }

  String get icon {
    switch (this) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '📷';
      case MessageType.audio:
        return '🎤';
      case MessageType.document:
        return '📎';
      case MessageType.location:
        return '📍';
      case MessageType.system:
        return 'ℹ️';
      case MessageType.appointment:
        return '📅';
      case MessageType.vitals:
        return '❤️';
      case MessageType.reminder:
        return '⏰';
    }
  }
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed to send';
    }
  }

  String get icon {
    switch (this) {
      case MessageStatus.sending:
        return '🕐';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓';
      case MessageStatus.failed:
        return '❌';
    }
  }
}

// Utility class for message-related operations
class MessageUtils {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today
      final hour = timestamp.hour;
      final minute = timestamp.minute;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      return days[timestamp.weekday % 7];
    } else {
      // Older
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }
}