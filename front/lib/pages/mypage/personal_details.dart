import 'package:flutter/material.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPage();
}

class _PersonalDetailsPage extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientLayout(
        child: Column(
          children: [
            CustomHeader(showBack: true),
            const SizedBox(height: 16),

            Expanded(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 드롭다운
                      CommonTextField(label: 'Gender'),
                      const SizedBox(height: 16),

                      CommonTextField(
                        label: 'Date of Birth',
                        hintText: 'DD/MM/YYYY',
                        readOnly: true,
                        controller: _dateController,
                        suffixIcon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 24,
                          color: green,
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            locale: const Locale('en', 'AU'), // 🇦🇺 호주 로케일
                          );

                          if (picked != null) {
                            _dateController.text =
                                '${picked.day.toString().padLeft(2, '0')}/'
                                '${picked.month.toString().padLeft(2, '0')}/'
                                '${picked.year}';
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // 로케이션
                      CommonTextField(label: 'Phone'),
                      const SizedBox(height: 16),

                      // 폰 넘버 (앞에 국가 선택)
                      CommonTextField(label: 'Email'),

                      const Spacer(),

                      PrimaryButton(
                        formKey: _formKey,
                        text: 'Save',
                        isLoading: false, // 임시
                        successMessage: '저장 되었습니다.(임시)',
                        failMessage: '',
                        nextRoute: null,
                        onAction: () async => true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
