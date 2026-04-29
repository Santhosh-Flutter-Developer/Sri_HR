import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/auth/login/widgets/branding_panel.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:sri_hr/widgets/form_fields.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  RxBool showPass = false.obs;
  final auth = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  List<dynamic> get fields => [
    {
      "label": "Email or Username",
      "controller": emailCtrl,
      "type": "text",
      "keyboardType": TextInputType.emailAddress,
      "prefixIcon": Icons.email_outlined,
      "validator": (v) {
        if (v == null || v.isEmpty) {
          return 'Email is required';
        }
        // else if (!isValidEmail(v)) {
        //   return 'Enter Valid Email';
        // }
        return null;
      },
      "obscureText": false,
      "suffixIcon": null,
      "onSuffixTap": null,
      "topPadding": 20.0,
      "xl": 12,
      "lg": 12,
      "md": 12,
      "sm": 12,
      "xs": 12,
    },
    {
      "label": "Password",
      "controller": passCtrl,
      "type": "text",
      "keyboardType": TextInputType.text,
      "prefixIcon": Icons.lock_outline,
      "validator": (val) => val.isEmpty ? "password is required" : null,
      "obscureText": showPass.value,
      "suffixIcon": showPass.value
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
      "onSuffixTap": togglePassword,
      "topPadding": 16.0,
      "xl": 12,
      "lg": 12,
      "md": 12,
      "sm": 12,
      "xs": 12,
    },
    {
      "label": "Sign In",
      "onPressed": submit,
      "type": "button",
      "isLoading": auth.isLoading.value,
      "isFullWidth": true,
      "topPadding": 32.0,
      "bottomPadding": 20.0,
      "xl": 12,
      "lg": 12,
      "md": 12,
      "sm": 12,
      "xs": 12,
    },
  ];

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  void onClose() {
    super.onClose();
    emailCtrl.dispose();
    passCtrl.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;
    auth.login(emailCtrl.text.trim(), passCtrl.text.trim());
  }

  void togglePassword() => showPass.toggle();

  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: loginForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget narrowLayout() {
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
          Padding(padding: const EdgeInsets.all(24), child: loginForm()),
        ],
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to your Sri HR account',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          // const SizedBox(height: 36),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8.0),
              ResponsiveGridRow(
                children: [
                  ...List.generate(fields.length, (index) {
                    return ResponsiveGridCol(
                      xl: fields[index]["xl"] ?? 12,
                      lg: fields[index]["lg"] ?? 12,
                      md: fields[index]["md"] ?? 12,
                      xs: fields[index]["xs"] ?? 12,
                      sm: fields[index]["sm"] ?? 12,
                      child: Obx(
                        () => FormFields(
                          label: fields[index]["label"] ?? "",
                          type: fields[index]["type"] ?? "",
                          textEditingController: fields[index]["controller"],
                          obscureText: fields[index]["obscureText"],
                          prefixIcon: fields[index]["prefixIcon"],
                          suffixIcon: fields[index]["suffixIcon"],
                          onSuffixTap: fields[index]["onSuffixTap"],
                          validator: fields[index]["validator"],
                          keyboardType: fields[index]["keyboardType"],
                          onPressed: fields[index]["onPressed"],
                          isLoading: fields[index]["isLoading"],
                          isFullWidth: fields[index]["isFullWidth"],
                          topPadding: fields[index]["topPadding"],
                          bottomPadding: fields[index]["bottomPadding"],
                          rightPadding: fields[index]["rightPadding"],
                          leftPadding: fields[index]["leftPadding"],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.routeSignup),
                    child: const Text(
                      'Register Company',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
