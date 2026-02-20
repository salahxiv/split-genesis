import 'package:flutter/material.dart';
import 'numpad_button.dart';

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

class _AmountNumpadState extends State<AmountNumpad> {
  String _input = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialAmount > 0) {
      final formatted = widget.initialAmount.toStringAsFixed(2);
      // Remove trailing zeros after decimal but keep meaningful digits
      if (formatted.contains('.')) {
        _input = formatted.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
        if (_input == '0') _input = '';
      } else {
        _input = formatted;
      }
    }
  }

  double get _amount {
    if (_input.isEmpty) return 0;
    return double.tryParse(_input) ?? 0;
  }

  String get _displayText {
    if (_input.isEmpty) return '0.00';
    final amount = double.tryParse(_input);
    if (amount == null) return _input;
    // If input has a decimal point, show as-is with padding
    if (_input.contains('.')) {
      final parts = _input.split('.');
      final decimals = parts.length > 1 ? parts[1] : '';
      if (decimals.length >= 2) return _input;
      if (decimals.length == 1) return '$_input\u200B'; // Show one decimal
      return '$_input\u200B\u200B'; // Just the dot
    }
    return '$_input.00';
  }

  void _appendDigit(String digit) {
    // Prevent leading zeros (except 0.xx)
    if (_input == '0' && digit != '.') {
      setState(() {
        _input = digit;
      });
      widget.onAmountChanged(_amount);
      return;
    }

    // Max 2 decimal places
    if (_input.contains('.')) {
      final parts = _input.split('.');
      if (parts.length > 1 && parts[1].length >= 2) return;
    }

    // Only one decimal point
    if (digit == '.' && _input.contains('.')) return;

    // Add leading zero before decimal
    if (digit == '.' && _input.isEmpty) {
      setState(() {
        _input = '0.';
      });
      widget.onAmountChanged(_amount);
      return;
    }

    // Limit total length
    if (_input.length >= 10) return;

    setState(() {
      _input += digit;
    });
    widget.onAmountChanged(_amount);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
    });
    widget.onAmountChanged(_amount);
  }

  void _clear() {
    setState(() {
      _input = '';
    });
    widget.onAmountChanged(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Amount display
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              '\$ $_displayText',
              key: ValueKey(_displayText),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _input.isEmpty
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(80)
                    : Theme.of(context).colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Numpad grid
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map((digit) => NumpadButton(
                        label: digit,
                        onTap: () => _appendDigit(digit),
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
              NumpadButton(
                label: '.',
                onTap: () => _appendDigit('.'),
              ),
              NumpadButton(
                label: '0',
                onTap: () => _appendDigit('0'),
              ),
              NumpadButton(
                icon: Icons.backspace_outlined,
                onTap: _backspace,
                onLongPress: _clear,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
