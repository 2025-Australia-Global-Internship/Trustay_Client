import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/constants/colors.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:front/widgets/custom_header.dart';
import 'package:front/widgets/gradient_layout.dart';
import 'package:front/widgets/primary_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:front/models/user_model.dart';
import 'package:flutter/cupertino.dart';

class CountryPhone {
  final String name;
  final String hint;

  CountryPhone({required this.name, required this.hint});
}

final List<CountryPhone> phoneCountries = [
  CountryPhone(name: 'KR', hint: '010 XXXX XXXX'),
  CountryPhone(name: 'AU', hint: '04XX XXX XXX'),
];

final Map<String, String> countryFlags = {'KR': '🇰🇷', 'AU': '🇦🇺'};

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPage();
}

class _PersonalDetailsPage extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  User? user;

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
            CustomHeader(
              showBack: true,
              center: const Text(
                'Personal Details',
                style: TextStyle(
                  color: dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Birth',
                            style: TextStyle(
                              color: dark,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 그림자를 위한 컨테이너
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: () async {
                                DateTime selectedDate = DateTime.now();
                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return Container(
                                      height: 300,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () {
                                                _dateController.text =
                                                    '${selectedDate.day.toString().padLeft(2, '0')}/'
                                                    '${selectedDate.month.toString().padLeft(2, '0')}/'
                                                    '${selectedDate.year}';
                                                Navigator.pop(context);
                                              },
                                              child: const Text(
                                                'Done',
                                                style: TextStyle(
                                                  color: green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: CupertinoDatePicker(
                                              initialDateTime: DateTime(2000),
                                              mode:
                                                  CupertinoDatePickerMode.date,
                                              onDateTimeChanged:
                                                  (DateTime newDate) {
                                                    selectedDate = newDate;
                                                  },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              style: const TextStyle(
                                color: dark,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'DD/MM/YYYY',
                                hintStyle: const TextStyle(
                                  color: grey02,
                                  fontSize: 12.5,
                                ),
                                contentPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  22,
                                  16,
                                  22,
                                ),

                                // 우측 아이콘
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: SvgPicture.asset(
                                    'assets/icons/calendar.svg',
                                    width: 22,
                                    height: 22,
                                  ),
                                ),
                                suffixIconConstraints: const BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),

                                // 테두리 없애기 (무테 디자인)
                                filled: true,
                                fillColor: Colors.transparent,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
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
                                      right: 15,
                                    ),
                                    child:
                                        DropdownButtonFormField<CountryPhone>(
                                          value: selectedPhoneCountry,
                                          items: phoneCountries
                                              .map(
                                                (c) => DropdownMenuItem(
                                                  value: c,
                                                  child: Center(
                                                    child: Text(
                                                      countryFlags[c.name] ??
                                                          c.name, // 국기만 보여줌
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
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
                                            contentPadding: EdgeInsets.only(
                                              left: 28,
                                              right: 6,
                                              top: 18,
                                              bottom: 18,
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
                                    cursorColor: grey03,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: dark,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: selectedPhoneCountry.hint,
                                      hintStyle: const TextStyle(
                                        color: grey01,
                                        fontSize: 13,
                                      ),

                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        20,
                                        16,
                                        20,
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
                        successMessage: 'Success to Save',
                        failMessage: '',
                        nextRoute: '',
                        onAction: () async {
                          // 폼 유효성 검사
                          if (!_formKey.currentState!.validate()) return false;

                          // 현재 선택된 Location을 User 객체에 저장
                          user?.location = country ?? "Location";

                          Navigator.pop(context);

                          return true; // 성공 시 true 반환
                        },
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

class CommonDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final void Function(T?)? onSaved;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final String? hintText;

  const CommonDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.onSaved,
    this.validator,
    this.prefixIcon,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<T>(
              value: value,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'NanumSquareNeo',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: dark,
                    ),
                    child: item.child,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              onSaved: onSaved,
              validator: validator,
              icon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SvgPicture.asset(
                  'assets/icons/arrow_down.svg',
                  width: 8,
                  height: 8,
                  color: grey01, // 화살표 색상 명시
                ),
              ),
              style: const TextStyle(
                fontFamily: 'NanumSquareNeo',
                color: dark,
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'NanumSquareNeo',
                  color: grey02,
                  fontSize: 12,
                ),
                prefixIcon: prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 13, 0),
                        child: prefixIcon,
                      )
                    : null,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),

                // 테두리 제거 핵심 부분
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
