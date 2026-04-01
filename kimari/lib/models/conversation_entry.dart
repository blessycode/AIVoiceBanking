enum ConversationRole { assistant, customer, system }

class ConversationEntry {
  const ConversationEntry({
    required this.role,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  final ConversationRole role;
  final String title;
  final String body;
  final DateTime timestamp;
}
