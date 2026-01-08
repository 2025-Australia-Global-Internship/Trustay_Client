import 'package:flutter/material.dart';
import 'package:front/widgets/common_action_button.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro_back.png',
              fit: BoxFit.cover,
            ),
          ),

          // 어두운 오버레이 (가독성)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 텍스트 + 버튼
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore',
                  style: TextStyle(fontSize: 36, color: Color(0xFFFFF27B)),
                ),

                const Text(
                  'Your Place\nto Stay,\nBuilt on Trust.',
                  style: TextStyle(
                    fontSize: 36,
                    color: Color(0xFFFFF27B),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                CommonActionButton(
                  formKey: GlobalKey<FormState>(),
                  text: 'Get Started',
                  onAction: () async => true,
                  successMessage: '',
                  failMessage: '',
                  nextRoute: '/login',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
