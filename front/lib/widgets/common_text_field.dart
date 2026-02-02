import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/constants/colors.dart';

class CommonTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? suffixText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final int maxLines;
  final void Function(String)? onChanged;
  final double bottomPadding;

  const CommonTextField({
    super.key,
    required this.label,
    this.hintText,
    this.suffixText,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onSaved,
    this.onTap,
    this.controller,
    this.maxLines = 1,
    this.onChanged,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
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
          const SizedBox(height: 12),

          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            onSaved: onSaved,
            onChanged: onChanged,
            maxLines: maxLines,
            cursorColor: grey03,
            style: const TextStyle(
              color: dark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
              hintText: hintText,
              hintStyle: const TextStyle(color: grey01, fontSize: 14),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 13, 0),
                      child: prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
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

              enabledBorder: _border(grey01),
              focusedBorder: _border(grey02),
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
