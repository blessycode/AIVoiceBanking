import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'transaction_success_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  int? _selectedBill;

  final _bills = [
    _Bill(icon: Icons.bolt, label: 'ZESA Electricity', detail: 'Meter: 1234567', color: AppColors.gold, dueDate: 'Due Nov 5', amount: '\$25.00'),
    _Bill(icon: Icons.water_drop_rounded, label: 'ZimWater', detail: 'Account: 987654', color: const Color(0xFF2196F3), dueDate: 'Due Nov 10', amount: '\$15.00'),
    _Bill(icon: Icons.wifi_rounded, label: 'TelOne Internet', detail: 'Account: ZIM-223', color: AppColors.teal, dueDate: 'Due Nov 15', amount: '\$35.00'),
    _Bill(icon: Icons.home_rounded, label: 'NSSA Fees', detail: 'ID: 557722', color: AppColors.accentLight, dueDate: 'Due Nov 20', amount: '\$10.00'),
    _Bill(icon: Icons.local_hospital_rounded, label: 'PSMAS Medical', detail: 'Scheme: Gold', color: AppColors.error, dueDate: 'Due Nov 30', amount: '\$55.00'),
    _Bill(icon: Icons.school_rounded, label: 'School Fees', detail: 'Ref: SF-2024-B', color: AppColors.success, dueDate: 'Due Nov 25', amount: '\$200.00'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildDueSummary(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _bills.length,
                  itemBuilder: (_, i) => _buildBillCard(context, i, _bills[i]),
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
            child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceLight.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18)),
          ),
          const Spacer(),
          const Text('Pay Bills', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.add_rounded, color: AppColors.accentGlow, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildDueSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3D2080), Color(0xFF1E1E3A)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: AppColors.accentGlow, size: 28),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Due This Month', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('\$340.00', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionSuccessScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]), borderRadius: BorderRadius.circular(12)),
                child: const Text('Pay All', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, int index, _Bill bill) {
    final selected = _selectedBill == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBill = selected ? null : index);
        if (!selected) _showPaySheet(context, bill);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? bill.color.withOpacity(0.1) : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? bill.color : AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: bill.color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(bill.icon, color: bill.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(bill.detail, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: AppColors.gold, size: 12),
                      const SizedBox(width: 4),
                      Text(bill.dueDate, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(bill.amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bill.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Pay Now', style: TextStyle(color: bill.color, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaySheet(BuildContext context, _Bill bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: bill.color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(bill.icon, color: bill.color, size: 30),
            ),
            const SizedBox(height: 14),
            Text(bill.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(bill.amount, style: const TextStyle(color: AppColors.textPrimary, fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(bill.dueDate, style: const TextStyle(color: AppColors.gold, fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionSuccessScreen()));
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.teal]), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text('Pay ${bill.amount} Now', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Bill {
  final IconData icon;
  final String label, detail, dueDate, amount;
  final Color color;
  const _Bill({required this.icon, required this.label, required this.detail, required this.color, required this.dueDate, required this.amount});
}
