import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/routes/navigation_type.dart';

class PostPendingApprovalPage extends StatelessWidget {
  const PostPendingApprovalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GradientLayout(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // 체크마크 아이콘
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 메인 텍스트
                    const Text(
                      'Your post is pending approval',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: green,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // 서브 텍스트
                    const Text(
                      'Receive an alert when your submission is approved?',
                      style: TextStyle(
                        fontSize: 12,
                        color: grey04,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 버튼들
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Notify Me 버튼
                    PrimaryButton(
                      formKey: GlobalKey<FormState>(),
                      text: 'Notify Me',
                      color: green,
                      textColor: Colors.white,
                      isLoading: false,
                      onAction: () async {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        return true;
                      },
                      successMessage: '',
                      failMessage: '',
                      enabled: true,
                    ),

                    const SizedBox(height: 12),

                    // Done 버튼
                    PrimaryButton(
                      formKey: GlobalKey<FormState>(),
                      text: 'Done',
                      isLoading: false,
                      onAction: () async {
                        return true;
                      },
                      successMessage: '',
                      failMessage: '',
                      nextRoute: '/index',
                      navigationType: NavigationType.clearStack,
                      enabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
