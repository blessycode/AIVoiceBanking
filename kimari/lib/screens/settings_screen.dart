import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.userDisplayName = 'Customer',
    this.phone,
    this.language = 'en',
    this.sessionId = '',
    this.backendBaseUrl = '',
    this.backendReachable = false,
    this.voiceStatusLabel = 'Paused',
    this.isAuthenticated = false,
    this.onResetConversation,
    this.onResumeVoice,
  });

  final String userDisplayName;
  final String? phone;
  final String language;
  final String sessionId;
  final String backendBaseUrl;
  final bool backendReachable;
  final String voiceStatusLabel;
  final bool isAuthenticated;
  final VoidCallback? onResetConversation;
  final VoidCallback? onResumeVoice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildProfileCard(),
                const SizedBox(height: 18),
                _buildSessionCard(),
                const SizedBox(height: 18),
                _buildConnectionCard(),
                const SizedBox(height: 18),
                _buildActionsCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Live configuration for the authenticated voice workspace',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return _SettingsSection(
      title: 'Profile',
      icon: Icons.person_outline_rounded,
      accent: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userDisplayName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(label: 'Phone', value: phone ?? 'Not available'),
          _InfoRow(label: 'Language', value: language.toUpperCase()),
          _InfoRow(
            label: 'Authentication',
            value: isAuthenticated ? 'Authenticated' : 'Guest',
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    return _SettingsSection(
      title: 'Session',
      icon: Icons.voice_chat_rounded,
      accent: AppColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'Voice Status',
            value: voiceStatusLabel,
          ),
          _InfoRow(
            label: 'Session ID',
            value: sessionId.isEmpty ? 'Not started yet' : sessionId,
          ),
          const SizedBox(height: 12),
          const Text(
            'This session is persisted locally on the device and mirrored in the backend so you can resume the voice flow later.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard() {
    return _SettingsSection(
      title: 'Connection',
      icon: Icons.wifi_tethering_rounded,
      accent: backendReachable ? AppColors.success : AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: backendReachable ? AppColors.success : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                backendReachable ? 'Backend reachable' : 'Backend unreachable',
                style: TextStyle(
                  color: backendReachable ? AppColors.success : AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            backendBaseUrl.isEmpty ? 'No backend URL configured.' : backendBaseUrl,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your laptop LAN IP on a physical device and keep the FastAPI server running while the voice loop is active.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return _SettingsSection(
      title: 'Actions',
      icon: Icons.tune_rounded,
      accent: AppColors.accentLight,
      child: Column(
        children: [
          _ActionTile(
            title: 'Resume Voice Agent',
            body: 'Return to the dashboard and continue the conversation.',
            icon: Icons.mic_rounded,
            accent: AppColors.teal,
            onTap: onResumeVoice == null
                ? null
                : () {
                    onResumeVoice!.call();
                    Navigator.pop(context);
                  },
          ),
          const SizedBox(height: 12),
          _ActionTile(
            title: 'Start Fresh Session',
            body: 'Reset the current flow and begin a new secure voice session.',
            icon: Icons.refresh_rounded,
            accent: AppColors.gold,
            onTap: onResetConversation == null
                ? null
                : () {
                    onResetConversation!.call();
                    Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

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
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
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
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
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
                  const SizedBox(height: 4),
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
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: onTap == null ? AppColors.textMuted : accent,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
