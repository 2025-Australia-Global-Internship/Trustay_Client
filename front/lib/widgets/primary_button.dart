import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';

class PrimaryButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String text;
  final Future<bool>? Function()? onAction;
  final String successMessage;
  final String failMessage;
  final String nextRoute;

  const PrimaryButton({
    super.key,
    required this.formKey,
    required this.text,
    required this.onAction,
    required this.successMessage,
    required this.failMessage,
    required this.nextRoute,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: darkgreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: isLoading
            ? null
            : () async {
                if (formKey.currentState != null) {
                  if (!formKey.currentState!.validate()) return;
                  formKey.currentState!.save();
                }

                final success = await onAction?.call() ?? true;

                if (!context.mounted) return;

                if (success) {
                  Navigator.pushReplacementNamed(context, nextRoute);
                }
              },
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: dark),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'NanumSquareNeo',
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
