import 'package:flutter/material.dart';

import '../models/conversation_entry.dart';
import '../models/dashboard_summary.dart';
import '../theme/app_theme.dart';
import 'all_transactions_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.assistantResponse = 'The voice agent is ready for the next banking task.',
    this.latestTranscript = '',
    this.voiceStatusLabel = 'Connected',
    this.voiceStatusColor = AppColors.teal,
    this.voiceControlLabel = 'Resume Voice Agent',
    this.voiceGreeting = 'Your secure voice banking workspace is active.',
    this.userDisplayName = 'Customer',
    this.sessionId = '',
    this.language = 'en',
    this.agentState = 'AUTHENTICATED_HOME',
    this.userId,
    this.summary,
    this.conversationEntries = const <ConversationEntry>[],
    this.backendReachable = false,
    this.backendBaseUrl = '',
    this.onVoiceControlPressed,
    this.onResetConversation,
  });

  final String assistantResponse;
  final String latestTranscript;
  final String voiceStatusLabel;
  final Color voiceStatusColor;
  final String voiceControlLabel;
  final String voiceGreeting;
  final String userDisplayName;
  final String sessionId;
  final String language;
  final String agentState;
  final int? userId;
  final DashboardSummary? summary;
  final List<ConversationEntry> conversationEntries;
  final bool backendReachable;
  final String backendBaseUrl;
  final VoidCallback? onVoiceControlPressed;
  final VoidCallback? onResetConversation;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _balanceVisible = true;

  void _openTransactionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllTransactionsScreen(
          sessionId: widget.sessionId,
          userDisplayName: widget.summary?.userName ?? widget.userDisplayName,
          currency: widget.summary?.currency ?? 'USD',
          initialTransactions:
              widget.summary?.recentTransactions ??
              const <DashboardTransaction>[],
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          userDisplayName: widget.summary?.userName ?? widget.userDisplayName,
          phone: widget.summary?.phone,
          language: widget.language,
          sessionId: widget.sessionId,
          backendBaseUrl: widget.backendBaseUrl,
          backendReachable: widget.backendReachable,
          voiceStatusLabel: widget.voiceStatusLabel,
          isAuthenticated: widget.summary?.isAuthenticated ?? true,
          onResetConversation: widget.onResetConversation,
          onResumeVoice: widget.onVoiceControlPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final displayName =
        summary?.userName?.trim().isNotEmpty == true
            ? summary!.userName!
            : widget.userDisplayName;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _DashboardHeader(
                displayName: displayName,
                voiceGreeting: widget.voiceGreeting,
                backendReachable: widget.backendReachable,
                onResetConversation: widget.onResetConversation,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountOverview(summary, displayName),
                      const SizedBox(height: 18),
                      _buildVoiceWorkspace(),
                      const SizedBox(height: 18),
                      _buildCommandSuggestions(),
                      const SizedBox(height: 18),
                      _buildRecentTransactions(summary),
                      const SizedBox(height: 18),
                      _buildConversationFeed(),
                      const SizedBox(height: 18),
                      _buildConnectionCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOverview(DashboardSummary? summary, String displayName) {
    final balance = summary?.balance;
    final currency = summary?.currency ?? 'USD';
    final maskedPhone = _maskPhone(summary?.phone);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF164A5B), Color(0xFF0E2431)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.16),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Overview',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _balanceVisible = !_balanceVisible;
                  });
                },
                icon: Icon(
                  _balanceVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.goldLight,
                ),
                tooltip: _balanceVisible ? 'Hide balance' : 'Show balance',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            balance == null
                ? 'Ask Jonten to check your balance'
                : _balanceVisible
                ? '${_formatCurrency(balance)} $currency'
                : '••••••',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionChip(
                label: 'History',
                icon: Icons.history_rounded,
                accent: AppColors.accentGlow,
                onTap: _openTransactionHistory,
              ),
              _ActionChip(
                label: 'Settings',
                icon: Icons.tune_rounded,
                accent: AppColors.gold,
                onTap: _openSettings,
              ),
              _InsightChip(
                label: 'User',
                value: widget.userId != null ? '#${widget.userId}' : 'Pending',
                color: AppColors.gold,
              ),
              _InsightChip(
                label: 'Phone',
                value: maskedPhone ?? 'Voice-only session',
                color: AppColors.accentGlow,
              ),
              _InsightChip(
                label: 'Language',
                value: widget.language.toUpperCase(),
                color: AppColors.teal,
              ),
              _InsightChip(
                label: 'State',
                value: widget.agentState,
                color: widget.voiceStatusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWorkspace() {
    return _SectionCard(
      title: 'Voice Workspace',
      icon: Icons.record_voice_over_rounded,
      accent: widget.voiceStatusColor,
      trailing: _StatusPill(
        label: widget.voiceStatusLabel,
        color: widget.voiceStatusColor,
      ),
      child: Column(
        children: [
          _MessagePanel(
            title: 'Assistant',
            body: widget.assistantResponse,
            icon: Icons.graphic_eq_rounded,
            color: AppColors.gold,
          ),
          const SizedBox(height: 12),
          _MessagePanel(
            title: 'Latest Transcript',
            body: widget.latestTranscript.isEmpty
                ? 'No spoken request captured yet.'
                : widget.latestTranscript,
            icon: Icons.mic_rounded,
            color: AppColors.teal,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: widget.voiceControlLabel,
                  icon: Icons.mic_rounded,
                  accent: widget.voiceStatusColor,
                  onPressed: widget.onVoiceControlPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'New Session',
                  icon: Icons.refresh_rounded,
                  accent: AppColors.surfaceLight,
                  onPressed: widget.onResetConversation,
                  outlined: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommandSuggestions() {
    const prompts = <String>[
      'Check my balance',
      'Send 10 dollars to Farai',
      'Buy 5 dollars airtime',
      'Pay my ZESA bill',
    ];

    return _SectionCard(
      title: 'Suggested Voice Commands',
      icon: Icons.tips_and_updates_rounded,
      accent: AppColors.gold,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: prompts
            .map(
              (prompt) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  prompt,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRecentTransactions(DashboardSummary? summary) {
    final transactions = summary?.recentTransactions ?? const <DashboardTransaction>[];

    return _SectionCard(
      title: 'Recent Transactions',
      icon: Icons.receipt_long_rounded,
      accent: AppColors.accentLight,
      trailing: TextButton(
        onPressed: _openTransactionHistory,
        child: const Text('Open History'),
      ),
      child: transactions.isEmpty
          ? const _EmptyState(
              title: 'No live transactions yet',
              body:
                  'Your recent payments and transfers will appear here after you complete them through the voice agent.',
            )
          : Column(
              children: transactions
                  .map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionTile(transaction: transaction),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildConversationFeed() {
    final entries = widget.conversationEntries.reversed.take(6).toList();

    return _SectionCard(
      title: 'Conversation Activity',
      icon: Icons.forum_rounded,
      accent: AppColors.teal,
      child: entries.isEmpty
          ? const _EmptyState(
              title: 'No conversation activity yet',
              body:
                  'Once the session starts, the latest turns between you and Jonten will appear here.',
            )
          : Column(
              children: entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivityTile(entry: entry),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildConnectionCard() {
    return _SectionCard(
      title: 'Connection',
      icon: Icons.wifi_tethering_rounded,
      accent: widget.backendReachable ? AppColors.success : AppColors.error,
      trailing: TextButton(
        onPressed: _openSettings,
        child: const Text('Settings'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.backendReachable
                ? 'Backend connection is healthy.'
                : 'Backend is currently unreachable.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.backendBaseUrl.isEmpty
                ? 'No backend URL configured.'
                : 'Connected target: ${widget.backendBaseUrl}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  String? _maskPhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length <= 4) {
      return value;
    }
    return '${value.substring(0, 3)} ••• ${value.substring(value.length - 3)}';
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.displayName,
    required this.voiceGreeting,
    required this.backendReachable,
    required this.onResetConversation,
  });

  final String displayName;
  final String voiceGreeting;
  final bool backendReachable;
  final VoidCallback? onResetConversation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $displayName',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  voiceGreeting,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: backendReachable ? 'Backend Live' : 'Offline',
            color: backendReachable ? AppColors.success : AppColors.error,
          ),
          if (onResetConversation != null) ...[
            const SizedBox(width: 10),
            IconButton(
              onPressed: onResetConversation,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
              tooltip: 'Reset session',
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...?trailing == null ? null : <Widget>[trailing!],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accent, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accent.withValues(alpha: 0.35)),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: Icon(icon, size: 18),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final DashboardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.transactionType != 'PROFILE_CREATED' &&
        transaction.transactionType != 'LOGIN_SUCCESS';
    final accent = isDebit ? AppColors.gold : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForType(transaction.transactionType),
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleForType(transaction),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.createdAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}',
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
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'SEND_MONEY':
        return Icons.north_east_rounded;
      case 'PAY_BILL':
        return Icons.receipt_long_rounded;
      case 'BUY_AIRTIME':
        return Icons.phone_android_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  String _titleForType(DashboardTransaction transaction) {
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

  String _formatDate(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute $suffix';
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});

  final ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final config = switch (entry.role) {
      ConversationRole.assistant => (
          title: 'Assistant',
          color: AppColors.gold,
          icon: Icons.graphic_eq_rounded,
        ),
      ConversationRole.customer => (
          title: 'You',
          color: AppColors.teal,
          icon: Icons.mic_rounded,
        ),
      ConversationRole.system => (
          title: 'System',
          color: AppColors.accentGlow,
          icon: Icons.info_outline_rounded,
        ),
    };

    final hour = entry.timestamp.hour % 12 == 0 ? 12 : entry.timestamp.hour % 12;
    final minute = entry.timestamp.minute.toString().padLeft(2, '0');
    final suffix = entry.timestamp.hour >= 12 ? 'PM' : 'AM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(config.icon, color: config.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.title.isEmpty ? config.title : entry.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$hour:$minute $suffix',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
