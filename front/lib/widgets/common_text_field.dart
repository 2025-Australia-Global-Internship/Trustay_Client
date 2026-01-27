import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/constants/colors.dart';

class CommonTextField extends StatelessWidget {
  final String label;
  final String? hintText;
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
    this.hintText,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onSaved: onSaved,
            maxLines: maxLines,
            cursorColor: grey03,
            style: const TextStyle(
              color: dark,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 12,
              ),
              hintText: hintText,
              hintStyle: const TextStyle(color: grey01, fontSize: 14),
              suffixText: suffixText,
              suffixIcon: suffixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: suffixIcon,
                    )
                  : null,

              suffixIconConstraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),

              filled: true,
              fillColor: Colors.white,

              enabledBorder: _border(grey02),
              focusedBorder: _border(grey03),
              errorBorder: _border(Colors.redAccent),
              focusedErrorBorder: _border(Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }
}
