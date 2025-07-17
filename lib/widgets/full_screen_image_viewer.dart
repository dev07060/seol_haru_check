import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String content;

  const FullScreenImageViewer({super.key, required this.imageUrl, required this.content});

  static PageRouteBuilder createRoute(String imageUrl, String content) {
    return PageRouteBuilder(
      opaque: false,
      pageBuilder:
          (context, animation, secondaryAnimation) => FullScreenImageViewer(imageUrl: imageUrl, content: content),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .8),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: FirebaseStorageImage(
                  imagePath: imageUrl,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            if (content.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: .8)],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                      child: Text(content, style: FTextStyles.bodyM.copyWith(color: Colors.white, height: 1.5)),
                    ),
                  ),
                ),
              ),
            Positioned(top: 40, right: 16, child: CloseButton(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
