import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/services/sms_service.dart';
import 'package:sri_hr/data/utils/otp_generator.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/auth/login/widgets/branding_panel.dart';
import 'package:sri_hr/presentation/auth/signup/widgets/step_indicator.dart';
import 'package:sri_hr/presentation/auth/signup/widgets/step_title.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_card.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

class SignupController extends GetxController {
  final signupformKey = GlobalKey<FormState>();
  final auth = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final compName = TextEditingController();
  final personName = TextEditingController();
  final gstIn = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final country = TextEditingController();
  final state = TextEditingController();
  final city = TextEditingController();
  final pincode = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final otp = TextEditingController();
  String otpCode = '';
  late String _activeOtp;
  // RxInt _resendSeconds = 60.obs;
  // RxInt _resendCount = 0.obs;
  // RxBool _canResend = false.obs;
  Timer? _timer;

  RxBool showPass = false.obs;
  RxBool showConfirmPass = false.obs;
  RxBool otpSent = false.obs;
  RxBool otpVerified = false.obs;
  RxBool sendingOtp = false.obs;
  RxInt step = 0.obs; // 0=company, 1=personal, 2=account

  final steps = ["Company", "Personal", "Account"];

  @override
  void onClose() {
    super.onClose();
    _timer?.cancel();
    signupformKey.currentState?.dispose();
    for (final c in [
      compName,
      personName,
      gstIn,
      mobile,
      email,
      address,
      country,
      state,
      city,
      pincode,
      password,
      confirmPassword,
      otp,
    ]) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
    signupformKey.currentState?.dispose();
    for (final c in [
      compName,
      personName,
      gstIn,
      mobile,
      email,
      address,
      country,
      state,
      city,
      pincode,
      password,
      confirmPassword,
      otp,
    ]) {
      c.dispose();
    }
  }

