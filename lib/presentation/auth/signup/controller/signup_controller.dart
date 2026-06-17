import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/services/sms_service.dart';
import 'package:sri_hr/data/services/supabase_service.dart';
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
  Timer? _timer;

  // ── Debounce timers ─────────────────────────────────────
  Timer? _compNameDebounce;
  Timer? _gstinDebounce;
  Timer? _mobileDebounce;
  Timer? _emailDebounce;

  // ── Checking spinners ────────────────────────────────────
  RxBool isCheckingCompName = false.obs;
  RxBool isCheckingGstin = false.obs;
  RxBool isCheckingMobile = false.obs;
  RxBool isChecking = false.obs; // email spinner (kept for compat)

  // ── Field-level error messages ───────────────────────────
  RxString compNameError = ''.obs;
  RxString gstinError = ''.obs;
  RxString mobileError = ''.obs;
  RxString emailError = ''.obs;

  // ── UI state ─────────────────────────────────────────────
  RxBool showPass = false.obs;
  RxBool showConfirmPass = false.obs;
  RxBool otpSent = false.obs;
  RxBool otpVerified = false.obs;
  RxBool sendingOtp = false.obs;
  RxInt step = 0.obs; // 0=company, 1=personal, 2=account

  final steps = ['Company', 'Personal', 'Account'];

  // ── Regex helpers ─────────────────────────────────────────
  static final _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
  static final _gstinRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  bool isValidEmail(String v) => _emailRegex.hasMatch(v.trim());

  // ────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ────────────────────────────────────────────────────────

  @override
  void onClose() {
    _cancelTimers();
    _disposeControllers();
    super.onClose();
  }

  @override
  void dispose() {
    _cancelTimers();
    _disposeControllers();
    super.dispose();
  }

  void _cancelTimers() {
    _timer?.cancel();
    _compNameDebounce?.cancel();
    _gstinDebounce?.cancel();
    _mobileDebounce?.cancel();
    _emailDebounce?.cancel();
  }

  void _disposeControllers() {
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

  // ────────────────────────────────────────────────────────
  //  GLOBAL UNIQUENESS CHECKS  (hit Supabase directly)
  // ────────────────────────────────────────────────────────

  /// Returns true when [name] already exists in the `organizations` table
  /// (global check — signup creates a new org, so no excludeId needed).
  Future<bool> isCompanyNameExists(String name) async {
    try {
      final rows = await SupabaseService.client
          .from('organizations')
          .select('id')
          .ilike('name', name.trim())
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (e) {
      debugPrint('[SignupCtrl] isCompanyNameExists ERROR: $e');
      return false;
    }
  }

  /// Returns true when [gstin] already exists in ANY company globally.
  Future<bool> isGstinExists(String gstin) async {
    try {
      final result = await SupabaseService.client.rpc(
        'check_gstin_globally_exists',
        params: {
          'p_gstin': gstin.trim().toUpperCase(),
          'p_exclude_company_id': null,
        },
      );
      return result as bool;
    } catch (e) {
      debugPrint('[SignupCtrl] isGstinExists ERROR: $e');
      return false;
    }
  }

  /// Returns true when [mobileNo] exists in ANY company OR any employee globally.
  Future<bool> isMobileExists(String mobileNo) async {
    try {
      final result = await SupabaseService.client.rpc(
        'check_phone_globally_exists',
        params: {
          'p_phone': mobileNo.trim(),
          'p_exclude_company_id': null,
          'p_exclude_employee_id': null,
        },
      );
      return result as bool;
    } catch (e) {
      debugPrint('[SignupCtrl] isMobileExists ERROR: $e');
      return false;
    }
  }

  /// Returns true when [emailAddr] exists in ANY company OR any employee globally.
  Future<bool> isEmailExists(
    String emailAddr, {
    String? excludeEmployeeId,
  }) async {
    try {
      final result = await SupabaseService.client.rpc(
        'check_email_globally_exists',
        params: {
          'p_email': emailAddr.trim().toLowerCase(),
          'p_exclude_company_id': null,
          'p_exclude_employee_id': excludeEmployeeId,
        },
      );
      return result as bool;
    } catch (e) {
      debugPrint('[SignupCtrl] isEmailExists ERROR: $e');
      return false;
    }
  }

  // Kept for AuthController compat
  Future<bool> isLoginEmailExists(
    String emailAddr, {
    String? excludeEmployeeId,
  }) async => isEmailExists(emailAddr, excludeEmployeeId: excludeEmployeeId);

  // ────────────────────────────────────────────────────────
  //  DEBOUNCE HANDLERS — Step 0 (Company)
  // ────────────────────────────────────────────────────────

  void onCompNameChanged(String value) {
    _compNameDebounce?.cancel();
    if (value.trim().isEmpty) {
      compNameError.value = '';
      isCheckingCompName.value = false;
      return;
    }
    isCheckingCompName.value = true;
    compNameError.value = '';
    _compNameDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await isCompanyNameExists(value.trim());
      isCheckingCompName.value = false;
      compNameError.value = exists
          ? 'This company name is already registered'
          : '';
    });
  }

  void onGstinChanged(String value) {
    _gstinDebounce?.cancel();
    if (value.trim().isEmpty) {
      gstinError.value = '';
      isCheckingGstin.value = false;
      return;
    }

    isCheckingGstin.value = true;
    gstinError.value = '';
    _gstinDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await isGstinExists(value.trim());
      isCheckingGstin.value = false;
      gstinError.value = exists ? 'This GSTIN is already registered' : '';
    });
  }

  // ────────────────────────────────────────────────────────
  //  DEBOUNCE HANDLERS — Step 1 (Personal)
  // ────────────────────────────────────────────────────────

  void onMobileChanged(String value) {
    sendingOtp.value = false;
    otpSent.value = false;
    _mobileDebounce?.cancel();
    if (value.trim().isEmpty) {
      mobileError.value = '';
      isCheckingMobile.value = false;
      return;
    }
    if (value.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      mobileError.value = 'Enter a valid 10-digit mobile number';
      isCheckingMobile.value = false;
      return;
    }
    isCheckingMobile.value = true;
    mobileError.value = '';
    _mobileDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await isMobileExists(value.trim());
      isCheckingMobile.value = false;
      mobileError.value = exists
          ? 'This mobile number is already registered'
          : '';
    });
  }

  void onEmailChanged(String value) {
    _emailDebounce?.cancel();
    if (value.trim().isEmpty) {
      emailError.value = '';
      isChecking.value = false;
      return;
    }
    if (!isValidEmail(value)) {
      emailError.value = 'Enter a valid email address';
      isChecking.value = false;
      return;
    }
    isChecking.value = true;
    emailError.value = '';
    _emailDebounce = Timer(const Duration(milliseconds: 600), () async {
      final exists = await isEmailExists(value.trim());
      isChecking.value = false;
      emailError.value = exists ? 'This email is already registered' : '';
    });
  }

  // ────────────────────────────────────────────────────────
  //  PASSWORD
  // ────────────────────────────────────────────────────────

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password cannot be empty';
    if (value.length < 8) return 'Must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must contain at least one number';
    }
    if (!value.contains(RegExp(r'[^A-Za-z0-9\s]'))) {
      return 'Must contain at least one special character';
    }
    if (value.contains(RegExp(r'\s'))) {
      return 'Password must not contain spaces';
    }
    return null;
  }

  // ────────────────────────────────────────────────────────
  //  OTP
  // ────────────────────────────────────────────────────────

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
      otpCode = OtpGenerator.generate();
      final mobileWithCode = '91$phone';
      await SmsService.sendOtp(
        mobileNumber: mobileWithCode,
        otp: otpCode,
        appName: 'Srisoft',
      );
      sendingOtp.value = false;
      otpSent.value = true;
      Get.snackbar(
        'OTP Sent',
        'A verification code has been sent to +91\$phone. Please check your messages.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      _activeOtp = otpCode;
    } catch (e) {
      sendingOtp.value = false;
      Get.snackbar(
        'Error',
        handleException(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Future<void> verifyOtp() async {
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
      if (otpcode == _activeOtp) {
        _timer?.cancel();
        otpVerified.value = true;
        Get.snackbar(
          'Success',
          'Mobile number verified successfully!',
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
        'Incorrect Verification Code',
        'Verification failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  // ────────────────────────────────────────────────────────
  //  SUBMIT — re-validates all unique fields before sending
  // ────────────────────────────────────────────────────────

  void submit() {
    if (!signupformKey.currentState!.validate()) return;
    if (!otpVerified.value) {
      Get.snackbar(
        'Mobile Verification Required',
        'Please verify your mobile number before continuing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }
    // Block if any inline duplicate error is still showing
    if (compNameError.value.isNotEmpty ||
        gstinError.value.isNotEmpty ||
        mobileError.value.isNotEmpty ||
        emailError.value.isNotEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please fix the highlighted errors before continuing.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
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

  // ────────────────────────────────────────────────────────
  //  LAYOUT
  // ────────────────────────────────────────────────────────

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

  Widget narrowLayout() => signupForm();

  Widget signupForm() {
    return Obx(
      () => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (Get.mediaQuery.size.width <= 800) const SizedBox(height: 20),
              StepIndicator(currentStep: step.value, steps: steps),
              const SizedBox(height: 32),
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
                      const SizedBox(height: 24),
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
                                    : () => _onNextOrSubmit(),
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
                                            ? const EdgeInsets.symmetric(
                                                vertical: 8,
                                              )
                                            : const EdgeInsets.symmetric(
                                                vertical: 4,
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

  void _onNextOrSubmit() {
    if (step.value < steps.length - 1) {
      if (!signupformKey.currentState!.validate()) return;

      // Step 0 → block if company/gstin check is pending or has error
      if (step.value == 0) {
        if (isCheckingCompName.value || isCheckingGstin.value) {
          Get.snackbar(
            'Please wait',
            'Checking field availability…',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.warning,
            colorText: Colors.white,
          );
          return;
        }
        if (compNameError.value.isNotEmpty || gstinError.value.isNotEmpty) {
          return; // validator already shows inline error
        }
      }

      // Step 1 → block if mobile/email check is pending or has error
      if (step.value == 1) {
        if (!otpVerified.value) {
          Get.snackbar(
            'OTP Required',
            'Please verify your mobile number',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(10),
            backgroundColor: AppColors.warning,
            colorText: Colors.white,
          );
          return;
        }
        if (isCheckingMobile.value || isChecking.value) {
          Get.snackbar(
            'Please wait',
            'Checking field availability…',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.warning,
            colorText: Colors.white,
          );
          return;
        }
        if (mobileError.value.isNotEmpty || emailError.value.isNotEmpty) {
          return;
        }
      }

      step.value++;
    } else {
      submit();
    }
  }

  Widget buildStep(int s) => switch (s) {
    0 => stepCompany(),
    1 => stepPersonal(),
    2 => stepAccount(),
    _ => const SizedBox(),
  };

  // ────────────────────────────────────────────────────────
  //  STEP 0 — Company
  // ────────────────────────────────────────────────────────

  Widget stepCompany() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StepTitle(title: 'Company Information', icon: Icons.business_rounded),
      const SizedBox(height: 20),

      // Company Name with global duplicate check
      Obx(
        () => SriTextField(
          controller: compName,
          label: 'Company Name *',
          prefixIcon: Icons.business_rounded,
          errorText: compNameError.value.isNotEmpty
              ? compNameError.value
              : null,
          onChanged: onCompNameChanged,
          suffixIconWidget: isCheckingCompName.value
              ? const _SpinnerIcon()
              : (compNameError.value.isEmpty && compName.text.isNotEmpty)
              ? const _CheckIcon()
              : null,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Company Name is required';
            }
            if (compNameError.value.isNotEmpty) {
              return compNameError.value;
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 16),

      // GSTIN with format + global duplicate check
      Obx(
        () => SriTextField(
          controller: gstIn,
          label: 'GSTIN',
          prefixIcon: Icons.numbers_rounded,
          hint: 'GST Identification Number',
          errorText: gstinError.value.isNotEmpty ? gstinError.value : null,
          onChanged: onGstinChanged,
          suffixIconWidget: isCheckingGstin.value
              ? const _SpinnerIcon()
              : (gstinError.value.isEmpty && gstIn.text.isNotEmpty)
              ? const _CheckIcon()
              : null,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null; // optional
            if (gstinError.value.isNotEmpty) return gstinError.value;
            return null;
          },
        ),
      ),
    ],
  );

  // ────────────────────────────────────────────────────────
  //  STEP 1 — Personal
  // ────────────────────────────────────────────────────────

  Widget stepPersonal() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StepTitle(title: 'Person Details', icon: Icons.person_rounded),
      const SizedBox(height: 20),

      SriTextField(
        controller: personName,
        label: 'Full Name *',
        prefixIcon: Icons.person_outline,
        validator: (v) => v?.toString().trim().isEmpty == true
            ? 'Person Name is required'
            : null,
      ),
      const SizedBox(height: 16),

      // Mobile + OTP row
      Obx(
        () => Row(
          children: [
            Expanded(
              child: SriTextField(
                controller: mobile,
                label: 'Mobile Number *',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                errorText: mobileError.value.isNotEmpty
                    ? mobileError.value
                    : null,
                onChanged: onMobileChanged,
                suffixIconWidget: isCheckingMobile.value
                    ? const _SpinnerIcon()
                    : (mobileError.value.isEmpty && mobile.text.isNotEmpty)
                    ? const _CheckIcon()
                    : null,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Mobile Number is required';
                  }
                  if (v.length != 10) return 'Enter 10 digits';
                  if (mobileError.value.isNotEmpty) {
                    return mobileError.value;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            if (!otpVerified.value &&
                mobileError.value.isEmpty &&
                !isCheckingMobile.value)
              ElevatedButton(
                onPressed: sendingOtp.value ? null : sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
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
                            ? const EdgeInsets.symmetric(vertical: 6)
                            : EdgeInsets.zero,
                        child: Text(otpSent.value ? 'Resend' : 'Send OTP'),
                      ),
              ),
          ],
        ),
      ),

      // OTP entry block
      Obx(() {
        if (otpSent.value &&
            !otpVerified.value &&
            mobileError.value.isEmpty &&
            !isCheckingMobile.value) {
          return Column(
            children: [
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
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
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
          );
        }
        if (otpVerified.value) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 16,
                    ),
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
          );
        }
        return const SizedBox();
      }),
      const SizedBox(height: 16),

      // Email with global duplicate check
      Obx(
        () => SriTextField(
          controller: email,
          label: 'Email Address *',
          prefixIcon: Icons.email_outlined,
          errorText: emailError.value.isNotEmpty ? emailError.value : null,
          keyboardType: TextInputType.emailAddress,
          onChanged: onEmailChanged,
          suffixIconWidget: isChecking.value
              ? const _SpinnerIcon()
              : (emailError.value.isEmpty && email.text.isNotEmpty)
              ? const _CheckIcon()
              : null,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!isValidEmail(v)) return 'Enter a valid email address';
            if (emailError.value.isNotEmpty) return emailError.value;
            return null;
          },
        ),
      ),
      const SizedBox(height: 20),

      StepTitle(title: 'Address Details', icon: Icons.location_on_rounded),
      const SizedBox(height: 20),

      SriTextField(
        controller: address,
        label: 'Full Address *',
        maxLines: 3,
        prefixIcon: Icons.home_rounded,
        validator: (v) => v?.toString().trim().isEmpty == true
            ? 'Full Address is required'
            : null,
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

  // ────────────────────────────────────────────────────────
  //  STEP 2 — Account
  // ────────────────────────────────────────────────────────

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
      Obx(
        () => SriTextField(
          controller: password,
          label: 'Password *',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !showPass.value,
          onSuffixTap: () => showPass.value = !showPass.value,
          suffixIcon: showPass.value ? Icons.visibility_off : Icons.visibility,
          validator: validatePassword,
        ),
      ),
      const SizedBox(height: 16),
      Obx(
        () => SriTextField(
          controller: confirmPassword,
          label: 'Confirm Password *',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: !showConfirmPass.value,
          onSuffixTap: () => showConfirmPass.value = !showConfirmPass.value,
          suffixIcon: showConfirmPass.value
              ? Icons.visibility_off
              : Icons.visibility,
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Confirm password is required';
            }
            if (v != password.text) return 'Passwords do not match';
            return null;
          },
        ),
      ),
    ],
  );
}

// ── Small helper widgets ──────────────────────────────────

class _SpinnerIcon extends StatelessWidget {
  const _SpinnerIcon();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 16,
    height: 16,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon();
  @override
  Widget build(BuildContext context) => const Icon(
    Icons.check_circle_rounded,
    color: AppColors.accentGreen,
    size: 18,
  );
}