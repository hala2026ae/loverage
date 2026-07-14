import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlan = 1; // default: 3-months
  bool _loading = false;

  static const _plans = [
    _Plan(id: 0, duration: '1 Month', price: '\$14.99', pricePerMonth: '\$14.99/mo', tag: null),
    _Plan(id: 1, duration: '3 Months', price: '\$29.99', pricePerMonth: '\$9.99/mo', tag: 'Most Popular'),
    _Plan(id: 2, duration: '6 Months', price: '\$47.99', pricePerMonth: '\$7.99/mo', tag: 'Best Value'),
  ];

  static const _features = [
    _Feature(icon: Icons.favorite_rounded, title: 'Unlimited Knocks', desc: 'Show interest to as many profiles as you like'),
    _Feature(icon: Icons.chat_bubble_rounded, title: 'Message Anyone', desc: 'Start conversations without waiting for a knock'),
    _Feature(icon: Icons.tune_rounded, title: 'Advanced Filters', desc: 'Filter by education, lifestyle, values, and more'),
    _Feature(icon: Icons.visibility_rounded, title: 'See Who Viewed You', desc: 'Know who found your profile interesting'),
    _Feature(icon: Icons.star_rounded, title: 'Priority Discovery', desc: 'Appear at the top of match feeds'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDarkBurgundy,
      body: Stack(
        children: [
          // Background
          Container(decoration: const BoxDecoration(gradient: AppColors.backgroundRadial)),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Restore', style: TextStyle(color: Colors.white54, fontSize: 13.5)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Crown icon
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.roseGoldGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFD4956A).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Loverage Premium',
                          style: AppTheme.serifHeadline(
                            fontSize: 32,
                            color: Colors.white,
                          ).copyWith(
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Everything you need to find\nyour life partner',
                          textAlign: TextAlign.center,
                          style: AppTheme.sansText(
                            fontSize: 15.5,
                            weight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.65),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Features list
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: _features.map((f) => _FeatureRow(feature: f)).toList(),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Plan selection
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: _plans.map((p) => _PlanTile(
                              plan: p,
                              isSelected: _selectedPlan == p.id,
                              onTap: () => setState(() => _selectedPlan = p.id),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom CTA
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.primaryDarkBurgundy.withOpacity(0.98)],
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_loading)
                        const CircularProgressIndicator(color: AppColors.accentRoseGold)
                      else
                        GestureDetector(
                          onTap: _purchase,
                          child: Container(
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: AppColors.roseGoldGradient,
                              borderRadius: BorderRadius.circular(AppRadius.circular),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentRoseGold.withOpacity(0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Start Premium — ${_plans[_selectedPlan].price}',
                              style: const TextStyle(
                                color: AppColors.primaryDarkBurgundy,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Cancel anytime · Secure payment · No hidden fees',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Loverage Premium! ✨'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final _Feature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentRoseGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, color: AppColors.accentRoseGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(feature.desc, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF86EFAC), size: 20),
          ],
        ),
      );
}

class _PlanTile extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onTap;
  const _PlanTile({required this.plan, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRoseGold.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(
            color: isSelected ? AppColors.accentRoseGold : Colors.white.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accentRoseGold : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.accentRoseGold : Colors.white30,
                  width: 2,
                ),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.duration, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(plan.pricePerMonth, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                if (plan.tag != null)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentRoseGold,
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Text(plan.tag!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Plan {
  final int id;
  final String duration, price, pricePerMonth;
  final String? tag;
  const _Plan({required this.id, required this.duration, required this.price, required this.pricePerMonth, required this.tag});
}

class _Feature {
  final IconData icon;
  final String title, desc;
  const _Feature({required this.icon, required this.title, required this.desc});
}
