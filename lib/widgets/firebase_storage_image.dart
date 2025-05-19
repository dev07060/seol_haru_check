import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FirebaseStorageImage extends StatelessWidget {
  final String imagePath;

  const FirebaseStorageImage({super.key, required this.imagePath});
  String _createFirebaseUrl(String path) {
    // gs:// 버킷 주소 제거
    const prefix = 'gs://seol-haru-check.firebasestorage.app/';
    String cleanPath = path.startsWith(prefix) ? path.replaceFirst(prefix, '') : path;
    final encodedPath = Uri.encodeComponent(cleanPath);
    return 'https://firebasestorage.googleapis.com/v0/b/seol-haru-check.firebasestorage.app/o/$encodedPath?alt=media';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _createFirebaseUrl(imagePath);
    log('Firebase Storage Image URL: $imageUrl');
    return AspectRatio(
      aspectRatio: 1, // 1:1 비율 강제
      child: ClipRRect(
        // 이미지가 비율을 벗어나지 않도록 자름
        child: CachedNetworkImage(
          fit: BoxFit.cover, // fill 대신 cover 사용하여 비율 유지하면서 채우기
          imageUrl: imageUrl,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator.adaptive()),
          errorWidget:
              (context, url, error) => Center(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('이미지를 불러올 수 없어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
