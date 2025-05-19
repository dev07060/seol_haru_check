import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';

void showCertificationDialog(
  User user,
  Map<String, dynamic> certification,
  String docId,
  BuildContext context, {
  VoidCallback? onDeleted,
  VoidCallback? onUpdated,
}) {
  final String photoUrl = certification['photoUrl'] ?? '';
  final String type = certification['type'] ?? '';
  final String content = certification['content'] ?? '';

  // 디버깅용 로그 추가
  debugPrint('ShowCertificationDialog - PhotoUrl: $photoUrl');

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${user.name}님의 인증 내용', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FirebaseStorageImage(imagePath: photoUrl),
                      ),
                    const SizedBox(height: 12),
                    if (type.isNotEmpty)
                      Text('유형: $type', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (content.isNotEmpty) Text('내용: $content', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004DF8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final passwordController = TextEditingController();

                        await showDialog<bool>(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('인증 삭제'),
                                content: TextField(
                                  controller: passwordController,
                                  decoration: const InputDecoration(labelText: '비밀번호'),
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                ),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('취소'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF004DF8),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    onPressed: () async {
                                      final password = passwordController.text.trim();
                                      final snapshot =
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .where('uuid', isEqualTo: user.uuid)
                                              .limit(1)
                                              .get();

                                      if (snapshot.docs.isNotEmpty &&
                                          snapshot.docs.first.data()['password'] == password) {
                                        await FirebaseFirestore.instance
                                            .collection('certifications')
                                            .doc(docId)
                                            .delete();

                                        Navigator.pop(ctx, true); // 비밀번호 창 닫기
                                        Navigator.pop(context); // 인증 보기 창 닫기
                                        onDeleted?.call(); // 콜백 실행

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(const SnackBar(content: Text('인증이 삭제되었습니다')));
                                      } else {
                                        Navigator.pop(ctx, false);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(const SnackBar(content: Text('비밀번호가 일치하지 않습니다')));
                                      }
                                    },
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
