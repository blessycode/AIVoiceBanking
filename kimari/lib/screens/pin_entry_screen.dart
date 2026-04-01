import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class PinEntryScreen extends StatefulWidget {
  final String title;
  final bool isSetup;
  const PinEntryScreen({super.key, this.title = 'Enter your PIN', this.isSetup = false});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    if (_pin.length >= 4) return;
    setState(() => _pin += key);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onPinComplete);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onPinComplete() {
    if (widget.isSetup) {
      if (!_confirming) {
        setState(() { _confirmPin = _pin; _pin = ''; _confirming = true; });
      } else {
        if (_pin == _confirmPin) {
          _navigateToDashboard();
        } else {
          _shakeController.forward(from: 0);
          setState(() { _pin = ''; _confirming = false; _confirmPin = ''; });
          _showErrorSnack('PINs don\'t match. Try again.');
        }
      }
    } else {
      if (_pin == '1234') { // Demo PIN
        _navigateToDashboard();
      } else {
        _attempts++;
        _shakeController.forward(from: 0);
        setState(() => _pin = '');
        if (_attempts >= 3) {
          _showErrorSnack('Too many attempts. Try voice login.');
        } else {
          _showErrorSnack('Incorrect PIN. ${3 - _attempts} attempts left.');
        }
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18)),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.lock_rounded, color: AppColors.accentGlow, size: 48),
              const SizedBox(height: 20),
              Text(
                _confirming ? 'Confirm your PIN' : widget.title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _confirming ? 'Enter the same PIN again to confirm' : 'Enter your 4-digit secure PIN',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 48),
              // PIN dots
              AnimatedBuilder(
                animation: _shakeAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shakeAnim.value * ((_shakeController.value * 10).floor() % 2 == 0 ? 1 : -1), 0),
                  child: child,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final filled = i < _pin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.accent : Colors.transparent,
                        border: Border.all(color: filled ? AppColors.accent : AppColors.textMuted, width: 2),
                        boxShadow: filled ? [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),
              // Number pad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    _buildKeyRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildKeyRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildKeyRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildKey('', icon: Icons.fingerprint_rounded, onTap: _navigateToDashboard, subtle: true),
                        _buildKey('0', onTap: () => _onKeyPress('0')),
                        _buildKey('', icon: Icons.backspace_outlined, onTap: _onDelete, subtle: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((k) => _buildKey(k, onTap: () => _onKeyPress(k))).toList(),
    );
  }

  Widget _buildKey(String label, {VoidCallback? onTap, IconData? icon, bool subtle = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: subtle ? Colors.transparent : AppColors.surfaceLight.withOpacity(0.4),
          shape: BoxShape.circle,
          border: subtle ? null : Border.all(color: AppColors.surfaceLight),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: subtle ? AppColors.textMuted : AppColors.textSecondary, size: 26)
              : Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
