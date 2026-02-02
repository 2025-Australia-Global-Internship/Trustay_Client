import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;

  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;

  final double bottomPadding;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onSaved,
    this.bottomPadding = 30,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 라벨
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          /// 입력창
          TextFormField(
            controller: widget.controller,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onSaved: widget.onSaved,
            cursorColor: Colors.white,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: grey02,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: grey02,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscure = !_obscure;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: darkgreen.withOpacity(0.5),
              enabledBorder: _border(grey01),
              focusedBorder: _border(Colors.white),
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
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }
}
