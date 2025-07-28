import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias FirebaseAuth
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/shared/components/f_bottom_sheet.dart';
import 'package:seol_haru_check/shared/components/f_dialog.dart';
import 'package:seol_haru_check/shared/components/f_solid_button.dart';
import 'package:seol_haru_check/shared/components/f_tab.dart';
import 'package:seol_haru_check/shared/components/f_text_field.dart';
import 'package:seol_haru_check/shared/components/f_toast.dart';
import 'package:seol_haru_check/widgets/full_screen_loading.dart';

Future<bool?> showAddCertificationBottomSheet({
  required User user,
  required BuildContext context,
  required Function onSuccess,
}) {
  return FBottomSheet.showWithHandler(
    context,
    contentBuilder: (isExpanded) => _AddCertificationContent(user: user),
    bottomBuilder: (context) => _AddCertificationBottomButton(user: user, onSuccess: onSuccess),
    initialHeight: 0.65,
    enableDrag: false,
  ).then((value) => value as bool?);
}

class _AddCertificationContent extends StatefulWidget {
  final User user;

  const _AddCertificationContent({required this.user});

  @override
  State<_AddCertificationContent> createState() => _AddCertificationContentState();
}

class _AddCertificationContentState extends State<_AddCertificationContent> {
  static CertificationType selectedType = CertificationType.exercise;
  static final contentController = TextEditingController();
  static final passwordController = TextEditingController();
  static Uint8List? selectedImageBytes;
  static bool isUploading = false;

  @override
  void dispose() {
    contentController.clear();
    passwordController.clear();
    selectedImageBytes = null; // 이미지 선택 초기화
    super.dispose();
  }

  List<String> get types => CertificationType.displayNames;
  // 이미지 압축 함수
  Future<Uint8List?> compressImage(Uint8List imageBytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 800,
        minWidth: 600,
        quality: 70, // 0-100, 낮을수록 더 압축됨
        format: CompressFormat.jpeg,
      );

      log('Original size: ${imageBytes.length} bytes');
      log('Compressed size: ${compressedBytes.length} bytes');
      log('Compression ratio: ${(compressedBytes.length / imageBytes.length * 100).toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      log('Image compression failed: $e');
      return imageBytes; // 압축 실패시 원본 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                AppStrings.addCertification,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              const Text(
                AppStrings.uploadLimit,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              FTab.capsuleTab(
                currentIndex: CertificationType.values.indexOf(selectedType),
                tabList: types,
                size: CapsuleTapSize.small,
                onChangedTap: (index) {
                  setState(() => selectedType = CertificationType.values[index]);
                },
              ),
              const Gap(8),
              FTextField(controller: contentController, hintText: AppStrings.contentHint, maxLines: 3),

              const Gap(8),
              FSolidButton.assistive(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    final bytes = await picked.readAsBytes();
                    // 이미지 압축 적용
                    final compressedBytes = await compressImage(bytes);
                    setState(() {
                      selectedImageBytes = compressedBytes;
                    });
                  }
                },
                size: FSolidButtonSize.small,
                text: selectedImageBytes == null ? AppStrings.selectImage : AppStrings.changeImage,
              ),

              if (selectedImageBytes != null) ...[
                const Gap(8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(selectedImageBytes!, height: 400, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              const Gap(8),
              // FTextField(controller: passwordController, hintText: '비밀번호(6자리)', maxLength: 6, obscureText: true),
              // const Gap(8),
            ],
          ),
        ),
        if (isUploading) const Positioned.fill(child: FFullScreenLoading()),
      ],
    );
  }
}

class _AddCertificationBottomButton extends StatefulWidget {
  final User user;

  const _AddCertificationBottomButton({required this.user, required this.onSuccess});
  final Function onSuccess;

  @override
  State<_AddCertificationBottomButton> createState() => _AddCertificationBottomButtonState();
}

class _AddCertificationBottomButtonState extends State<_AddCertificationBottomButton> {
  // 이미지 압축 함수
  Future<Uint8List?> compressImage(Uint8List imageBytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 800,
        minWidth: 600,
        quality: 70, // 0-100, 낮을수록 더 압축됨
        format: CompressFormat.jpeg,
      );

      log('Original size: ${imageBytes.length} bytes');
      log('Compressed size: ${compressedBytes.length} bytes');
      log('Compression ratio: ${(compressedBytes.length / imageBytes.length * 100).toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      log('Image compression failed: $e');
      return imageBytes; // 압축 실패시 원본 반환
    }
  }

  // 하루 업로드 개수 확인 함수
  Future<int> getTodayUploadCount(String userUuid) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query =
        await FirebaseFirestore.instance
            .collection(AppStrings.certificationsCollection)
            .where(AppStrings.uuidField, isEqualTo: userUuid)
            .where(AppStrings.createdAtField, isGreaterThanOrEqualTo: startOfDay)
            .where(AppStrings.createdAtField, isLessThan: endOfDay)
            .get();

    return query.docs.length;
  }

  Future<void> _handleSubmit() async {
    if (_AddCertificationContentState.isUploading) return;
    if (_AddCertificationContentState.contentController.text.trim().isEmpty ||
        _AddCertificationContentState.selectedImageBytes == null) {
      FToast(message: AppStrings.fillAllFields).show(context);
      return;
    }

    setState(() {
      _AddCertificationContentState.isUploading = true;
    });

    try {
      // 하루 업로드 제한 확인
      final todayCount = await getTodayUploadCount(widget.user.uuid);
      if (todayCount >= 3) {
        setState(() {
          _AddCertificationContentState.isUploading = false;
        });
        await showDialog(
          context: context,
          builder:
              (context) => FDialog.oneButton(
                title: AppStrings.uploadLimit2,
                confirmText: AppStrings.confirm,
                onConfirm: () => Navigator.pop(context),
              ),
        );
        return;
      }

      // 현재 로그인한 사용자의 UUID와 위젯의 user.uuid가 일치하는지 확인
      final currentFbUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (currentFbUser == null || currentFbUser.uid != widget.user.uuid) {
        setState(() {
          _AddCertificationContentState.isUploading = false;
        });
        FToast(message: AppStrings.authError).show(context);
        return;
      }

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd').format(now);
      final timestamp = DateFormat('HHmmss').format(now);
      // 고유한 파일명 생성 (날짜 + 시간 + 카운트)
      final filename = '${widget.user.uuid}_${formattedDate}_${timestamp}_${todayCount + 1}.jpg';

      final storageRef = FirebaseStorage.instance.ref().child('certifications/$filename');
      final uploadTask = await storageRef.putData(_AddCertificationContentState.selectedImageBytes!);
      final gsPath = uploadTask.ref.fullPath;
      final bucket = FirebaseStorage.instance.bucket;
      final gsUrl = 'gs://$bucket/$gsPath';

      await FirebaseFirestore.instance.collection(AppStrings.certificationsCollection).add({
        AppStrings.uuidField: widget.user.uuid,
        AppStrings.nicknameField: widget.user.name,
        AppStrings.createdAtField: now,
        AppStrings.typeField: _AddCertificationContentState.selectedType.displayName,
        AppStrings.contentField: _AddCertificationContentState.contentController.text.trim(),
        AppStrings.photoUrlField: gsUrl,
      });

      setState(() {
        _AddCertificationContentState.isUploading = false;
      });
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _AddCertificationContentState.isUploading = false;
      });
      debugPrint('업로드 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('업로드 중 오류 발생: $e')));
    }

    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FSolidButton.primary(onPressed: _handleSubmit, text: AppStrings.submit, size: FSolidButtonSize.medium),
    );
  }
}
