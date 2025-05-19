import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart'; // 이 부분을 추가해주세요.
import 'package:seol_haru_check/widgets/full_screen_loading.dart';

Future<bool?> showEditCertificationDialog(User user, Map<String, dynamic> certification, BuildContext context) {
  String selectedType = certification['type'] ?? '운동';
  final contentController = TextEditingController(text: certification['content'] ?? '');
  final passwordController = TextEditingController();
  Uint8List? selectedImageBytes;
  bool isUploading = false;
  String? currentPhotoUrl = certification['photoUrl'];

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
                          const Text('인증 수정하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 16),
                          ToggleButtons(
                            isSelected: [selectedType == '운동', selectedType == '식단'],
                            onPressed: (index) {
                              setState(() => selectedType = index == 0 ? '운동' : '식단');
                            },
                            borderRadius: BorderRadius.circular(12),
                            selectedColor: Colors.white,
                            fillColor: Colors.blue,
                            color: Colors.blue,
                            constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
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
                                      currentPhotoUrl = null; // 새로운 이미지 선택 시 기존 이미지 URL 제거
                                    });
                                  }
                                },
                                icon: const Icon(Icons.image),
                                label: Text(selectedImageBytes == null ? '이미지 선택' : '이미지 변경'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black,
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
                              if (currentPhotoUrl != null && selectedImageBytes == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FirebaseStorageImage(imagePath: currentPhotoUrl!),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  if (isUploading) return;
                                  if (contentController.text.trim().isEmpty ||
                                      (selectedImageBytes == null && currentPhotoUrl == null) ||
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

                                    String? newPhotoUrl = currentPhotoUrl;
                                    if (selectedImageBytes != null) {
                                      // 이전 이미지가 있다면 삭제 (선택 사항)
                                      // if (currentPhotoUrl != null) {
                                      //   try {
                                      //     await FirebaseStorage.instance.refFromURL(currentPhotoUrl!).delete();
                                      //   } catch (e) {
                                      //     debugPrint('Failed to delete old image: $e');
                                      //   }
                                      // }
                                      final now = DateTime.now();
                                      final formattedDate = DateFormat(
                                        'yyyyMMdd_HHmmss',
                                      ).format(now); // 파일명 중복 방지를 위해 시간 추가
                                      final filename = '${user.uuid}_$formattedDate.jpg';

                                      final storageRef = FirebaseStorage.instance.ref().child(
                                        'certifications/$filename',
                                      );
                                      final uploadTask = await storageRef.putData(selectedImageBytes!);
                                      final gsPath = uploadTask.ref.fullPath;
                                      final bucket = FirebaseStorage.instance.bucket;
                                      newPhotoUrl = 'gs://$bucket/$gsPath';
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('certifications')
                                        .doc(certification['id'])
                                        .update({
                                          'type': selectedType,
                                          'content': contentController.text.trim(),
                                          'photoUrl': newPhotoUrl,
                                        });

                                    setState(() => isUploading = false);
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    setState(() => isUploading = false);
                                    debugPrint('수정 실패: $e');
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(SnackBar(content: Text('수정 중 오류 발생: $e')));
                                  }
                                },
                                child: const Text('완료'),
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
