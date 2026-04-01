import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'voice_transaction_screen.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final _amountController = TextEditingController(text: '50');
  final _noteController = TextEditingController();
  int _selectedRecipient = 0;

  final _recipients = [
    _Recipient(initials: 'SN', name: 'Simon Ndlovu', number: '•••• 8291', color: const Color(0xFF4CAF50)),
    _Recipient(initials: 'FM', name: 'Farai Moyo', number: '•••• 4512', color: const Color(0xFF2196F3)),
    _Recipient(initials: 'TC', name: 'Tendai Chikutu', number: '•••• 7734', color: const Color(0xFFFF9800)),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
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
                        const SizedBox(height: 8),
                        _buildAmountSection(),
                        const SizedBox(height: 24),
                        _buildRecipientsSection(),
                        const SizedBox(height: 24),
                        _buildNoteSection(),
                        const SizedBox(height: 24),
                        _buildFeeInfo(),
                        const SizedBox(height: 32),
                        _buildSendButtons(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18),
            ),
          ),
          const Spacer(),
          const Text('Send Money', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.accentGlow, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3D2080), Color(0xFF1E1E3A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('Amount to Send', style: TextStyle(color: AppColors.textMuted, fontSize: 13, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('\$', style: TextStyle(color: AppColors.textMuted, fontSize: 24, fontWeight: FontWeight.w700)),
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
          const SizedBox(height: 8),
          const Text('Available: \$1,240.50', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          // Quick amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['10', '25', '50', '100'].map((amt) {
              final selected = _amountController.text == amt;
              return GestureDetector(
                onTap: () => setState(() => _amountController.text = amt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent.withOpacity(0.25) : AppColors.surfaceLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? AppColors.accentLight : AppColors.surfaceLight),
                  ),
                  child: Text('\$$amt', style: TextStyle(color: selected ? AppColors.accentGlow : AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recipients', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddRecipientSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: AppColors.accentGlow, size: 14),
                    SizedBox(width: 4),
                    Text('Add New', style: TextStyle(color: AppColors.accentGlow, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recipients.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final selected = _selectedRecipient == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedRecipient = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent.withOpacity(0.12) : AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? AppColors.accent : AppColors.surfaceLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: r.color.withOpacity(0.2), shape: BoxShape.circle),
                    child: Center(child: Text(r.initials, style: TextStyle(color: r.color, fontSize: 16, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(r.number, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.3), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: AppColors.accentGlow, size: 14),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Note (Optional)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'e.g. Rent payment, school fees...',
              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                children: [
                  TextSpan(text: 'Transaction fee: '),
                  TextSpan(text: '\$0.00', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                  TextSpan(text: '  ·  Total: '),
                  TextSpan(text: '\$50.00', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButtons(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceTransactionScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Send \$${_amountController.text} to ${_recipients[_selectedRecipient].name.split(' ').first}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceTransactionScreen())),
          icon: const Icon(Icons.mic_rounded, size: 18),
          label: const Text('Use Voice to Send'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentGlow,
            side: const BorderSide(color: AppColors.accent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  void _showAddRecipientSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Add Recipient', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _sheetField('Full Name', Icons.person_rounded),
            const SizedBox(height: 12),
            _sheetField('Account Number', Icons.credit_card_rounded),
            const SizedBox(height: 12),
            _sheetField('Phone Number', Icons.phone_rounded),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Save Recipient', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetField(String hint, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surfaceLight)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14), border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _Recipient {
  final String initials, name, number;
  final Color color;
  const _Recipient({required this.initials, required this.name, required this.number, required this.color});
}