  Future<void> sendOtp() async {
    final phone = mobile.text.trim();

    if (phone.length != 10) {
      Get.snackbar(
        'Error',
        'Enter valid 10-digit mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    try {
      sendingOtp.value = true;

      // await Supabase.instance.client.auth.signInWithOtp(
      //   phone: '+91$phone', // India country code
      // );

      otpCode = OtpGenerator.generate();
      final mobileWithCode = '91$phone';

      final sent = await SmsService.sendOtp(
        mobileNumber: mobileWithCode,
        otp: otpCode,
        appName: 'Srisoft',
      );

      sendingOtp.value = false;
      otpSent.value = true;

      Get.snackbar(
        'OTP Sent',
        'OTP sent to +91$phone',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      _activeOtp = otpCode;
      // _startCountdown();
    } catch (e) {
      sendingOtp.value = false;

      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // void _startCountdown() {
  //   _resendSeconds.value = 60;
  //   _canResend.value = false;
  //   _timer?.cancel();
  //   _timer = Timer.periodic(const Duration(seconds: 1), (t) {
  //     if (_resendSeconds.value <= 1) {
  //       t.cancel();
  //       _canResend.value = true;
  //     } else {
  //       _resendSeconds.value--;
  //     }
  //   });
  // }

  // Future<void> _resendOtp() async {
  //   if (_resendCount.value >= 3) {
  //     Get.snackbar(
  //       'Warning',
  //       "Maximum resend limit reached. Please try again later.",
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: AppColors.warning,
  //       colorText: Colors.white,
  //     );
  //   }
  //   final newOtp = OtpGenerator.generate();
  //   final sent = await SmsService.sendOtp(
  //     mobileNumber: '91${mobile.text.toString()}',
  //     otp: newOtp,
  //     appName: 'Srisoft',
  //   );
  //   if (sent) {
  //     _activeOtp = newOtp;
  //     _resendCount.value++;
  //     pincode.clear();
  //     _startCountdown();
  //     Get.snackbar(
  //       'Success',
  //       "OTP resent successfully",
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: AppColors.success,
  //       colorText: Colors.white,
  //     );
  //   } else {
  //     Get.snackbar(
  //       'Error',
  //       "Failed to resend OTP",
  //       snackPosition: SnackPosition.BOTTOM,
  //       backgroundColor: AppColors.error,
  //       colorText: Colors.white,
  //     );
  //   }
  // }

  /*Future<void> sendOtp() async {
    if (mobile.text.length != 10) {
      Get.snackbar(
        'Error',
        'Enter a valid 10-digit mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }
    sendingOtp.value = true;
    await Future.delayed(const Duration(seconds: 1));
    sendingOtp.value = false;
    otpSent.value = true;

    Get.snackbar(
      'OTP Sent',
      'OTP sent to ${mobile.text} (use 123456 for demo)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }*/

  Future<void> verifyOtp() async {
    final phone = mobile.text.trim();
    final otpcode = otp.text.trim();

    if (otpcode.length != 6) {
      Get.snackbar(
        'Error',
        'Enter valid 6-digit OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // final response = await Supabase.instance.client.auth.verifyOTP(
      //   phone: '+91$phone',
      //   token: otpcode,
      //   type: OtpType.sms,
      // );

      if (otpcode == _activeOtp) {
        _timer?.cancel();
        otpVerified.value = true;

        Get.snackbar(
          'Success',
          'Mobile number verified!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        pincode.clear();
        Get.snackbar(
          'ERROR',
          'Incorrect OTP. Please try again',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Invalid OTP',
        'Verification failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  /*void verifyOtp() {
    if (otp.text == "123456") {
      otpVerified.value = true;
      Get.snackbar(
        'Verified',
        'Mobile number verified!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the correct OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }*/

  void submit() {
    if (!signupformKey.currentState!.validate()) return;
    if (!otpVerified.value) {
      Get.snackbar(
        'OTP Required',
        'Please verify your mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }
    auth.register(
      companyName: compName.text.trim(),
      personName: personName.text.trim(),
      gstin: gstIn.text.trim(),
      mobile: mobile.text.trim(),
      email: email.text.trim(),
      address: address.text.trim(),
      country: country.text.trim(),
      state: state.text.trim(),
      city: city.text.trim(),
      pincode: pincode.text.trim(),
      password: password.text.trim(),
    );
  }

  Widget wideLayout() {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: signupForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget narrowLayout() {
    return signupForm();
  }

  Widget signupForm() {
    return Obx(
      () => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (Get.mediaQuery.size.width <= 800)
                const SizedBox(height: 20.0),
              StepIndicator(currentStep: step.value, steps: steps),
              const SizedBox(height: 32.0),
              SriCard(
                child: Form(
                  key: signupformKey,
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: KeyedSubtree(
                          key: ValueKey(step.value),
                          child: buildStep(step.value),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Row(
                        children: [
                          if (step.value > 0)
                            Expanded(
                              child: SriButton(
                                onPressed: () => step.value--,
                                label: 'Back',
                                isOutlined: true,
                              ),
                            ),
                          if (step.value > 0) const SizedBox(width: 12),
                          Expanded(
                            child: Obx(
                              () => ElevatedButton(
                                onPressed: auth.isLoading.value
                                    ? null
                                    : () {
                                        if (step.value < steps.length - 1) {
                                          if (!signupformKey.currentState!
                                              .validate()) {
                                            return;
                                          }
                                          if (step.value == 1 &&
                                              !otpVerified.value) {
                                            Get.snackbar(
                                              'OTP Required',
                                              'Please verify your mobile number',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              margin: EdgeInsets.all(10.0),
                                              backgroundColor:
                                                  AppColors.warning,
                                              colorText: Colors.white,
                                            );
                                            return;
                                          }

                                          step.value++;
                                        } else {
                                          submit();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: auth.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Padding(
                                        padding:
                                            Get.mediaQuery.size.width >= 800
                                            ? EdgeInsets.symmetric(
                                                vertical: 8.0,
                                              )
                                            : EdgeInsets.symmetric(
                                                vertical: 4.0,
                                              ),
                                        child: Text(
                                          step.value < steps.length - 1
                                              ? 'Next'
                                              : 'Create Account',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStep(int step) {
    return switch (step) {
      0 => stepCompany(),
      1 => stepPersonal(),
      2 => stepAccount(),
      _ => const SizedBox(),
    };
  }

  Widget stepCompany() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StepTitle(title: 'Company Information', icon: Icons.business_rounded),
      const SizedBox(height: 20),
      SriTextField(
        controller: compName,
        label: 'Company Name *',
        prefixIcon: Icons.business_rounded,
        validator: (v) => v?.isEmpty == true ? 'Company Name Required' : null,
      ),
      const SizedBox(height: 16),
      SriTextField(
        controller: gstIn,
        label: 'GSTIN',
        prefixIcon: Icons.numbers_rounded,
        hint: 'GST Identification Number',
      ),
    ],
  );

  Widget stepPersonal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StepTitle(title: 'Person Details', icon: Icons.person_rounded),
      const SizedBox(height: 20),
      SriTextField(
        controller: personName,
        label: 'Full Name *',
        prefixIcon: Icons.person_outline,
        validator: (v) => v?.isEmpty == true ? 'Person Name Required' : null,
      ),
      const SizedBox(height: 16),
      // Mobile + OTP
      Row(
        children: [
          Expanded(
            child: SriTextField(
              controller: mobile,
              label: 'Mobile Number *',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v?.isEmpty == true) return 'Mobile Number is Required';
                if (v!.length != 10) return 'Enter 10 digits';
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: sendingOtp.value ? null : sendOtp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: sendingOtp.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Padding(
                    padding: Get.mediaQuery.size.width >= 800
                        ? EdgeInsets.symmetric(vertical: 6.0)
                        : EdgeInsets.symmetric(vertical: 0.0),
                    child: Text(otpSent.value ? 'Resend' : 'Send OTP'),
                  ),
          ),
        ],
      ),
      if (otpSent.value && !otpVerified.value) ...[
        const SizedBox(height: 16),
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
                'Enter OTP sent to your mobile',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Pinput(
                controller: otp,
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
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Verify OTP'),
              ),
            ],
          ),
        ),
       
      ],
      if (otpVerified.value) ...[
        const SizedBox(height: 12),
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
                'Mobile verified',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      SriTextField(
        controller: email,
        label: 'Email Address *',
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v?.isEmpty == true) return 'Email is Required';
          if (!GetUtils.isEmail(v!)) return 'Invalid email';
          return null;
        },
      ),
      const SizedBox(height: 20),
      StepTitle(title: 'Address Details', icon: Icons.location_on_rounded),
      const SizedBox(height: 20),
      SriTextField(
        controller: address,
        label: 'Full Address *',
        maxLines: 3,
        prefixIcon: Icons.home_rounded,
        validator: (v) =>
            v?.isEmpty == true ? 'Full Address is Required' : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: SriTextField(
              controller: country,
              label: 'Country',
              prefixIcon: Icons.flag_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SriTextField(
              controller: state,
              label: 'State',
              prefixIcon: Icons.map_rounded,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: SriTextField(
              controller: city,
              label: 'City',
              prefixIcon: Icons.location_city_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SriTextField(
              controller: pincode,
              label: 'Pincode',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.pin_drop_rounded,
            ),
          ),
        ],
      ),
    ],
  );

  // Widget stepAddress() => Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //     StepTitle(title: 'Address Details', icon: Icons.location_on_rounded),
  //     const SizedBox(height: 20),
  //     SriTextField(
  //       controller: address,
  //       label: 'Full Address *',
  //       maxLines: 3,
  //       prefixIcon: Icons.home_rounded,
  //       validator: (v) => v?.isEmpty == true ? 'Required' : null,
  //     ),
  //     const SizedBox(height: 16),
  //     Row(
  //       children: [
  //         Expanded(
  //           child: SriTextField(
  //             controller: country,
  //             label: 'Country',
  //             prefixIcon: Icons.flag_rounded,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: SriTextField(
  //             controller: state,
  //             label: 'State',
  //             prefixIcon: Icons.map_rounded,
  //           ),
  //         ),
  //       ],
  //     ),
  //     const SizedBox(height: 16),
  //     Row(
  //       children: [
  //         Expanded(
  //           child: SriTextField(
  //             controller: city,
  //             label: 'City',
  //             prefixIcon: Icons.location_city_rounded,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: SriTextField(
  //             controller: pincode,
  //             label: 'Pincode',
  //             keyboardType: TextInputType.number,
  //             prefixIcon: Icons.pin_drop_rounded,
  //           ),
  //         ),
  //       ],
  //     ),
  //   ],
  // );

  Widget stepAccount() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StepTitle(title: 'Account Setup', icon: Icons.lock_rounded),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: const Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Text(
                  'Trial Plan – Free for 3 days',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Includes all features • Max 3 users • No credit card required',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SriTextField(
        controller: password,
        label: 'Password *',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: !showPass.value,
        onSuffixTap: () => showPass.value = !showPass.value,
        suffixIcon: showPass.value ? Icons.visibility_off : Icons.visibility,

        validator: (v) {
          if (v?.isEmpty == true) return 'Password is required';
          if (v!.length < 6) return 'Min 6 characters';
          return null;
        },
      ),
      const SizedBox(height: 16),
      SriTextField(
        controller: confirmPassword,
        label: 'Confirm Password *',
        prefixIcon: Icons.lock_outline_rounded,
        obscureText: !showConfirmPass.value,
        onSuffixTap: () => showConfirmPass.value = !showConfirmPass.value,
        suffixIcon: showConfirmPass.value
            ? Icons.visibility_off
            : Icons.visibility,
        validator: (v) {
          if (v?.isEmpty == true) return 'Confirm password is required';
          if (v != password.text) return 'Passwords do not match';
          return null;
        },
      ),
    ],
  );
}
