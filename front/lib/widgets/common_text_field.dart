import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonTextField extends StatelessWidget {
  final String label;
  final String? suffixText;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final int maxLines;

  const CommonTextField({
    super.key,
    required this.label,
    this.suffixText,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.onTap,
    this.controller,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onSaved: onSaved,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          suffixText: suffixText,
          suffixIcon: suffixIcon,

          filled: true,
          fillColor: Colors.transparent,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
