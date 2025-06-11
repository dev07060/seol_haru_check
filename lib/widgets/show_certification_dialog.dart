import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';
import 'package:seol_haru_check/widgets/show_add_certification_dialog.dart';

void showCertificationDialog(
  User user,
  List<Map<String, dynamic>> certifications,
  BuildContext context, {
  VoidCallback? onDeleted,
  VoidCallback? onUpdated,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) {
      final CarouselSliderController controller = CarouselSliderController();

      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            height: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF004DF8), size: 28),
                      tooltip: '추가 인증',
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await showAddCertificationBottomSheet(
                          user: user,
                          context: context,
                          onSuccess: onUpdated!,
                        );
                        if (result == true) onUpdated();
                      },
                    ),

                    Text('${user.name}님의 인증 기록', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: CarouselSlider(
                    carouselController: controller,
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 0.9,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: true,
                      scrollDirection: Axis.horizontal,
                    ),
                    items:
                        certifications.map((cert) {
                          final photoUrl = cert['photoUrl'] ?? '';
                          final type = cert['type'] ?? '';
                          final content = cert['content'] ?? '';
                          final docId = cert['docId'];

                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (photoUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: SizedBox(
                                          height: 180,
                                          width: double.infinity,
                                          child: FirebaseStorageImage(imagePath: photoUrl),
                                        ),
                                      ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (type.isNotEmpty)
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '유형: $type',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                                    onPressed: () async {
                                                      final passwordController = TextEditingController();
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder:
                                                            (ctx) => AlertDialog(
                                                              title: const Text('인증 삭제'),
                                                              content: TextField(
                                                                controller: passwordController,
                                                                decoration: const InputDecoration(labelText: '비밀번호'),
                                                                obscureText: true,
                                                                keyboardType: TextInputType.number,
                                                                maxLength: 6,
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(ctx, false),
                                                                  child: const Text('취소'),
                                                                ),
                                                                ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: const Color(0xFF004DF8),
                                                                    foregroundColor: Colors.white,
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(8),
                                                                    ),
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
                                                                        snapshot.docs.first.data()['password'] ==
                                                                            password) {
                                                                      await FirebaseFirestore.instance
                                                                          .collection('certifications')
                                                                          .doc(docId)
                                                                          .delete();
                                                                      Navigator.pop(ctx);
                                                                      Navigator.pop(context);
                                                                      onDeleted?.call();
                                                                    } else {
                                                                      Navigator.pop(ctx);
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text('비밀번호가 일치하지 않습니다'),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  child: const Text('삭제'),
                                                                ),
                                                              ],
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 4),
                                            if (content.isNotEmpty)
                                              Expanded(
                                                child: Text(
                                                  content,
                                                  style: const TextStyle(fontSize: 14),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
