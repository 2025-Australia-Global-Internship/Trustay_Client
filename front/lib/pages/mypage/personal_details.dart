import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:front/widgets/common_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CountryPhone {
  final String name;
  final String hint;

  CountryPhone({required this.name, required this.hint});
}

final List<CountryPhone> phoneCountries = [
  CountryPhone(name: '🇰🇷 KR', hint: '010 XXXX XXXX'),
  CountryPhone(name: '🇦🇺 AU', hint: '04XX XXX XXX'),
];

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPage();
}

class _PersonalDetailsPage extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? gender;
  String? country;
  CountryPhone selectedPhoneCountry = phoneCountries.first;

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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      /// Gender
                      CommonDropdown<String>(
                        label: 'Gender',
                        value: gender,
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) => setState(() => gender = v),
                      ),

                      const SizedBox(height: 16),

                      /// Date of Birth
                      CommonTextField(
                        label: 'Date of Birth',
                        hintText: 'DD/MM/YYYY',
                        readOnly: true,
                        controller: _dateController,
                        suffixIcon: SvgPicture.asset(
                          'assets/icons/calendar.svg',
                          width: 25,
                          height: 25,
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            locale: const Locale('en', 'AU'),
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

                      /// Location
                      CommonDropdown<String>(
                        label: 'Location',
                        value: country,
                        prefixIcon: SvgPicture.asset(
                          'assets/icons/pin.svg',
                          width: 25,
                          height: 25,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Melbourne, Australia',
                            child: Text('Melbourne, Australia'),
                          ),
                          DropdownMenuItem(
                            value: 'Sydney, Australia',
                            child: Text('Sydney, Australia'),
                          ),
                          DropdownMenuItem(
                            value: 'Canberra, Australia',
                            child: Text('Canberra, Australia'),
                          ),
                        ],
                        onChanged: (v) => setState(() => country = v),
                      ),

                      const SizedBox(height: 16),

                      /// Phone (Country + Number)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 공통 라벨
                          const Text(
                            'Phone',
                            style: TextStyle(
                              color: dark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: grey02),
                            ),
                            child: Row(
                              children: [
                                /// 국가 드롭다운
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsetsGeometry.only(
                                      right: 10,
                                    ),
                                    child:
                                        DropdownButtonFormField<CountryPhone>(
                                          value: selectedPhoneCountry,
                                          items: phoneCountries
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Text(c.name),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            setState(() {
                                              selectedPhoneCountry = v!;
                                              _phoneController.clear();
                                            });
                                          },
                                          icon: SizedBox(
                                            width: 19,
                                            height: 19,
                                            child: Center(
                                              child: SvgPicture.asset(
                                                'assets/icons/arrow_down.svg',
                                                width: 16,
                                                height: 16,
                                              ),
                                            ),
                                          ),
                                          iconSize: 0,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 18,
                                                  vertical: 18,
                                                ),
                                          ),
                                        ),
                                  ),
                                ),

                                /// 폰 번호 입력
                                Expanded(
                                  flex: 7,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: selectedPhoneCountry.hint,
                                      hintStyle: const TextStyle(
                                        color: grey01,
                                        fontSize: 15,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 18,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      /// Save Button
                      PrimaryButton(
                        formKey: _formKey,
                        text: 'Save',
                        isLoading: false,
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
