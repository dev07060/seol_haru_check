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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '${_emailController.text.trim()}@seolharu.check',
        password: _passwordController.text.trim(),
      );
      // 로그인이 성공하면 라우터가 알아서 홈으로 보냅니다.
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: ${e.message}')));
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
                controller: _emailController,
                hintText: '닉네임을 입력해 주세요.',
                textInputType: TextInputType.emailAddress,
              ),
              const Gap(16),
              FTextField(controller: _passwordController, hintText: AppStrings.password4digits, obscureText: true),
              const Gap(24),
              FSolidButton.primary(text: '로그인', onPressed: _signIn),
            ],
          ),
        ),
      ),
    );
  }
}
