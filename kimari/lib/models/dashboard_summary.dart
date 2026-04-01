class DashboardSummary {
  const DashboardSummary({
    required this.sessionId,
    required this.state,
    required this.language,
    required this.isAuthenticated,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.balance,
    required this.currency,
    required this.recentTransactions,
  });

  final String sessionId;
  final String state;
  final String language;
  final bool isAuthenticated;
  final int? userId;
  final String? userName;
  final String? phone;
  final double? balance;
  final String? currency;
  final List<DashboardTransaction> recentTransactions;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      sessionId: json['session_id'] as String? ?? '',
      state: json['state'] as String? ?? 'UNKNOWN',
      language: json['language'] as String? ?? 'en',
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
      userId: json['user_id'] as int?,
      userName: json['user_name'] as String?,
      phone: json['phone'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      recentTransactions: (json['recent_transactions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => DashboardTransaction.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class DashboardTransaction {
  const DashboardTransaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.recipient,
    required this.reference,
    required this.status,
    required this.balanceAfter,
    required this.createdAt,
  });

  final int id;
  final String transactionType;
  final double amount;
  final String? recipient;
  final String? reference;
  final String status;
  final double balanceAfter;
  final DateTime createdAt;

  factory DashboardTransaction.fromJson(Map<String, dynamic> json) {
    return DashboardTransaction(
      id: json['id'] as int? ?? 0,
      transactionType: json['transaction_type'] as String? ?? 'UNKNOWN',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      recipient: json['recipient'] as String?,
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'UNKNOWN',
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class TransactionsResponse {
  const TransactionsResponse({
    required this.sessionId,
    required this.isAuthenticated,
    required this.userId,
    required this.currency,
    required this.transactions,
  });

  final String sessionId;
  final bool isAuthenticated;
  final int? userId;
  final String? currency;
  final List<DashboardTransaction> transactions;

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      sessionId: json['session_id'] as String? ?? '',
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
      userId: json['user_id'] as int?,
      currency: json['currency'] as String?,
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => DashboardTransaction.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
