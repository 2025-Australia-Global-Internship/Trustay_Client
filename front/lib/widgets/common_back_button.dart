import 'package:flutter/material.dart';

class CommonBackButton extends StatelessWidget {
  const CommonBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      color: Colors.white,
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }
}
