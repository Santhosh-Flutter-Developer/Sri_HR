import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/forgot_password/controller/forgot_password_controller.dart';
import 'package:sri_hr/presentation/auth/login/widgets/branding_panel.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

class ForgotPassword extends GetView<ForgotPasswordController> {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.sidebarBg,
        statusBarIconBrightness: Brightness.light,
      ),
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: AppColors.bg,
          body: isWide ? _wideLayout(context) : _narrowLayout(context),
        ),
      ),
    );
  }

  // ── Wide (tablet / desktop) ───────────────────────────────
  Widget _wideLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: BrandingPanel(),
          ),
        ),
        Container(
          width: 480,
          color: AppColors.surface,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: _pageContent(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Narrow (mobile) ───────────────────────────────────────
  Widget _narrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 380,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: BrandingPanel(),
          ),
          Padding(padding: const EdgeInsets.all(20), child: _pageContent()),
        ],
      ),
    );
  }

  // ── Main content (switches per step) ─────────────────────
  Widget _pageContent() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Step progress bar ───────────────────────────
          _StepProgress(currentStep: controller.step.value),
          const SizedBox(height: 28),

          // ── Animated step switcher ──────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(controller.step.value),
              child: switch (controller.step.value) {
                0 => _StepIdentifier(controller: controller),
                1 => _StepOtp(controller: controller),
                2 => _StepNewPassword(controller: controller),
                _ => const SizedBox.shrink(),
              },
            ),
          ),

          // ── Back to login ───────────────────────────────
          if (controller.step.value == 0) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Remember your password? ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Step progress indicator (3 dots)
// ─────────────────────────────────────────────────────────────
class _StepProgress extends StatelessWidget {
  final int currentStep;
  const _StepProgress({required this.currentStep});

  static const _labels = ['Identify', 'Verify OTP', 'New Password'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? AppColors.primary
                        : isDone
                        ? AppColors.success
                        : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 0 — Email / Username input
// ─────────────────────────────────────────────────────────────
class _StepIdentifier extends StatelessWidget {
  final ForgotPasswordController controller;
  const _StepIdentifier({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.identifierFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Enter your email or username to receive an OTP',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SriTextField(
            controller: controller.identifierCtrl,
            label: 'Email or Username *',
            prefixIcon: Icons.person_search_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateIdentifier,
          ),
          const SizedBox(height: 8),
          const Text(
            'An OTP will be sent to the mobile number linked to your account.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          Obx(
            () => SriButton(
              label: 'Send OTP',
              isFullWidth: true,
              isLoading: controller.isLoading.value,
              onPressed: controller.lookupUser,
              icon: Icons.send_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 1 — OTP verification (same Pinput style as signup)
// ─────────────────────────────────────────────────────────────
class _StepOtp extends StatelessWidget {
  final ForgotPasswordController controller;
  const _StepOtp({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sms_rounded,
                  color: AppColors.accentGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'OTP sent to ${controller.maskedPhone.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // OTP info box (same style as signup)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text(
                  'Enter the 6-digit OTP sent to your mobile',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Pinput — exact same theme as signup
                Pinput(
                  controller: controller.otpCtrl,
                  length: 6,
                  defaultPinTheme: PinTheme(
                    width: 48,
                    height: 52,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.surfaceVariant,
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 48,
                    height: 52,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.surfaceVariant,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 6) {
                      return 'Enter the 6-digit OTP';
                    }
                    return null;
                  },
                  onCompleted: (_) => controller.verifyOtp(),
                ),
                const SizedBox(height: 16),

                // Verify button
                Obx(
                  () => SriButton(
                    label: 'Verify OTP',
                    isFullWidth: true,
                    isLoading: controller.isLoading.value,
                    onPressed: controller.verifyOtp,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resend row
          Obx(() {
            if (controller.canResend.value) {
              return Center(
                child: TextButton.icon(
                  onPressed: controller.resendOtp,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                'Resend OTP in ${controller.resendSeconds.value}s',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Back button
          TextButton(
            onPressed: controller.goBack,
            child: const Text(
              '← Change email / username',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 2 — New password
// ─────────────────────────────────────────────────────────────
class _StepNewPassword extends StatelessWidget {
  final ForgotPasswordController controller;
  const _StepNewPassword({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.accentGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set New Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Identity verified. Create a strong password.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
    
          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 16),
                SizedBox(width: 6),
                Text(
                  'Mobile number verified successfully',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
    
          // Password requirements hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: const Text(
              '• At least 8 characters\n'
              '• One uppercase & one lowercase letter\n'
              '• One number & one special character\n'
              '• No spaces',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 20),
    
          // New password field
          Obx(
            () => SriTextField(
              controller: controller.newPasswordCtrl,
              label: 'New Password *',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !controller.showNewPass.value,
              suffixIcon: controller.showNewPass.value
                  ? Icons.visibility_off
                  : Icons.visibility,
              onSuffixTap: () => controller.showNewPass.toggle(),
              validator: controller.validatePassword,
            ),
          ),
          const SizedBox(height: 16),
    
          // Confirm password field
          Obx(
            () => SriTextField(
              controller: controller.confirmPasswordCtrl,
              label: 'Confirm New Password *',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: !controller.showConfirmPass.value,
              suffixIcon: controller.showConfirmPass.value
                  ? Icons.visibility_off
                  : Icons.visibility,
              onSuffixTap: () => controller.showConfirmPass.toggle(),
              validator: controller.validateConfirmPassword,
            ),
          ),
          const SizedBox(height: 24),
    
          Obx(
            () => SriButton(
              label: 'Update Password',
              isFullWidth: true,
              isLoading: controller.isLoading.value,
              onPressed: controller.updatePassword,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
