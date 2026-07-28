import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.prefix,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.errorText,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          textCapitalization: textCapitalization,
          style: TextStyle(
            color: readOnly ? AppTheme.textDarkSecondary : AppTheme.textDarkPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffixIcon,
            errorText: errorText,
            fillColor: readOnly ? const Color(0xFFF1F5F9) : AppTheme.surfaceWhite,
          ),
        ),
      ],
    );
  }
}
