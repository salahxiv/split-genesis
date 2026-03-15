import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../groups/screens/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _pageController = PageController();
  bool _isSubmitting = false;
  int _currentPage = 0;

  static const int _totalPages = 4;

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onGetStarted() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);

    ref.read(displayNameProvider.notifier).set(name);
    await completeOnboarding();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: List.generate(_totalPages, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _currentPage == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(50),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _OfflineFirstPage(onNext: _nextPage),
                  _SettleUpUSPPage(onNext: _nextPage),
                  _GetStartedPage(
                    nameController: _nameController,
                    isSubmitting: _isSubmitting,
                    onGetStarted: _onGetStarted,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Page 1: Welcome

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to\nSplit Genesis',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Split expenses effortlessly with friends and groups.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// MARK: - Page 2: Offline-First (Issue #65)

class _OfflineFirstPage extends StatelessWidget {
  final VoidCallback onNext;
  const _OfflineFirstPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(30),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Your data.\nYour device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Works without internet.\nSyncs when connected.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _FeatureChip(
            icon: Icons.phone_android_rounded,
            label: 'All data stored on your device',
          ),
          const SizedBox(height: 10),
          _FeatureChip(
            icon: Icons.sync_rounded,
            label: 'Syncs automatically when back online',
          ),
          const SizedBox(height: 10),
          _FeatureChip(
            icon: Icons.lock_outline_rounded,
            label: 'Your data stays private',
          ),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Page 3: Settle-Up USP (Issue #66)

class _SettleUpUSPPage extends StatelessWidget {
  final VoidCallback onNext;
  const _SettleUpUSPPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'Fair settlements,\nalways',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          // Debt simplification animation: A → B → C becomes A → C
          const _DebtSimplificationDiagram(),
          const SizedBox(height: 28),
          Text(
            'Unlike other apps, we track who paid what. So when it\'s time to settle, everyone pays exactly what they owe — not a penny more.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Checkmark highlights
          _CheckRow(label: 'No more manual calculations.'),
          const SizedBox(height: 8),
          _CheckRow(label: 'No more awkward conversations.'),
          const Spacer(flex: 2),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  const _CheckRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Icon(Icons.check_circle_rounded,
            size: 18, color: theme.colorScheme.primary),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Animated diagram showing debt simplification:
/// Before: A → B → C (chain, costly)
/// After:  A → C (direct, optimal)
class _DebtSimplificationDiagram extends StatefulWidget {
  const _DebtSimplificationDiagram();

  @override
  State<_DebtSimplificationDiagram> createState() =>
      _DebtSimplificationDiagramState();
}

class _DebtSimplificationDiagramState
    extends State<_DebtSimplificationDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeBeforeAfter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _fadeBeforeAfter = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SizedBox(
      height: 110,
      child: AnimatedBuilder(
        animation: _fadeBeforeAfter,
        builder: (context, _) {
          final showBefore = _fadeBeforeAfter.value < 0.5;
          final opacity = showBefore
              ? 1.0 - (_fadeBeforeAfter.value * 2)
              : (_fadeBeforeAfter.value - 0.5) * 2;

          return Stack(
            children: [
              // BEFORE: A → B → C chain
              Opacity(
                opacity: showBefore ? opacity.clamp(0.0, 1.0) : (1 - opacity).clamp(0.0, 1.0),
                child: _buildBeforeLayout(theme, primary),
              ),
              // AFTER: A → C direct
              Opacity(
                opacity: showBefore ? (1 - opacity).clamp(0.0, 1.0) : opacity.clamp(0.0, 1.0),
                child: _buildAfterLayout(theme, primary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBeforeLayout(ThemeData theme, Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Other apps',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            _PersonNode(label: 'A', color: Colors.orange),
            _Arrow(label: '\$10'),
            _PersonNode(label: 'B', color: Colors.purple),
            _Arrow(label: '\$10'),
            _PersonNode(label: 'C', color: Colors.teal),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A owes B, B owes C — confusing!',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAfterLayout(ThemeData theme, Color primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Split Genesis',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            _PersonNode(label: 'A', color: Colors.orange),
            _Arrow(label: '\$10', color: primary),
            _PersonNode(label: 'C', color: Colors.teal),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A pays C directly. Done. ✓',
          style: theme.textTheme.bodySmall?.copyWith(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PersonNode extends StatelessWidget {
  final String label;
  final Color color;
  const _PersonNode({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final String label;
  final Color color;
  const _Arrow({required this.label, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
        ),
        Icon(Icons.arrow_forward_rounded, size: 18, color: color),
      ],
    );
  }
}

// MARK: - Page 4: Get Started (name input)

class _GetStartedPage extends StatelessWidget {
  final TextEditingController nameController;
  final bool isSubmitting;
  final VoidCallback onGetStarted;
  final VoidCallback onChanged;

  const _GetStartedPage({
    required this.nameController,
    required this.isSubmitting,
    required this.onGetStarted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            "What's your name?",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'So your friends know who you are.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onGetStarted(),
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLowest,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: nameController.text.trim().isEmpty || isSubmitting
                  ? null
                  : onGetStarted,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
