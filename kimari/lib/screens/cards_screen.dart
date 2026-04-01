import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  int _activeCard = 0;
  bool _showCardNumber = false;

  final _cards = [
    _Card(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C4DFF), Color(0xFF00E5CC)],
      ),
      name: 'Blessed Nyoni',
      number: '4521 3678 9012 4321',
      expiry: '08/27',
      cvv: '942',
      network: 'Visa',
      balance: '\$1,240.50',
      type: 'Virtual',
    ),
    _Card(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A237E), Color(0xFF311B92)],
      ),
      name: 'Blessed Nyoni',
      number: '5200 1234 5678 9001',
      expiry: '12/25',
      cvv: '321',
      network: 'Mastercard',
      balance: '\$210.00',
      type: 'Physical',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildCardCarousel(),
                        const SizedBox(height: 20),
                        _buildCardSelector(),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCardDetails(),
                              const SizedBox(height: 24),
                              _buildCardActions(context),
                              const SizedBox(height: 24),
                              const Text(
                                'Card Controls',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildCardControls(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'My Cards',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddCardSheet(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.accentGlow,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        onPageChanged: (i) => setState(() {
          _activeCard = i;
          _showCardNumber = false;
        }),
        itemCount: _cards.length,
        itemBuilder: (_, i) {
          final card = _cards[i];
          final isActive = _activeCard == i;
          return AnimatedScale(
            scale: isActive ? 1.0 : 0.92,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: () => setState(() => _showCardNumber = !_showCardNumber),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: card.gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            card.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          card.network,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 18,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _showCardNumber
                          ? card.number
                          : '•••• •••• •••• ${card.number.substring(card.number.length - 4)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARDHOLDER',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              card.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              card.expiry,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _cards.asMap().entries.map((e) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _activeCard == e.key ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _activeCard == e.key
                ? AppColors.accent
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardDetails() {
    final card = _cards[_activeCard];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              Text(
                card.balance,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Card Number',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              GestureDetector(
                onTap: () => setState(() => _showCardNumber = !_showCardNumber),
                child: Text(
                  _showCardNumber
                      ? card.number
                      : '•••• ${card.number.substring(card.number.length - 4)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CVV',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              Text(
                _showCardNumber ? card.cvv : '•••',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(BuildContext context) {
    final actions = [
      _CardAction(
        icon: Icons.send_rounded,
        label: 'Pay',
        color: AppColors.accent,
      ),
      _CardAction(
        icon: Icons.add_rounded,
        label: 'Top Up',
        color: AppColors.teal,
      ),
      _CardAction(
        icon: Icons.barcode_reader,
        label: 'Scan',
        color: AppColors.gold,
      ),
      _CardAction(
        icon: Icons.history_rounded,
        label: 'History',
        color: AppColors.accentLight,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map(
            (a) => Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: a.color.withOpacity(0.25)),
                  ),
                  child: Icon(a.icon, color: a.color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildCardControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          _controlTile(
            Icons.lock_rounded,
            AppColors.success,
            'Card Active',
            'Tap to freeze card',
            true,
            isFirst: true,
          ),
          Divider(
            height: 1,
            color: AppColors.surfaceLight.withOpacity(0.5),
            indent: 68,
          ),
          _controlTile(
            Icons.public_rounded,
            AppColors.teal,
            'Online Payments',
            'Enable internet transactions',
            true,
          ),
          Divider(
            height: 1,
            color: AppColors.surfaceLight.withOpacity(0.5),
            indent: 68,
          ),
          _controlTile(
            Icons.notifications_rounded,
            AppColors.accent,
            'Transaction Alerts',
            'Receive SMS notifications',
            false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _controlTile(
    IconData icon,
    Color color,
    String title,
    String sub,
    bool val, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return StatefulBuilder(
      builder: (_, set) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: val,
              onChanged: (v) => set(() {}),
              activeThumbColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add New Card',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _sheetField('Card Number', Icons.credit_card_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _sheetField('Expiry MM/YY', Icons.date_range_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(child: _sheetField('CVV', Icons.lock_rounded)),
              ],
            ),
            const SizedBox(height: 12),
            _sheetField('Cardholder Name', Icons.person_rounded),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.teal],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Add Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card {
  final LinearGradient gradient;
  final String name, number, expiry, cvv, network, balance, type;
  const _Card({
    required this.gradient,
    required this.name,
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.network,
    required this.balance,
    required this.type,
  });
}

class _CardAction {
  final IconData icon;
  final String label;
  final Color color;
  const _CardAction({
    required this.icon,
    required this.label,
    required this.color,
  });
}
