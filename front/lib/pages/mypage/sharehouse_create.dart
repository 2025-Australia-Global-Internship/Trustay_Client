import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/widgets/common_text_field.dart';
import 'package:intl/intl.dart';
import 'package:front/widgets/common_dropdown.dart';

// 천의 자리 , 표시
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final plainText = newValue.text.replaceAll(',', '');
    final number = int.tryParse(plainText);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SharehouseCreatePage extends StatefulWidget {
  const SharehouseCreatePage({super.key});

  @override
  State<SharehouseCreatePage> createState() => _SharehouseCreatePageState();
}

class _SharehouseCreatePageState extends State<SharehouseCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // 매물 유형
  String? houseType;

  // 상세 정보
  String address = '';
  String fee = '';
  String roomCount = '';
  String bathroomCount = '';
  String residentCount = '';

  // 옵션
  bool smokingAllowed = false;
  bool petAllowed = false;
  String genderLimit = '무관';
  String ageLimit = '무관';
  String religionDiet = '';

  // 설명
  String description = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('쉐어하우스 등록')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHouseType(),
              _buildDetailInfo(),
              _buildOptions(),
              _buildDescription(),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 매물 유형
  Widget _buildHouseType() {
    return CommonDropdown<String>(
      label: '매물 유형',
      value: houseType,
      items: const [
        DropdownMenuItem(value: '아파트', child: Text('아파트')),
        DropdownMenuItem(value: '단독주택', child: Text('단독주택')),
        DropdownMenuItem(value: '원룸', child: Text('원룸')),
        DropdownMenuItem(value: '기타', child: Text('기타')),
      ],
      onChanged: (v) => setState(() => houseType = v),
      onSaved: (v) => houseType = v,
      validator: (v) => v == null ? '매물 유형을 선택하세요' : null,
    );
  }

  // 상세 정보
  Widget _buildDetailInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          '상세 정보',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        CommonTextField(
          label: '주소 및 위치',
          onSaved: (v) => address = v!,
          validator: (v) => v!.isEmpty ? '주소를 입력하세요' : null,
        ),

        CommonTextField(
          label: '쉐어비',
          suffixText: '원',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter(),
          ],
          onSaved: (v) {
            fee = v!.replaceAll(',', ''); // 저장은 숫자만
          },
          validator: (v) => v!.isEmpty ? '쉐어비를 입력하세요' : null,
        ),

        CommonTextField(
          label: '방 개수',
          keyboardType: TextInputType.number,
          onSaved: (v) => roomCount = v!,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? '방 개수를 입력하세요' : null,
        ),

        CommonTextField(
          label: '화장실 개수',
          keyboardType: TextInputType.number,
          onSaved: (v) => bathroomCount = v!,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? '개수를 입력하세요' : null,
        ),

        CommonTextField(
          label: '현 거주 인원',
          keyboardType: TextInputType.number,
          onSaved: (v) => residentCount = v!,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? '거주 인원을 입력하세요' : null,
        ),
      ],
    );
  }

  // 옵션
  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          '옵션',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        SwitchListTile(
          title: const Text('흡연 가능'),
          value: smokingAllowed,
          onChanged: (v) => setState(() => smokingAllowed = v),
        ),

        SwitchListTile(
          title: const Text('반려동물 가능'),
          value: petAllowed,
          onChanged: (v) => setState(() => petAllowed = v),
        ),

        CommonDropdown<String>(
          label: '성별',
          value: genderLimit,
          items: const [
            DropdownMenuItem(value: '무관', child: Text('무관')),
            DropdownMenuItem(value: '여성 전용', child: Text('여성 전용')),
            DropdownMenuItem(value: '남성 전용', child: Text('남성 전용')),
          ],
          onChanged: (v) => setState(() => genderLimit = v!),
          onSaved: (v) => genderLimit = v!,
        ),

        CommonDropdown<String>(
          label: '나이 제한',
          value: ageLimit,
          items: const [
            DropdownMenuItem(value: '무관', child: Text('무관')),
            DropdownMenuItem(
              value: '미성년자 불가 (19세 이상)',
              child: Text('미성년자 불가 (19세 이상)'),
            ),
          ],
          onChanged: (v) => setState(() => ageLimit = v!),
          onSaved: (v) => ageLimit = v!,
        ),

        CommonTextField(
          label: '종교 / 식성 (선택)',
          onSaved: (v) => religionDiet = v ?? '',
        ),
      ],
    );
  }

  // 세부 사항
  Widget _buildDescription() {
    return Column(
      children: [
        const SizedBox(height: 24),
        CommonTextField(
          label: '상세 설명',
          maxLines: 5,
          onSaved: (v) => description = v ?? '',
        ),
      ],
    );
  }

  // 등록 버튼
  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('쉐어하우스 등록 완료')));

              // API 요청 보내기
            }
          },
          child: const Text('쉐어하우스 등록'),
        ),
      ),
    );
  }
}
