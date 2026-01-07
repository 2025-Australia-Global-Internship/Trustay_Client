import 'package:flutter/material.dart';

class CommonActionButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String text;
  final Future<bool>? Function()? onAction;
  final String successMessage;
  final String failMessage;
  final String nextRoute;

  const CommonActionButton({
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
          backgroundColor: const Color(0xFFFFF27B),
          foregroundColor: const Color(0xFF454B27),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF454B27),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
