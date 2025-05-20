import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/widgets/full_screen_loading.dart';

Future<bool?> showAddCertificationDialog(User user, BuildContext context) {
  String selectedType = '운동';
  final contentController = TextEditingController();
  final passwordController = TextEditingController();
  Uint8List? selectedImageBytes;
  bool isUploading = false;

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    width: 320,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('인증 추가하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 16),
                          ToggleButtons(
                            isSelected: [selectedType == '운동', selectedType == '식단'],
                            onPressed: (index) {
                              setState(() => selectedType = index == 0 ? '운동' : '식단');
                            },
                            borderRadius: BorderRadius.circular(8),
                            selectedColor: Colors.white,
                            fillColor: const Color(0xFF004DF8),
                            color: const Color(0xFF004DF8),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
                            children: const [Text('운동'), Text('식단')],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: contentController,
                            decoration: const InputDecoration(labelText: '내용', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder()),
                            obscureText: true,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setState(() {
                                      selectedImageBytes = bytes;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.image),
                                label: Text(selectedImageBytes == null ? '이미지 선택' : '이미지 변경'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004DF8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                              if (selectedImageBytes != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(selectedImageBytes!, height: 120, fit: BoxFit.cover),
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
                                  foregroundColor: Colors.grey.shade700,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF004DF8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                onPressed: () async {
                                  if (isUploading) return;
                                  if (contentController.text.trim().isEmpty ||
                                      selectedImageBytes == null ||
                                      passwordController.text.isEmpty) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(const SnackBar(content: Text('내용, 이미지, 비밀번호를 모두 입력해주세요')));
                                    return;
                                  }
                                  setState(() => isUploading = true);

                                  try {
                                    // Fetch user document by querying for uuid field (not by doc id)
                                    final userQuery =
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .where('uuid', isEqualTo: user.uuid)
                                            .limit(1)
                                            .get();
                                    if (userQuery.docs.isEmpty ||
                                        userQuery.docs.first.data()['password'] != passwordController.text) {
                                      log(
                                        'password: ${userQuery.docs.isNotEmpty ? userQuery.docs.first.data() : null}',
                                      );

                                      setState(() => isUploading = false);
                                      await showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text('비밀번호 오류'),
                                              content: const Text('비밀번호가 올바르지 않습니다.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('확인'),
                                                ),
                                              ],
                                            ),
                                      );
                                      return;
                                    }

                                    final now = DateTime.now();
                                    final formattedDate = DateFormat('yyyyMMdd').format(now);
                                    final filename = '${user.uuid}_$formattedDate.jpg';

                                    final storageRef = FirebaseStorage.instance.ref().child('certifications/$filename');
                                    final uploadTask = await storageRef.putData(selectedImageBytes!);
                                    final gsPath = uploadTask.ref.fullPath;
                                    final bucket = FirebaseStorage.instance.bucket;
                                    final gsUrl = 'gs://$bucket/$gsPath';

                                    await FirebaseFirestore.instance.collection('certifications').add({
                                      'uuid': user.uuid,
                                      'nickname': user.name,
                                      'createdAt': now,
                                      'type': selectedType,
                                      'content': contentController.text.trim(),
                                      'photoUrl': gsUrl,
                                    });

                                    setState(() => isUploading = false);
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    setState(() => isUploading = false);
                                    debugPrint('업로드 실패: $e');
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(SnackBar(content: Text('업로드 중 오류 발생: $e')));
                                  }
                                },
                                child: const Text('제출'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isUploading) Positioned.fill(child: const FFullScreenLoading()),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
