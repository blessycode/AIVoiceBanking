import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'voice_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoNavigate = true});

  final bool autoNavigate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _pulse;
  late Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _contentFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _logoController.forward().then((_) {
      _fadeController.forward();
      if (widget.autoNavigate) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _navigateToAuth();
          }
        });
      }
    });
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) =>
            const VoiceHomeScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(top: 40, left: 30, child: _buildGlowOrb(60, AppColors.accent.withOpacity(0.3))),
                    Positioned(top: 80, right: 20, child: _buildGlowOrb(40, AppColors.teal.withOpacity(0.25))),
                    Positioned(bottom: 20, left: 50, child: _buildGlowOrb(30, AppColors.accentLight.withOpacity(0.2))),
                    AnimatedBuilder(
                      animation: Listenable.merge([_logoController, _pulseController]),
                      builder: (context, child) => FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(scale: _logoScale.value * _pulse.value, child: child),
                      ),
                      child: _buildLogo(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 80, child: _WaveformWidget(controller: _waveController)),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _contentFade,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.accent.withOpacity(0.1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: AppColors.success, size: 8),
                      SizedBox(width: 8),
                      Text('Listening...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _contentFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _navigateToAuth,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF2A2A4A), Color(0xFF1E1E3A)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic, color: AppColors.accentGlow, size: 18),
                              SizedBox(width: 10),
                              Text('Launch the live voice banking session', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _navigateToAuth,
                        child: const Text('Continue →', style: TextStyle(color: AppColors.accentLight, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.teal]),
            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 20),
        const Text('Jonten', style: TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.accentGradient.createShader(bounds),
          child: const Text('Your AI Voice Banking Assistant', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildGlowOrb(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: size, spreadRadius: size * 0.3)]),
    );
  }
}

class _WaveformWidget extends StatelessWidget {
  final AnimationController controller;
  const _WaveformWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => CustomPaint(painter: _WavePainter(controller.value), size: const Size(double.infinity, 80)),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  _WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 30;
    final barWidth = size.width / (bars * 2);
    final centerY = size.height / 2;

    for (int i = 0; i < bars; i++) {
      final x = i * barWidth * 2 + barWidth;
      final phase = (i / bars + progress) * 2 * pi;
      final height = (sin(phase) * 0.5 + 0.5) * size.height * 0.8 + 4;

      final gradient = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.accent.withOpacity(0.9), AppColors.teal.withOpacity(0.7)],
      );
      final rect = Rect.fromCenter(center: Offset(x, centerY), width: barWidth * 0.7, height: height);
      final paint = Paint()..shader = gradient.createShader(rect)..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.progress != progress;
}
