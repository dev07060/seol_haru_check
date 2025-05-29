import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/shared/components/f_scaffold.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';

class UserDetailPage extends StatefulWidget {
  final String uuid;
  const UserDetailPage({required this.uuid, super.key});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  List<Map<String, dynamic>> certifications = [];
  bool isLoading = true;
  String nickname = '';

  @override
  void initState() {
    super.initState();
    fetchCertifications();
  }

  Future<void> fetchCertifications() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('certifications')
            .where('uuid', isEqualTo: widget.uuid)
            .orderBy('createdAt', descending: true)
            .get();

    if (snapshot.docs.isNotEmpty) {
      nickname = snapshot.docs.first.data()['nickname'] ?? '';
    }

    setState(() {
      certifications =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['docId'] = doc.id;
            return data;
          }).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      appBar: AppBar(
        title: Text('$nickname의 히스토리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/');
          },
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : ListView.builder(
                itemCount: certifications.length,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                itemBuilder: (_, index) {
                  final cert = certifications[index];
                  final date = (cert['createdAt'] as Timestamp).toDate();
                  final photoUrl = cert['photoUrl'] ?? '';
                  final type = cert['type'] ?? '';
                  final content = cert['content'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (photoUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: FirebaseStorageImage(imagePath: photoUrl),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd (E)', 'ko').format(date),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text('유형: $type', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              if (content.isNotEmpty) Text(content, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
