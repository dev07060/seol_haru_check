import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/constants/app_strings.dart';

class FirebaseStorageImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double? aspectRatio;

  const FirebaseStorageImage({super.key, required this.imagePath, this.width, this.height, this.fit, this.aspectRatio});
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
    final image = CachedNetworkImage(
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
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
                    child: Text(
                      AppStrings.cannotLoadImage,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (aspectRatio != null) {
      return AspectRatio(aspectRatio: aspectRatio!, child: ClipRRect(child: image));
    }

    return image;
  }
}
