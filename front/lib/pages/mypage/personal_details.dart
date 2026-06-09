import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/constants/colors.dart';
import 'package:front/services/auth_service.dart';
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

  /// 서버 birth(yyyy-MM-dd) 원본을 저장해두고, 저장 시 그대로 다시 전송
  String? _serverBirthIso;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 프로필 API 호출 → 값이 있으면 폼에 채우고, 없으면 공백 유지
  Future<void> _loadProfile() async {
    try {
      final data = await AuthService.fetchProfile();
      if (!mounted) return;

      setState(() {
        user = data;

        // 성별: 서버 값을 그대로 사용 (male/female)
        if (data.gender == 'male' || data.gender == 'female') {
          gender = data.gender;
        }

        // 생년월일: 서버 yyyy-MM-dd → 화면 DD/MM/YYYY
        _serverBirthIso = data.birth;
        _dateController.text = _isoToDisplay(data.birth);

        // 전화번호: 서버 000-0000-0000 → 화면 숫자만
        final phoneDigits = _stripPhone(data.phone);
        // 한국번호('010'...)인지로 국가 자동 선택
        if (phoneDigits.startsWith('010')) {
          selectedPhoneCountry = phoneCountries.firstWhere(
            (c) => c.name == 'KR',
            orElse: () => phoneCountries.first,
          );
        } else if (phoneDigits.startsWith('04')) {
          selectedPhoneCountry = phoneCountries.firstWhere(
            (c) => c.name == 'AU',
            orElse: () => phoneCountries.first,
          );
        }
        _phoneController.text = phoneDigits;

        // 위치: 서버 address(=location) 값이 드롭다운 옵션과 일치하면 선택
        const supportedLocations = {
          'Melbourne, Australia',
          'Sydney, Australia',
          'Canberra, Australia',
        };
        if (data.location != null &&
            supportedLocations.contains(data.location)) {
          country = data.location;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필 조회 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 'yyyy-MM-dd' → 'DD/MM/YYYY'
  String _isoToDisplay(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parts = iso.split('-');
    if (parts.length != 3) return '';
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  /// 'DD/MM/YYYY' → 'yyyy-MM-dd'
  String? _displayToIso(String display) {
    if (display.isEmpty) return null;
    final parts = display.split('/');
    if (parts.length != 3) return null;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  /// 서버 phone 문자열에서 숫자만 추출
  String _stripPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// 숫자만 입력된 phone 을 백엔드 정규식(0\d{1,2}-\d{3,4}-\d{4})에 맞게 포맷
  /// - 11자리: AAA-BBBB-CCCC (예: 010-1234-5678)
  /// - 10자리: AAA-BBB-CCCC  (예: 041-234-5678)
  /// - 9자리 : AA-BBB-CCCC   (예: 02-123-4567)
  /// 그 외는 null 반환 (보내지 않음)
  String? _formatPhoneForApi(String digits) {
    if (digits.isEmpty) return null;
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    if (digits.length == 9) {
      return '${digits.substring(0, 2)}-${digits.substring(2, 5)}-${digits.substring(5)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: green),
                    )
                  : Form(
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
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text('Male'),
                                ),
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
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _dateController,
                                    readOnly: true,
                                    onTap: () async {
                                      // 기존 입력값이 있으면 그걸 초기값으로
                                      DateTime selectedDate =
                                          _parseDisplayDate(
                                                _dateController.text,
                                              ) ??
                                              DateTime(2000);
                                      await showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) {
                                          return Container(
                                            height: 300,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(20),
                                                  ),
                                            ),
                                            child: Column(
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _dateController.text =
                                                            '${selectedDate.day.toString().padLeft(2, '0')}/'
                                                            '${selectedDate.month.toString().padLeft(2, '0')}/'
                                                            '${selectedDate.year}';
                                                        _serverBirthIso =
                                                            '${selectedDate.year}-'
                                                            '${selectedDate.month.toString().padLeft(2, '0')}-'
                                                            '${selectedDate.day.toString().padLeft(2, '0')}';
                                                      });
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'Done',
                                                      style: TextStyle(
                                                        color: green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: CupertinoDatePicker(
                                                    initialDateTime:
                                                        selectedDate,
                                                    mode:
                                                        CupertinoDatePickerMode
                                                            .date,
                                                    onDateTimeChanged:
                                                        (DateTime newDate) {
                                                          selectedDate =
                                                              newDate;
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
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'DD/MM/YYYY',
                                      hintStyle: const TextStyle(
                                        color: grey02,
                                        fontSize: 12.5,
                                      ),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                        16,
                                        24,
                                        16,
                                        24,
                                      ),

                                      // 우측 아이콘
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 19,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/icons/calendar.svg',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                      suffixIconConstraints:
                                          const BoxConstraints(
                                            minWidth: 0,
                                            minHeight: 0,
                                          ),

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
                                const Text(
                                  'Phone',
                                  style: TextStyle(
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
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      /// 국가 드롭다운 (왼쪽)
                                      Expanded(
                                        flex: 2,
                                        child:
                                            DropdownButtonFormField<
                                              CountryPhone
                                            >(
                                              value: selectedPhoneCountry,
                                              items: phoneCountries
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Center(
                                                        child: Text(
                                                          countryFlags[c
                                                                  .name] ??
                                                              c.name,
                                                          style:
                                                              const TextStyle(
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
                                              // 드롭다운 화살표 아이콘 설정
                                              icon: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                child: SvgPicture.asset(
                                                  'assets/icons/arrow_down.svg',
                                                  width: 8,
                                                  height: 8,
                                                  color: grey02,
                                                ),
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 20,
                                                  right: 20,
                                                ),
                                              ),
                                            ),
                                      ),

                                      /// 폰 번호 입력 (오른쪽)
                                      Expanded(
                                        flex: 7,
                                        child: TextFormField(
                                          controller: _phoneController,
                                          cursorColor: grey03,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                            color: dark,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: selectedPhoneCountry.hint,
                                            hintStyle: const TextStyle(
                                              color: grey02,
                                              fontSize: 14,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 24,
                                                ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
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
                              isLoading: _isSaving,
                              successMessage: 'Success to Save',
                              failMessage: '',
                              nextRoute: '',
                              onAction: _onSavePressed,
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

  /// 'DD/MM/YYYY' → DateTime (실패 시 null)
  DateTime? _parseDisplayDate(String display) {
    if (display.isEmpty) return null;
    final parts = display.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Save 버튼 액션: 백엔드 PATCH /profile 호출
  Future<bool> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return false;
    if (_isSaving) return false;

    final birthIso = _serverBirthIso ?? _displayToIso(_dateController.text);
    final phoneFormatted = _formatPhoneForApi(_phoneController.text.trim());

    // 전화번호를 입력했는데 형식이 맞지 않으면 안내 후 중단
    if (_phoneController.text.trim().isNotEmpty && phoneFormatted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호 자릿수를 확인해주세요 (9~11자리 숫자).')),
      );
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await AuthService.updateProfile(
        birth: birthIso,
        phone: phoneFormatted,
        gender: gender,
        address: country,
        // accountInfo: 이 화면에서는 입력 받지 않으므로 전달하지 않음
      );
      user = updated;

      if (!mounted) return true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));

      Navigator.pop(context);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
                  color: Colors.black.withOpacity(0.03),
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
                  color: grey02,
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
