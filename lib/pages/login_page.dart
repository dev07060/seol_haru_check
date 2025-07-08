import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/generated/assets.dart';
import 'package:seol_haru_check/shared/components/f_solid_button.dart';
import 'package:seol_haru_check/shared/components/f_text_field.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '${_nicknameController.text.trim()}@seolharu.check',
        password: '${_passwordController.text.trim()}00',
      );
      // 로그인이 성공하면 라우터가 알아서 홈으로 보냅니다.
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: ${e.message}')));
    }
  }

  Future<void> _signUp() async {
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text.trim();

    if (nickname.isEmpty || password.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임과 4자리 비밀번호를 모두 올바르게 입력해주세요.')));
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: '$nickname@seolharu.check',
        password: '${password}00',
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'nickname': nickname,
          'uuid': userCredential.user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입에 성공했습니다. 자동으로 로그인됩니다.')));
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = '회원가입에 실패했습니다. 다시 시도해주세요.';
      if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 닉네임입니다.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('알 수 없는 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Assets.imageHaruCheckIcon, width: 120, height: 120, fit: BoxFit.cover),
              const Gap(20),
              Text(
                AppStrings.appTitle,
                style: FTextStyles.display2_32.copyWith(
                  color: FColors.of(context).labelNeutral,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(32),
              FTextField(
                controller: _nicknameController,
                hintText: '닉네임을 입력해 주세요.',
                textInputType: TextInputType.emailAddress,
              ),
              const Gap(16),
              FTextField(
                controller: _passwordController,
                hintText: AppStrings.password4digits,
                obscureText: true,
                maxLength: 4,
              ),
              const Gap(24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FSolidButton.primary(text: '로그인', onPressed: _signIn),
                  const Gap(36),
                  FSolidButton.secondary(text: '회원가입(ID 생성시에만)', onPressed: _signUp),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
