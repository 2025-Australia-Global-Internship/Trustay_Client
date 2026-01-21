import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/routes/navigation_type.dart';

class PrimaryButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final String text;
  final Future<bool>? Function()? onAction;
  final String successMessage;
  final String failMessage;
  final String? nextRoute;
  final NavigationType navigationType;

  const PrimaryButton({
    super.key,
    required this.formKey,
    required this.text,
    required this.onAction,
    required this.successMessage,
    required this.failMessage,
    this.nextRoute,
    this.isLoading = false,
    this.navigationType = NavigationType.push, // 기본값
  });

  void _navigate(BuildContext context) {
    if (nextRoute == null || nextRoute!.isEmpty) return;

    switch (navigationType) {
      case NavigationType.push:
        Navigator.pushNamed(context, nextRoute!);
        break;

      case NavigationType.replace:
        Navigator.pushReplacementNamed(context, nextRoute!);
        break;

      case NavigationType.clearStack:
        Navigator.pushNamedAndRemoveUntil(
          context,
          nextRoute!,
          (route) => false,
        );
        break;
    }
  }

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
                if (!context.mounted || !success) return;

                _navigate(context);
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
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
