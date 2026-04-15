import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palee_elite_training_center/core/constants/app_colors.dart';

enum DigitOnly { integer, decimal }

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  final double? maxValue;

  _ThousandsSeparatorFormatter({this.maxValue});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (!RegExp(r'^\d+$').hasMatch(digits)) return oldValue;

    if (maxValue != null) {
      final value = double.tryParse(digits) ?? 0;
      if (value > maxValue!) {
        return oldValue;
      }
    }

    final formatted = _format(digits);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String digits) {
    final buf = StringBuffer();
    final reversed = digits.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buf.write(',');
      buf.write(reversed[i]);
    }
    return buf.toString().split('').reversed.join();
  }
}

class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final bool required;
  final bool enabled;
  final DigitOnly? digitOnly;
  final int? maxLength;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool thousandsSeparator;
  final double? maxValue;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
    this.required = false,
    this.enabled = true,
    this.digitOnly,
    this.maxLength,
    this.fontSize,
    this.fontWeight,
    this.thousandsSeparator = false,
    this.maxValue,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _animController;
  late final Animation<double> _borderAnim;
  bool _isFocused = false;
  String? _errorText;

  List<TextInputFormatter> get _inputFormatters {
    if (widget.thousandsSeparator) {
      return [_ThousandsSeparatorFormatter(maxValue: widget.maxValue)];
    }
    switch (widget.digitOnly) {
      case DigitOnly.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      case DigitOnly.decimal:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))];
      case null:
        return [];
    }
  }

  TextInputType get _keyboardType {
    switch (widget.digitOnly) {
      case DigitOnly.integer:
        return TextInputType.number;
      case DigitOnly.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      case null:
        return widget.keyboardType;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _borderAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Color get _fillColor {
    if (!widget.enabled) return AppColors.input.withOpacity(0.4);
    if (_isFocused) return AppColors.primary.withOpacity(0.04);
    return AppColors.input;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: _isFocused
                      ? AppColors.primary
                      : widget.enabled
                      ? AppColors.foreground.withOpacity(0.85)
                      : AppColors.mutedForeground,
                ),
              ),
              if (widget.required)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.destructive,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        AnimatedBuilder(
          animation: _borderAnim,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: _fillColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _errorText != null
                      ? AppColors.destructive.withOpacity(0.8)
                      : _isFocused
                      ? AppColors.primary.withOpacity(0.7)
                      : AppColors.border.withOpacity(0.5),
                  width: _isFocused || _errorText != null ? 1.5 : 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ]
                    : [],
              ),
              child: child,
            );
          },
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: _keyboardType,
            inputFormatters: _inputFormatters,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            onChanged: (v) {
              widget.onChanged?.call(v);
              final err = widget.validator?.call(v);
              if (err != _errorText) {
                setState(() => _errorText = err);
              }
            },
            maxLength: widget.maxLength,
            style: TextStyle(
              fontSize: widget.fontSize ?? 14,
              fontWeight: widget.fontWeight ?? FontWeight.w500,
              color: widget.enabled
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
              letterSpacing: 0.1,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.mutedForeground.withOpacity(0.55),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 13, right: 8),
                      child: IconTheme(
                        data: IconThemeData(
                          size: 17,
                          color: _isFocused
                              ? AppColors.primary.withOpacity(0.8)
                              : widget.enabled
                              ? AppColors.mutedForeground
                              : AppColors.border,
                        ),
                        child: widget.prefixIcon!,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 13),
                      child: IconTheme(
                        data: IconThemeData(
                          size: 17,
                          color: widget.enabled
                              ? AppColors.mutedForeground
                              : AppColors.border,
                        ),
                        child: widget.suffixIcon!,
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 0,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: widget.maxLines != null && widget.maxLines! > 1
                    ? 14
                    : 13,
              ),
              isDense: true,
              counterText: '',
            ),
          ),
        ),

        if (_errorText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 12,
                color: AppColors.destructive.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.destructive.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
