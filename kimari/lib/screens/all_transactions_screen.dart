import 'package:flutter/material.dart';

import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({
    super.key,
    this.sessionId = '',
    this.userDisplayName = 'Customer',
    this.currency = 'USD',
    this.initialTransactions = const <DashboardTransaction>[],
    ApiService? apiService,
  }) : _apiService = apiService;

  final String sessionId;
  final String userDisplayName;
  final String currency;
  final List<DashboardTransaction> initialTransactions;
  final ApiService? _apiService;

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  late final ApiService _apiService;
  late final bool _ownsApiService;

  List<DashboardTransaction> _transactions = <DashboardTransaction>[];
  String _selectedFilter = 'All';
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ownsApiService = widget._apiService == null;
    _apiService = widget._apiService ?? ApiService();
    _transactions = List<DashboardTransaction>.from(widget.initialTransactions);

    if (widget.sessionId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTransactions();
      });
    }
  }

  @override
  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final response = await _apiService.fetchTransactions(widget.sessionId);
      if (!mounted) {
        return;
      }
      setState(() {
        _transactions = response.transactions;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _filters {
    final categories = _transactions
        .map(_categoryForTransaction)
        .toSet()
        .toList()
      ..sort();
    return <String>['All', ...categories];
  }

  List<DashboardTransaction> get _filteredTransactions {
    if (_selectedFilter == 'All') {
      return _transactions;
    }

    return _transactions
        .where((transaction) => _categoryForTransaction(transaction) == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;
    final totals = _buildTotals(_transactions);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSummaryCard(totals),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorText != null
                    ? _buildErrorState()
                    : transactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final transaction = transactions[index];
                          return _TransactionHistoryTile(
                            transaction: transaction,
                            currency: widget.currency,
                            onTap: () => _showTransactionDetail(transaction),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live backend transactions for ${widget.userDisplayName}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadTransactions,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.accentGlow,
            tooltip: 'Refresh history',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(_TransactionTotals totals) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF164A5B), Color(0xFF0F2737)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SummaryMetric(
                label: 'Debits',
                value: '${totals.totalDebits.toStringAsFixed(2)} ${widget.currency}',
                color: AppColors.gold,
              ),
            ),
            _divider(),
            Expanded(
              child: _SummaryMetric(
                label: 'Credits',
                value: '${totals.totalCredits.toStringAsFixed(2)} ${widget.currency}',
                color: AppColors.success,
              ),
            ),
            _divider(),
            Expanded(
              child: _SummaryMetric(
                label: 'Entries',
                value: totals.count.toString(),
                color: AppColors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 42,
      color: AppColors.surfaceLight,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildFilterChips() {
    final filters = _filters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              labelStyle: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppColors.accent.withValues(alpha: 0.25),
              backgroundColor: AppColors.surface.withValues(alpha: 0.72),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.surfaceLight,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Unable to load transactions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorText ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textMuted,
              size: 36,
            ),
            SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Payments, transfers, and airtime purchases completed through the voice agent will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetail(DashboardTransaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _titleForTransaction(transaction),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${transaction.amount.toStringAsFixed(2)} ${widget.currency}',
                style: TextStyle(
                  color: _isDebit(transaction) ? AppColors.gold : AppColors.success,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow('Type', transaction.transactionType.replaceAll('_', ' ')),
              _detailRow('Status', transaction.status),
              if (transaction.recipient != null && transaction.recipient!.isNotEmpty)
                _detailRow('Recipient', transaction.recipient!),
              if (transaction.reference != null && transaction.reference!.isNotEmpty)
                _detailRow('Reference', transaction.reference!),
              _detailRow(
                'Balance After',
                '${transaction.balanceAfter.toStringAsFixed(2)} ${widget.currency}',
              ),
              _detailRow('Created', _formatDate(transaction.createdAt)),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _TransactionTotals _buildTotals(List<DashboardTransaction> transactions) {
    var totalDebits = 0.0;
    var totalCredits = 0.0;

    for (final transaction in transactions) {
      if (_isDebit(transaction)) {
        totalDebits += transaction.amount;
      } else {
        totalCredits += transaction.amount;
      }
    }

    return _TransactionTotals(
      count: transactions.length,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
    );
  }

  bool _isDebit(DashboardTransaction transaction) {
    switch (transaction.transactionType) {
      case 'SEND_MONEY':
      case 'PAY_BILL':
      case 'BUY_AIRTIME':
        return true;
      default:
        return false;
    }
  }

  String _titleForTransaction(DashboardTransaction transaction) {
    switch (transaction.transactionType) {
      case 'SEND_MONEY':
        return 'Sent to ${transaction.recipient ?? 'recipient'}';
      case 'PAY_BILL':
        return 'Paid ${transaction.recipient ?? 'bill'}';
      case 'BUY_AIRTIME':
        return 'Airtime purchase';
      default:
        return transaction.transactionType.replaceAll('_', ' ');
    }
  }

  String _categoryForTransaction(DashboardTransaction transaction) {
    switch (transaction.transactionType) {
      case 'SEND_MONEY':
        return 'Transfers';
      case 'PAY_BILL':
        return 'Bills';
      case 'BUY_AIRTIME':
        return 'Airtime';
      default:
        return 'Other';
    }
  }

  String _formatDate(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute $suffix';
  }
}

class _TransactionTotals {
  const _TransactionTotals({
    required this.count,
    required this.totalDebits,
    required this.totalCredits,
  });

  final int count;
  final double totalDebits;
  final double totalCredits;
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _TransactionHistoryTile extends StatelessWidget {
  const _TransactionHistoryTile({
    required this.transaction,
    required this.currency,
    required this.onTap,
  });

  final DashboardTransaction transaction;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDebit = switch (transaction.transactionType) {
      'SEND_MONEY' || 'PAY_BILL' || 'BUY_AIRTIME' => true,
      _ => false,
    };
    final accent = isDebit ? AppColors.gold : AppColors.success;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                switch (transaction.transactionType) {
                  'SEND_MONEY' => Icons.north_east_rounded,
                  'PAY_BILL' => Icons.receipt_long_rounded,
                  'BUY_AIRTIME' => Icons.phone_android_rounded,
                  _ => Icons.account_balance_wallet_rounded,
                },
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    switch (transaction.transactionType) {
                      'SEND_MONEY' => 'Sent to ${transaction.recipient ?? 'recipient'}',
                      'PAY_BILL' => 'Paid ${transaction.recipient ?? 'bill'}',
                      'BUY_AIRTIME' => 'Airtime purchase',
                      _ => transaction.transactionType.replaceAll('_', ' '),
                    },
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.status} • ${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}-${transaction.createdAt.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? '-' : '+'}${transaction.amount.toStringAsFixed(2)} $currency',
                  style: TextStyle(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bal ${transaction.balanceAfter.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
