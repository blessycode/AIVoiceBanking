import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/ai_assistant_screen.dart';
import 'screens/airtime_screen.dart';
import 'screens/all_transactions_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/send_money_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/top_up_screen.dart';
import 'screens/transaction_success_screen.dart';
import 'screens/voice_auth_screen.dart';
import 'screens/voice_home_screen.dart';
import 'screens/voice_listening_screen.dart';
import 'screens/voice_transaction_screen.dart';
import 'theme/app_theme.dart';

const _intervalMs = int.fromEnvironment(
  'SCREENSHOT_INTERVAL_MS',
  defaultValue: 4500,
);
const _singleScreenName = String.fromEnvironment('SCREENSHOT_SCREEN');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E1E3A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ScreenshotApp());
}

class ScreenshotApp extends StatelessWidget {
  const ScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jonten Screenshots',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _singleScreenName.isEmpty
          ? const ScreenshotCarousel()
          : ScreenshotFrame(screen: _findScreen(_singleScreenName)),
    );
  }
}

class ScreenshotCarousel extends StatefulWidget {
  const ScreenshotCarousel({super.key});

  @override
  State<ScreenshotCarousel> createState() => _ScreenshotCarouselState();
}

class _ScreenshotCarouselState extends State<ScreenshotCarousel> {
  late final Timer _timer;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: _intervalMs), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _index = (_index + 1) % _screens.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenshotFrame(screen: _screens[_index].builder());
  }
}

class ScreenshotFrame extends StatelessWidget {
  const ScreenshotFrame({super.key, required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return screen;
  }
}

class _ScreenSpec {
  const _ScreenSpec(this.name, this.builder);

  final String name;
  final Widget Function() builder;
}

final List<_ScreenSpec> _screens = [
  _ScreenSpec('splash', () => const SplashScreen(autoNavigate: false)),
  _ScreenSpec('voice-auth', () => const VoiceAuthScreen()),
  _ScreenSpec('voice-home', () => const VoiceHomeScreen(autoStart: false)),
  _ScreenSpec(
    'dashboard',
    () => const DashboardScreen(
      assistantResponse:
          'Your voice-first banking assistant is ready for the next task.',
      latestTranscript: 'Send money to Simon',
      voiceStatusLabel: 'Paused',
      voiceControlLabel: 'Resume Voice Agent',
      voiceGreeting: 'Your authenticated voice banking session is active.',
      userDisplayName: 'Blessed',
      sessionId: 'session-demo-001',
      language: 'en',
      agentState: 'AUTHENTICATED_HOME',
      userId: 1,
    ),
  ),
  _ScreenSpec('send-money', () => const SendMoneyScreen()),
  _ScreenSpec('voice-transaction', () => const VoiceTransactionScreen()),
  _ScreenSpec(
    'transaction-success',
    () => const TransactionSuccessScreen(),
  ),
  _ScreenSpec('airtime', () => const AirtimeScreen()),
  _ScreenSpec('bills', () => const BillsScreen()),
  _ScreenSpec('cards', () => const CardsScreen()),
  _ScreenSpec('all-transactions', () => const AllTransactionsScreen()),
  _ScreenSpec('top-up', () => const TopUpScreen()),
  _ScreenSpec('pin-entry', () => const PinEntryScreen()),
  _ScreenSpec('ai-assistant', () => const AiAssistantScreen()),
  _ScreenSpec('voice-listening', () => const VoiceListeningScreen()),
  _ScreenSpec('settings', () => const SettingsScreen()),
];

Widget _findScreen(String name) {
  for (final screen in _screens) {
    if (screen.name == name) {
      return screen.builder();
    }
  }

  return Scaffold(
    backgroundColor: const Color(0xFF1E1E3A),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unknown screenshot screen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                color: AppColors.accentGlow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Supported screen names:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (final screen in _screens)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        screen.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
