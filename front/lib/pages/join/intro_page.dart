import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/routes/navigation_type.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkgreen,
      body: Stack(
        children: [
          // 1. 배경 이미지 (화면 전체 꽉 차게)
          Positioned.fill(
            child: Image.asset(
              'assets/images/intro_back.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. 어두운 오버레이 (기본 투명도 가독성 확보)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 3. 로그인 페이지와 동일한 초록색 그라데이션 효과 (맨 밑까지 꽉 차게)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    darkgreen, // 아래 단색
                    darkgreen.withOpacity(0.9), // 여기까지는 단색
                    darkgreen.withOpacity(0.0), // 위에서만 투명
                  ],
                  stops: const [0.0, 0.25, 1.0], // 그라데이션 범위 조절
                ),
              ),
            ),
          ),

          // 4. 텍스트 + 버튼 UI 영역
          // SafeArea를 씌워서 하단 홈 버튼/내비게이션 바에 글씨나 버튼이 가려지지 않게 보호합니다.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 36,
                      color: yellow,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Your Place\nto Stay,\nBuilt on Trust.',
                    style: TextStyle(
                      fontSize: 36,
                      color: yellow,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    formKey: GlobalKey<FormState>(),
                    text: 'Get Started',
                    onAction: () async => true,
                    successMessage: '',
                    failMessage: '',
                    nextRoute: '/login',
                    navigationType: NavigationType.push,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
