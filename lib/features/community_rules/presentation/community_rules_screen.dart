import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class CommunityRulesScreen extends ConsumerStatefulWidget {
  const CommunityRulesScreen({super.key});

  @override
  ConsumerState<CommunityRulesScreen> createState() => _CommunityRulesScreenState();
}

class _CommunityRulesScreenState extends ConsumerState<CommunityRulesScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _hasAccepted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 20.0) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_hasAccepted || !_hasScrolledToBottom) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      
      // Save rules acceptance server-side
      await authRepo.acceptCommunityRules(
        rulesVersion: 'v1.0.0',
        locale: 'en',
        appVersion: '1.0.0',
      );

      // Navigate to Verification Pending Screen
      if (mounted) {
        context.go('/verification-pending');
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBurgundy))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20.0),
                  Text(
                    'Loverage Community Rules',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primaryBurgundy,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Please review and agree to our guidelines before finishing registration.',
                    style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20.0),
                  
                  // Rules Scrollbox
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: ListView(
                          controller: _scrollController,
                          children: const [
                            Text(
                              'By using Loverage, you confirm that:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
                            ),
                            SizedBox(height: 16.0),
                            RuleItem(number: 1, text: 'You are using Loverage only for serious marriage intentions.'),
                            RuleItem(number: 2, text: 'You will be honest about your identity, age, relationship status, and intentions.'),
                            RuleItem(number: 3, text: 'You will treat every member with respect and good manners.'),
                            RuleItem(number: 4, text: 'You will not upload nude, sexual, offensive, or inappropriate photos.'),
                            RuleItem(number: 5, text: 'You will not send sexual messages, harass, threaten, or pressure anyone.'),
                            RuleItem(number: 6, text: 'You will not create fake profiles, scam users, or ask for money.'),
                            RuleItem(number: 7, text: 'You will respect another person’s decision if they are not interested.'),
                            RuleItem(number: 8, text: 'You will keep conversations appropriate and focused on serious compatibility.'),
                            RuleItem(number: 9, text: 'You must be at least 18 years old to use Loverage.'),
                            RuleItem(number: 10, text: 'You will report any suspicious, abusive, or inappropriate behavior.'),
                            SizedBox(height: 20.0),
                            Text(
                              'Loverage is a respectful community created exclusively for adults seeking serious marriage and commitment. Violating these rules will result in immediate suspension.',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13.0, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20.0),
                  
                  // Scroll hint
                  if (!_hasScrolledToBottom)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Please scroll to the bottom to enable agreement',
                          style: TextStyle(color: AppColors.error, fontSize: 12.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  
                  // Acceptance checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _hasAccepted,
                        activeColor: AppColors.primaryBurgundy,
                        onChanged: _hasScrolledToBottom 
                            ? (value) => setState(() => _hasAccepted = value ?? false)
                            : null,
                      ),
                      const Expanded(
                        child: Text(
                          'I have read, understood, and agree to follow these community rules.',
                          style: TextStyle(fontSize: 13.0, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  
                  FilledButton(
                    onPressed: (_hasAccepted && _hasScrolledToBottom) ? _submit : null,
                    child: const Text('I Agree & Continue'),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
      ),
    );
  }
}

class RuleItem extends StatelessWidget {
  final int number;
  final String text;

  const RuleItem({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10.0,
            backgroundColor: AppColors.primaryBurgundy.withOpacity(0.1),
            child: Text(
              '$number',
              style: const TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: AppColors.primaryBurgundy),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.0, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
