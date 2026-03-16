import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/navigation/main_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _pageController = PageController();
  bool _isSubmitting = false;
  int _currentPage = 0;

  static const int _totalPages = 3;

  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _dotController.dispose();
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
        PageRouteBuilder(
          pageBuilder: (ctx, anim, sec) => const MainShell(),
          transitionsBuilder: (ctx, anim, sec, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(40),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _nextPage),
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

// MARK: - Shared Entrance Animation Wrapper

class _AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedEntrance({required this.child, this.delay = Duration.zero});

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

// MARK: - Hero Illustration: Welcome

class _SplitIllustration extends StatefulWidget {
  const _SplitIllustration();

  @override
  State<_SplitIllustration> createState() => _SplitIllustrationState();
}

class _SplitIllustrationState extends State<_SplitIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return SizedBox(
          width: 220,
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Glowing background blob
              Positioned(
                child: Container(
                  width: 160 + 20 * math.sin(t * math.pi),
                  height: 160 + 20 * math.sin(t * math.pi),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primary.withAlpha(isDark ? 60 : 30),
                        primary.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Receipt card
              Transform.translate(
                offset: Offset(0, -4 + 4 * math.sin(t * math.pi)),
                child: Container(
                  width: 130,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withAlpha(isDark ? 80 : 40),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.doc_text,
                            color: primary, size: 24),
                      ),
                      const SizedBox(height: 12),
                      // Fake receipt lines
                      ...[0.7, 0.5, 0.6, 0.4].map((w) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: 6, left: 20, right: 20),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(20)
                                    : Colors.grey.withAlpha(40),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              width: 80 * w,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              // Avatar bubbles
              Positioned(
                left: 0,
                top: 30,
                child: Transform.translate(
                  offset: Offset(-4 * math.sin(t * math.pi * 0.7), 0),
                  child: _AvatarBubble(
                      letter: 'A', color: Colors.orange, primary: primary),
                ),
              ),
              Positioned(
                right: 0,
                top: 50,
                child: Transform.translate(
                  offset: Offset(4 * math.sin(t * math.pi * 0.9), 0),
                  child: _AvatarBubble(
                      letter: 'B', color: Colors.purple, primary: primary),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 20,
                child: Transform.translate(
                  offset: Offset(0, 4 * math.sin(t * math.pi * 0.8)),
                  child: _AvatarBubble(
                      letter: 'C', color: Colors.teal, primary: primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String letter;
  final Color color;
  final Color primary;

  const _AvatarBubble(
      {required this.letter, required this.color, required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(180), width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(60), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
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
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 100),
            child: const _SplitIllustration(),
          ),
          const SizedBox(height: 32),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Welcome to\nSplitty',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Split expenses with friends,\nsimply and fairly.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(flex: 2),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 400),
            child: _PrimaryButton(label: 'Get Started', onPressed: onNext),
          ),
          const SizedBox(height: 12),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 450),
            child: Text(
              'Free · No account needed · Works offline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// MARK: - Page 2: Settle-Up USP

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
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 100),
            child: const _DebtSimplificationDiagram(),
          ),
          const SizedBox(height: 32),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Fair settlements,\nalways',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'We track exactly who owes what — so when\nit\'s time to settle, everyone pays fairly.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 350),
            child: Column(
              children: [
                _FeatureRow(
                  icon: CupertinoIcons.sum,
                  color: Colors.orange,
                  label: 'Automatic debt simplification',
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: CupertinoIcons.wifi_slash,
                  color: Colors.green,
                  label: 'Works offline, syncs automatically',
                ),
                const SizedBox(height: 10),
                _FeatureRow(
                  icon: CupertinoIcons.lock,
                  color: theme.colorScheme.primary,
                  label: 'Your data stays private',
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 400),
            child: _PrimaryButton(label: 'Next', onPressed: onNext),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _FeatureRow(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : Colors.white.withAlpha(200),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(15)
              : Colors.black.withAlpha(8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(CupertinoIcons.checkmark_circle_fill, color: color, size: 18),
        ],
      ),
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

class _DebtSimplificationDiagramState extends State<_DebtSimplificationDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeBeforeAfter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _fadeBeforeAfter = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _fadeBeforeAfter,
        builder: (context, _) {
          final showBefore = _fadeBeforeAfter.value < 0.5;
          final opacity = showBefore
              ? 1.0 - (_fadeBeforeAfter.value * 2)
              : (_fadeBeforeAfter.value - 0.5) * 2;

          return Stack(
            children: [
              Opacity(
                opacity: showBefore
                    ? opacity.clamp(0.0, 1.0)
                    : (1 - opacity).clamp(0.0, 1.0),
                child: _buildBeforeLayout(theme),
              ),
              Opacity(
                opacity: showBefore
                    ? (1 - opacity).clamp(0.0, 1.0)
                    : opacity.clamp(0.0, 1.0),
                child: _buildAfterLayout(theme, primary),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBeforeLayout(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'OTHER APPS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            fontWeight: FontWeight.w500,
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
          'SPLITTY',
          style: theme.textTheme.labelSmall?.copyWith(
            color: primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: color, fontSize: 16),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final String label;
  final Color color;
  const _Arrow({required this.label, this.color = const Color(0xFF8E8E93)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Icon(CupertinoIcons.arrow_right, size: 18, color: color),
        ],
      ),
    );
  }
}

// MARK: - Page 3: Get Started (name input)

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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 100),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withAlpha(180),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 200),
            child: Text(
              "What's your name?",
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 300),
            child: Text(
              'So your friends know who you are.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 350),
            child: CupertinoTextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onGetStarted(),
              onChanged: (_) => onChanged(),
              placeholder: 'Your name',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              style: TextStyle(
                fontSize: 17,
                color: isDark ? Colors.white : Colors.black,
              ),
              placeholderStyle: TextStyle(
                fontSize: 17,
                color: isDark
                    ? Colors.white.withAlpha(80)
                    : Colors.black.withAlpha(80),
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(12),
                ),
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  CupertinoIcons.person,
                  size: 18,
                  color: isDark
                      ? Colors.white.withAlpha(100)
                      : Colors.black.withAlpha(80),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _AnimatedEntrance(
            delay: const Duration(milliseconds: 400),
            child: _PrimaryButton(
              label: isSubmitting ? null : 'Get Started',
              onPressed: nameController.text.trim().isEmpty || isSubmitting
                  ? null
                  : onGetStarted,
              loading: isSubmitting,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// MARK: - Shared Primary Button

class _PrimaryButton extends StatelessWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool loading;

  const _PrimaryButton({
    this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CupertinoActivityIndicator(
                    color: Colors.white),
              )
            : Text(
                label ?? '',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }
}
