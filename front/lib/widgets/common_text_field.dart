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

  final FontWeight labelFontWeight;
  final double labelFontSize;
  final EdgeInsetsGeometry prefixIconPadding;
  final EdgeInsetsGeometry suffixIconPadding;

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
    this.labelFontWeight = FontWeight.w700,
    this.labelFontSize = 14,
    this.prefixIconPadding = const EdgeInsets.fromLTRB(20, 0, 13, 0),
    this.suffixIconPadding = const EdgeInsets.only(right: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                color: dark,
                fontSize: labelFontSize,
                fontWeight: labelFontWeight,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 그림자를 위한 Container 추가
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                maxLines > 1 ? 25 : 50,
              ), // 멀티라인일 땐 살짝 덜 둥글게 조절
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
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
                contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                hintText: hintText,
                hintStyle: const TextStyle(color: grey02, fontSize: 12),
                prefixIcon: prefixIcon != null
                    ? Padding(padding: prefixIconPadding, child: prefixIcon)
                    : null,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                suffixText: suffixText,
                suffixStyle: const TextStyle(
                  color: dark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                suffixIcon: suffixIcon != null
                    ? Padding(padding: suffixIconPadding, child: suffixIcon)
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),

                // 테두리 제거 (InputBorder.none)
                filled: true,
                fillColor: Colors.transparent, // 컨테이너 배경색을 사용하므로 투명하게
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
