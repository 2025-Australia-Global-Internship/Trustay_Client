import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final String? hintText;

  const CommonDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onSaved,
    this.validator,
    this.prefixIcon,
    this.hintText,
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
          const SizedBox(height: 12),

          DropdownButtonFormField<T>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item.value,
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'NanumSquareNeo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: dark,
                  ),
                  child: item.child,
                ),
              );
            }).toList(),
            onChanged: onChanged,
            onSaved: onSaved,
            validator: validator,
            icon: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SvgPicture.asset(
                'assets/icons/arrow_down.svg',
                width: 10,
                height: 10,
              ),
            ),
            style: const TextStyle(
              fontFamily: 'NanumSquareNeo', // 입력창 텍스트 폰트
              color: dark,
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'NanumSquareNeo', // 힌트 텍스트 폰트
                color: grey02,
                fontSize: 12,
              ),
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 13, 0),
                      child: prefixIcon,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
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
