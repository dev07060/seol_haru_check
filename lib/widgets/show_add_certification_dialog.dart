import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/widgets/full_screen_loading.dart';

const _primaryColor = Color(0xFF004DF8);
const _neutralColor = Colors.grey;

// 인증 추가 다이얼로그 표시
Future<bool?> showAddCertificationDialog(User user, BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder:
        (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: AddCertificationForm(user: user),
        ),
  );
}

// 인증 추가 폼 위젯
class AddCertificationForm extends StatefulWidget {
  final User user;
  const AddCertificationForm({super.key, required this.user});

  @override
  _AddCertificationFormState createState() => _AddCertificationFormState();
}

class _AddCertificationFormState extends State<AddCertificationForm> {
  String _selectedType = '운동';
  final _contentController = TextEditingController();
  final _passwordController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _contentController.dispose();
    _passwordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 이미지 선택 및 압축
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final compressed = await FlutterImageCompress.compressWithFile(
        picked.path,
        minHeight: 800,
        minWidth: 800,
        quality: 85,
      );
      if (compressed != null) {
        setState(() {
          _selectedImageBytes = compressed;
        });
      }
    }
  }

  // 인증 제출
  Future<void> _submitCertification() async {
    if (_isUploading) return;
    if (_contentController.text.trim().isEmpty || _selectedImageBytes == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용, 이미지, 비밀번호를 모두 입력해주세요')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 사용자 비밀번호 확인
      final userQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .where('uuid', isEqualTo: widget.user.uuid)
              .limit(1)
              .get();

      if (userQuery.docs.isEmpty || userQuery.docs.first.data()['password'] != _passwordController.text) {
        setState(() => _isUploading = false);
        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('비밀번호 오류'),
                content: const Text('비밀번호가 올바르지 않습니다.'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('확인'))],
              ),
        );
        return;
      }

      // 이미지 업로드
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd').format(now);
      final filename = '${widget.user.uuid}_$formattedDate.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('certifications/$filename');
      final uploadTask = await storageRef.putData(_selectedImageBytes!);
      final gsPath = uploadTask.ref.fullPath;
      final bucket = FirebaseStorage.instance.bucket;
      final gsUrl = 'gs://$bucket/$gsPath';

      // Firestore에 인증 데이터 저장
      await FirebaseFirestore.instance.collection('certifications').add({
        'uuid': widget.user.uuid,
        'nickname': widget.user.name,
        'createdAt': now,
        'type': _selectedType,
        'content': _contentController.text.trim(),
        'photoUrl': gsUrl,
      });

      setState(() => _isUploading = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 중 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('인증 추가하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                ToggleButtons(
                  isSelected: [_selectedType == '운동', _selectedType == '식단'],
                  onPressed: (index) {
                    setState(() => _selectedType = index == 0 ? '운동' : '식단');
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: _primaryColor,
                  color: _primaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
                  children: const [Text('운동'), Text('식단')],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(labelText: '내용', border: OutlineInputBorder()),
                  maxLines: 2,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      // 입력 처리 (필요 시 추가 로직)
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder()),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_selectedImageBytes == null ? '이미지 선택' : '이미지 변경'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    if (_selectedImageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_selectedImageBytes!, height: 120, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _neutralColor.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _submitCertification,
                      child: const Text('제출'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isUploading) const FFullScreenLoading(),
      ],
    );
  }
}
