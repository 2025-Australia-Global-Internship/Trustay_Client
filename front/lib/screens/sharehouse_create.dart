import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: '매물 유형'),
      items: const [
        DropdownMenuItem(value: '1인실', child: Text('1인실')),
        DropdownMenuItem(value: '2인실', child: Text('2인실')),
        DropdownMenuItem(value: '3인실', child: Text('3인실')),
        DropdownMenuItem(value: '4인실', child: Text('4인실')),
        DropdownMenuItem(value: '기타', child: Text('기타')),
      ],
      onChanged: (value) => houseType = value,
      validator: (value) => value == null ? '매물 유형을 선택하세요' : null,
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

        TextFormField(
          decoration: const InputDecoration(labelText: '주소 및 위치'),
          onSaved: (v) => address = v!,
          validator: (v) => v!.isEmpty ? '주소를 입력하세요' : null,
        ),

        TextFormField(
          decoration: const InputDecoration(labelText: '쉐어비', suffixText: '원'),
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

        TextFormField(
          decoration: const InputDecoration(labelText: '방 개수'),
          keyboardType: TextInputType.number,
          onSaved: (v) => roomCount = v!,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? '방 개수를 입력하세요' : null,
        ),

        TextFormField(
          decoration: const InputDecoration(labelText: '화장실 개수'),
          keyboardType: TextInputType.number,
          onSaved: (v) => bathroomCount = v!,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v!.isEmpty ? '개수를 입력하세요' : null,
        ),

        TextFormField(
          decoration: const InputDecoration(labelText: '현 거주 인원'),
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

        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: '성별'),
          initialValue: genderLimit,
          items: const [
            DropdownMenuItem(value: '무관', child: Text('무관')),
            DropdownMenuItem(value: '여성 전용', child: Text('여성 전용')),
            DropdownMenuItem(value: '남성 전용', child: Text('남성 전용')),
          ],
          onChanged: (v) => setState(() => genderLimit = v!),
          onSaved: (v) => genderLimit = v!,
        ),

        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: '나이 제한'),
          initialValue: ageLimit,
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

        TextFormField(
          decoration: const InputDecoration(labelText: '종교 / 식성 (선택)'),
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
        TextFormField(
          decoration: const InputDecoration(
            labelText: '상세 설명',
            alignLabelWithHint: true,
          ),
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
