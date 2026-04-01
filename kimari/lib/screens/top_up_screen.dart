import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountController = TextEditingController(text: '100');
  int _selectedMethod = 0;
  int _selectedAmount = 2; // $100

  final _methods = [
    _PayMethod(icon: Icons.credit_card_rounded, label: 'Debit Card', detail: '•••• 4321', color: AppColors.accent),
    _PayMethod(icon: Icons.account_balance_rounded, label: 'Bank Transfer', detail: 'ZB Bank', color: AppColors.teal),
    _PayMethod(icon: Icons.phone_android_rounded, label: 'EcoCash', detail: '+263 77 123 4567', color: AppColors.gold),
  ];

  final _quickAmounts = ['20', '50', '100', '200', '500'];

  @override
  void dispose() {
    _amountController.dispose();
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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountCard(),
                      const SizedBox(height: 24),
                      const Text('Quick Amounts', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _buildQuickAmounts(),
                      const SizedBox(height: 24),
                      const Text('Payment Method', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ..._methods.asMap().entries.map((e) => _buildMethodTile(e.key, e.value)),
                      const SizedBox(height: 24),
                      _buildTimeEstimate(),
                      const SizedBox(height: 32),
                      _buildTopUpButton(context),
                      const SizedBox(height: 16),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18),
            ),
          ),
          const Spacer(),
          const Text('Top Up Wallet', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF003D3D), Color(0xFF1E1E3A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.teal.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('Amount to Add', style: TextStyle(color: AppColors.textMuted, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('\$', style: TextStyle(color: AppColors.teal, fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 48, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [AppColors.teal, AppColors.accentGlow]).createShader(b),
            child: const Text('Instant deposit · No fees', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    return Wrap(
      spacing: 10,
      children: _quickAmounts.asMap().entries.map((e) {
        final selected = _selectedAmount == e.key;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAmount = e.key;
              _amountController.text = e.value;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.teal.withOpacity(0.2) : AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: selected ? AppColors.teal : AppColors.surfaceLight),
            ),
            child: Text('\$${e.value}', style: TextStyle(color: selected ? AppColors.teal : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMethodTile(int index, _PayMethod method) {
    final selected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? method.color.withOpacity(0.1) : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? method.color : AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: method.color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(method.icon, color: method.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(method.detail, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: method.color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEstimate() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.flash_on_rounded, color: AppColors.success, size: 18),
          SizedBox(width: 10),
          Text('Funds available instantly after confirmation', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTopUpButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showSuccessDialog(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.teal, AppColors.accent]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text('Add \$${_amountController.text} to Wallet', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.teal, AppColors.success]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Added \$${_amountController.text}!', style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Your wallet has been topped up successfully.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.teal, AppColors.accent]), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayMethod {
  final IconData icon;
  final String label, detail;
  final Color color;
  const _PayMethod({required this.icon, required this.label, required this.detail, required this.color});
}
