import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:get/get.dart';

import '../shared Widgets/CustomButtons.dart';
import '../shared Widgets/CustomTextField.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final authCtrl = Get.find<AuthController>();
    final isWide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 440 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 32 : 24),
            child: Container(
              padding: isWide ? const EdgeInsets.all(28) : EdgeInsets.zero,
              decoration: isWide
                  ? BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_reset_outlined,
                    size: isWide ? 52 : 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter your email address and we\'ll send you a password reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWide ? 13.5 : 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  CustomTextField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  Obx(() => CustomButton(
                        text: 'Send Reset Link',
                        isLoading: authCtrl.isLoading.value,
                        icon: Icons.send_outlined,
                        onPressed: () {
                          if (emailCtrl.text.isNotEmpty) {
                            authCtrl.resetPassword(emailCtrl.text.trim());
                          }
                        },
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
