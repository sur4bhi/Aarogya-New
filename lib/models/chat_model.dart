import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final ChatType type;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Group chat specific fields
  final String? groupName;
  final String? groupDescription;
  final String? groupImageUrl;
  final String? adminId;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    this.type = ChatType.individual,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.groupDescription,
    this.groupImageUrl,
    this.adminId,
  });

  // Get other participant ID (for individual chats)
  String? getOtherParticipantId(String currentUserId) {
    if (type != ChatType.individual || participants.length != 2) return null;
    return participants.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  // Get unread count for specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount[userId] ?? 0;
  }

  // Check if user has unread messages
  bool hasUnreadMessages(String userId) {
    return getUnreadCountForUser(userId) > 0;
  }

  // Get display name for chat
  String getDisplayName(String currentUserId, {Map<String, String>? userNames}) {
    if (type == ChatType.group) {
      return groupName ?? 'Group Chat';
    }
    
    final otherParticipantId = getOtherParticipantId(currentUserId);
    if (otherParticipantId != null && userNames != null) {
      return userNames[otherParticipantId] ?? 'Unknown User';
    }
    
    return 'Chat';
  }

  // Factory constructor from Firestore
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null 
          ? (data['lastMessageTime'] as Timestamp).toDate() 
          : null,
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      type: ChatType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => ChatType.individual,
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      groupName: data['groupName'],
      groupDescription: data['groupDescription'],
      groupImageUrl: data['groupImageUrl'],
      adminId: data['adminId'],
    );
  }

  // Factory constructor from JSON
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      lastMessageSenderId: json['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
      type: ChatType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => ChatType.individual,
      ),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      groupName: json['groupName'],
      groupDescription: json['groupDescription'],
      groupImageUrl: json['groupImageUrl'],
      adminId: json['adminId'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null 
          ? Timestamp.fromDate(lastMessageTime!) 
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'type': type.toString(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupImageUrl': groupImageUrl,
      'adminId': adminId,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'type': type.toString(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupImageUrl': groupImageUrl,
      'adminId': adminId,
    };
  }

  // Copy with method
  ChatModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    ChatType? type,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? groupName,
    String? groupDescription,
    String? groupImageUrl,
    String? adminId,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      adminId: adminId ?? this.adminId,
    );
  }

  @override
  String toString() {
    return 'ChatModel(id: $id, participants: $participants, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToMessageId;
  final List<String> readBy;
  final Map<String, dynamic>? metadata;
  
  // Media message fields
  final String? mediaUrl;
  final String? mediaType;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  
  // Location message fields
  final double? latitude;
  final double? longitude;
  final String? locationName;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.replyToMessageId,
    this.readBy = const [],
    this.metadata,
    this.mediaUrl,
    this.mediaType,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  // Check if message is read by specific user
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  // Check if message is sent by specific user
  bool isSentBy(String userId) {
    return senderId == userId;
  }

  // Get display text for different message types
  String get displayText {
    switch (type) {
      case MessageType.text:
        return text;
      case MessageType.image:
        return '📷 Image';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.document:
        return '📄 Document';
      case MessageType.location:
        return '📍 Location';
      case MessageType.system:
        return text;
    }
  }

  // Factory constructor from Firestore
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      status: MessageStatus.values.firstWhere(
        (status) => status.toString() == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      replyToMessageId: data['replyToMessageId'],
      readBy: List<String>.from(data['readBy'] ?? []),
      metadata: data['metadata'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      thumbnailUrl: data['thumbnailUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationName: data['locationName'],
    );
  }

  // Factory constructor from JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      type: MessageType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere(
        (status) => status.toString() == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      replyToMessageId: json['replyToMessageId'],
      readBy: List<String>.from(json['readBy'] ?? []),
      metadata: json['metadata'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      thumbnailUrl: json['thumbnailUrl'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      locationName: json['locationName'],
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.toString(),
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.toString(),
      'replyToMessageId': replyToMessageId,
      'readBy': readBy,
      'metadata': metadata,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'replyToMessageId': replyToMessageId,
      'readBy': readBy,
      'metadata': metadata,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': fileName,
      'fileSize': fileSize,
      'thumbnailUrl': thumbnailUrl,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
    };
  }

  // Copy with method
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToMessageId,
    List<String>? readBy,
    Map<String, dynamic>? metadata,
    String? mediaUrl,
    String? mediaType,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      readBy: readBy ?? this.readBy,
      metadata: metadata ?? this.metadata,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, senderId: $senderId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Chat type enum
enum ChatType {
  individual,
  group,
}

// Message type enum
enum MessageType {
  text,
  image,
  video,
  audio,
  document,
  location,
  system,
}

// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Extension methods
extension ChatTypeExtension on ChatType {
  String get displayName {
    switch (this) {
      case ChatType.individual:
        return 'Individual';
      case ChatType.group:
        return 'Group';
    }
  }
}

extension MessageTypeExtension on MessageType {
  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.video:
        return 'Video';
      case MessageType.audio:
        return 'Audio';
      case MessageType.document:
        return 'Document';
      case MessageType.location:
        return 'Location';
      case MessageType.system:
        return 'System';
    }
  }

  String get icon {
    switch (this) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '📷';
      case MessageType.video:
        return '🎥';
      case MessageType.audio:
        return '🎵';
      case MessageType.document:
        return '📄';
      case MessageType.location:
        return '📍';
      case MessageType.system:
        return 'ℹ️';
    }
  }
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  String get icon {
    switch (this) {
      case MessageStatus.sending:
        return '⏳';
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
