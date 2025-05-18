import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';

void showAddCertificationDialog(User user, BuildContext context) {
  String selectedType = '운동';
  final contentController = TextEditingController();
  File? selectedImage;

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) {
      return StatefulBuilder(
        builder:
            (context, setState) => Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
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
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() {
                                selectedImage = File(picked.path);
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('이미지 선택'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black,
                          ),
                        ),
                        if (selectedImage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(selectedImage!, height: 120, fit: BoxFit.cover),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                debugPrint('제출됨: $selectedType / ${contentController.text}');
                                Navigator.pop(context);
                              },
                              child: const Text('제출'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      );
    },
  );
}
