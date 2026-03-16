import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class AmountNumpad extends StatefulWidget {
  final double initialAmount;
  final ValueChanged<double> onAmountChanged;

  const AmountNumpad({
    super.key,
    this.initialAmount = 0,
    required this.onAmountChanged,
  });

  @override
  State<AmountNumpad> createState() => _AmountNumpadState();
}

class _AmountNumpadState extends State<AmountNumpad>
    with SingleTickerProviderStateMixin {
  String _input = '';

  // Scale animation for amount display bounce on each keystroke
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_bounceController);

    if (widget.initialAmount > 0) {
      final formatted = widget.initialAmount.toStringAsFixed(2);
      if (formatted.contains('.')) {
        _input = formatted
            .replaceAll(RegExp(r'0+$'), '')
            .replaceAll(RegExp(r'\.$'), '');
        if (_input == '0') _input = '';
      } else {
        _input = formatted;
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  double get _amount {
    if (_input.isEmpty) return 0;
    return double.tryParse(_input) ?? 0;
  }

  String get _displayText {
    if (_input.isEmpty) return '0.00';
    final amount = double.tryParse(_input);
    if (amount == null) return _input;
    if (_input.contains('.')) {
      final parts = _input.split('.');
      final decimals = parts.length > 1 ? parts[1] : '';
      if (decimals.length >= 2) return _input;
      if (decimals.length == 1) return '$_input\u200B';
      return '$_input\u200B\u200B';
    }
    return '$_input.00';
  }

  bool get _hasValue => _input.isNotEmpty && _amount > 0;

  void _triggerBounce() {
    _bounceController
      ..reset()
      ..forward();
  }

  void _appendDigit(String digit) {
    // Prevent leading zeros (except 0.xx)
    if (_input == '0' && digit != '.') {
      setState(() => _input = digit);
      _triggerBounce();
      widget.onAmountChanged(_amount);
      return;
    }

    // Max 2 decimal places
    if (_input.contains('.')) {
      final parts = _input.split('.');
      if (parts.length > 1 && parts[1].length >= 2) return;
    }

    if (digit == '.' && _input.contains('.')) return;

    if (digit == '.' && _input.isEmpty) {
      setState(() => _input = '0.');
      _triggerBounce();
      widget.onAmountChanged(_amount);
      return;
    }

    if (_input.length >= 10) return;

    setState(() => _input += digit);
    _triggerBounce();
    widget.onAmountChanged(_amount);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _input = _input.substring(0, _input.length - 1));
    widget.onAmountChanged(_amount);
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    setState(() => _input = '');
    widget.onAmountChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Amount display ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _bounceAnimation.value,
                  child: child,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _displayText,
                    key: ValueKey(_displayText),
                    style: TextStyle(
                      fontSize: _hasValue ? 64 : 56,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                      color: _hasValue
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withAlpha(60),
                    ),
                  ),
                ),
              ),
              // Subtle underline beneath amount
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: _hasValue ? 120 : 60,
                decoration: BoxDecoration(
                  color: _hasValue
                      ? AppTheme.primaryColor
                      : theme.colorScheme.onSurface.withAlpha(30),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // ── Numpad grid ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (final row in [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: row
                        .map((digit) => _PolishedNumpadButton(
                              label: digit,
                              onTap: () => _appendDigit(digit),
                              isDark: isDark,
                            ))
                        .toList(),
                  ),
                ),
              // Bottom row: . 0 ⌫
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PolishedNumpadButton(
                      label: '.',
                      onTap: () => _appendDigit('.'),
                      isDark: isDark,
                    ),
                    _PolishedNumpadButton(
                      label: '0',
                      onTap: () => _appendDigit('0'),
                      isDark: isDark,
                    ),
                    _PolishedNumpadButton(
                      icon: Icons.backspace_outlined,
                      onTap: _backspace,
                      onLongPress: _clear,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Polished Numpad Button — larger, haptic, spring scale, subtle glow on press
// ─────────────────────────────────────────────────────────────────────────────

class _PolishedNumpadButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDark;

  const _PolishedNumpadButton({
    this.label = '',
    this.icon,
    required this.onTap,
    this.onLongPress,
    required this.isDark,
  });

  @override
  State<_PolishedNumpadButton> createState() => _PolishedNumpadButtonState();
}

class _PolishedNumpadButtonState extends State<_PolishedNumpadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _up(TapUpDetails _) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _cancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalBg =
        widget.isDark ? Colors.white.withAlpha(18) : Colors.grey.shade100;
    final pressedBg =
        widget.isDark ? Colors.white.withAlpha(30) : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _cancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onLongPress: widget.onLongPress != null
            ? () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isPressed ? pressedBg : normalBg,
            boxShadow: _isPressed
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(
                          widget.isDark ? 40 : 15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  size: 22,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
