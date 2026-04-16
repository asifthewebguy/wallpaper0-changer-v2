import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassFormField extends StatefulWidget {
  const GlassFormField({
    super.key,
    required this.label,
    required this.onBlur,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
    this.helperText,
    this.controller,
  });

  final String label;
  final String? initialValue;
  final void Function(String) onBlur;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? helperText;
  final TextEditingController? controller;

  @override
  State<GlassFormField> createState() => _GlassFormFieldState();
}

class _GlassFormFieldState extends State<GlassFormField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  late String _lastCommitted;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      if (widget.initialValue != null && _controller.text.isEmpty) {
        _controller.text = widget.initialValue!;
      }
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _ownsController = true;
    }
    _lastCommitted = _controller.text;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant GlassFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync when we own the controller — external controllers are
    // the parent's responsibility. Also ignore if the user has pending
    // edits that haven't been committed yet (avoid clobbering typing).
    if (_ownsController &&
        widget.initialValue != oldWidget.initialValue &&
        _controller.text == _lastCommitted) {
      final next = widget.initialValue ?? '';
      _controller.text = next;
      _lastCommitted = next;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _controller.text;
      if (text != _lastCommitted) {
        _lastCommitted = text;
        widget.onBlur(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
