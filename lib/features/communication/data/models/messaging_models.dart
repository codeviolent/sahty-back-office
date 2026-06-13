class ConversationItem {
  final int    id;
  final String status;
  final String lastMessagePreview;
  final DateTime lastMessageAt;
  final int    unreadByDoctor;
  final ConversationPatient patient;

  const ConversationItem({
    required this.id,
    required this.status,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadByDoctor,
    required this.patient,
  });

  bool get hasUnread => unreadByDoctor > 0;

  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  factory ConversationItem.fromJson(Map<String, dynamic> j) =>
      ConversationItem(
        id:                 (j['id'] as num).toInt(),
        status:             j['status'] as String? ?? 'active',
        lastMessagePreview: j['lastMessagePreview'] as String? ?? '',
        lastMessageAt:      DateTime.parse(
          j['lastMessageAt'] as String? ?? DateTime.now().toIso8601String()),
        unreadByDoctor:     (j['unreadByDoctor'] as num?)?.toInt() ?? 0,
        patient: ConversationPatient.fromJson(
          j['patient'] as Map<String, dynamic>? ?? {}),
      );
}

class ConversationPatient {
  final int    id;
  final String firstName;
  final String lastName;
  final String phone;
  final String bloodType;

  const ConversationPatient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.bloodType,
  });

  String get displayName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty  ? lastName[0].toUpperCase()  : '';
    return '$f$l';
  }

  factory ConversationPatient.fromJson(Map<String, dynamic> j) =>
      ConversationPatient(
        id:        (j['id'] as num?)?.toInt()      ?? 0,
        firstName: j['firstName'] as String?       ?? '',
        lastName:  j['lastName']  as String?       ?? '',
        phone:     j['phone']     as String?       ?? '',
        bloodType: j['bloodType'] as String?       ?? '—',
      );
}

class MessageItem {
  final int    id;
  final String senderId;
  final String senderRole;   // 'medecin' | 'patient'
  final String content;
  final bool   isRead;
  final DateTime createdAt;

  const MessageItem({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  bool get isFromDoctor => senderRole == 'medecin';

  String get formattedTime {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  factory MessageItem.fromJson(Map<String, dynamic> j) => MessageItem(
    id:         (j['id'] as num).toInt(),
    senderId:   j['senderId']   as String? ?? '',
    senderRole: j['senderRole'] as String? ?? 'patient',
    content:    j['content']    as String? ?? '',
    isRead:     j['isRead']     as bool?   ?? false,
    createdAt:  DateTime.parse(
      j['createdAt'] as String? ?? DateTime.now().toIso8601String()),
  );
}