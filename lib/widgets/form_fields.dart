import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/widgets/sri_button.dart';
import 'package:sri_hr/widgets/sri_textfield.dart';

class FormFields extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? type;
  final String? value;
  final TextEditingController? textEditingController;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(dynamic)? validator;
  final bool? obscureText;
  final bool? textArea;
  final IconData? suffixIcon;
  final Function()? onSuffixTap;
  final Function()? onPressed;
  final Function()? onTap;
  final Function()? onTapDate;
  final Function(bool)? onSwitchChanged;
  void Function(dynamic)? onChanged;
  final List<DropdownMenuItem<dynamic>>? items;
  final bool? readOnly;
  final bool? isLoading;
  final bool? isFullWidth;
  final Rx<File?>? selectedProfile;
  final Rx<File?>? selectedFile;
  final dynamic editingItem;
  final bool? switchValue;
  final double? topPadding;
  final double? bottomPadding;
  final double? rightPadding;
  final double? leftPadding;

  FormFields({
    super.key,
    this.label,
    this.hint,
    this.type,
    this.value,
    this.isFullWidth,
    this.isLoading,
    this.keyboardType,
    this.items,
    this.obscureText,
    this.textArea,
    this.onChanged,
    this.onPressed,
    this.onTap,
    this.onTapDate,
    this.onSuffixTap,
    this.prefixIcon,
    this.suffixIcon,
    this.textEditingController,
    this.selectedProfile,
    this.selectedFile,
    this.editingItem,
    this.validator,
    this.onSwitchChanged,
    this.readOnly,
    this.switchValue,
    this.topPadding,
    this.bottomPadding,
    this.leftPadding,
    this.rightPadding,
  });

  @override
  Widget build(BuildContext context) {
    Widget fields({
      String? label,
      String? hint,
      String? type,
      String? value,
      TextEditingController? textEditingController,
      TextInputType? keyboardType,
      IconData? prefixIcon,
      String? Function(dynamic)? validator,
      bool? obscureText,
      bool? textArea,
      IconData? suffixIcon,
      Function()? onSuffixTap,
      Function()? onPressed,
      Function()? onTap,
      Function()? onTapDate,
      Function(bool)? onSwitchChanged,
      Function(dynamic)? onChanged,
      List<DropdownMenuItem<dynamic>>? items,
      Rx<File?>? selectedProfile,
      Rx<File?>? selectedFile,
      dynamic editingItem,
      bool? readOnly,
      bool? isLoading,
      bool? switchValue,
      bool? isFullWidth,
      double? topPadding,
      double? bottomPadding,
      double? leftPadding,
      double? rightPadding,
    }) {
      switch (type) {
        case "text":
          return Padding(
            padding: EdgeInsets.only(
              top: topPadding ?? 0.0,
              bottom: bottomPadding ?? 0.0,
              right: rightPadding ?? 0.0,
              left: leftPadding ?? 0.0,
            ),
            child: SriTextField(
              label: label ?? '',
              controller: textEditingController ?? TextEditingController(),
              obscureText: obscureText ?? false,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              onSuffixTap: onSuffixTap,
              maxLines: textArea == true ? 3 : 1,
              onTap: onTap,
              onChanged: onChanged,
              validator: validator,
              keyboardType: keyboardType,
              readOnly: readOnly ?? false,
            ),
          );
        case "date":
          return Padding(
            padding: EdgeInsets.only(
              top: topPadding ?? 0.0,
              bottom: bottomPadding ?? 0.0,
              right: rightPadding ?? 0.0,
              left: leftPadding ?? 0.0,
            ),
            child: SriTextField(
              label: label ?? '',
              controller: textEditingController ?? TextEditingController(),
              obscureText: obscureText ?? false,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              onSuffixTap: onSuffixTap,
              onTap: onTapDate,
              onChanged: onChanged,
              validator: validator,
              keyboardType: keyboardType,
              readOnly: readOnly ?? false,
            ),
          );
        // case "dropdown":
        //   return Padding(
        //     padding: EdgeInsets.only(
        //       top: topPadding ?? 0.0,
        //       bottom: bottomPadding ?? 0.0,
        //       right: rightPadding ?? 0.0,
        //       left: leftPadding ?? 0.0,
        //     ),
        //     child: AppDropdown(
        //       label: label ?? '',
        //       value: value,
        //       prefixIcon: prefixIcon,
        //       onChanged: onChanged,
        //       items: items ?? [],
        //       validator: validator,
        //     ),
        //   );
        case "switch":
          return Padding(
            padding: EdgeInsets.only(
              top: topPadding ?? 0.0,
              bottom: bottomPadding ?? 0.0,
              right: rightPadding ?? 0.0,
              left: leftPadding ?? 0.0,
            ),
            child: SwitchListTile(
              title: Text(
                label ?? "",
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: hint != null
                  ? Text(
                      hint,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.0,
                      ),
                    )
                  : null,
              value: switchValue ?? false,
              onChanged: onSwitchChanged,
              inactiveThumbColor: AppColors.textMuted.withOpacity(0.8),
              trackOutlineColor: WidgetStateColor.resolveWith((color) {
                return AppColors.textMuted.withOpacity(0.4);
              }),
            ),
          );
        case "logo":
          return Obx(
            () => Padding(
              padding: EdgeInsets.only(
                top: topPadding ?? 0.0,
                bottom: bottomPadding ?? 0.0,
                right: rightPadding ?? 0.0,
                left: leftPadding ?? 0.0,
              ),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 90.0,
                  height: 90.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: selectedProfile?.value != null
                        ? DecorationImage(
                            image: FileImage(selectedProfile!.value!),
                            fit: BoxFit.cover,
                          )
                        : (editingItem?.profilePictureUrl != null &&
                              editingItem!.profilePictureUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(
                              editingItem!.profilePictureUrl!,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: selectedProfile?.value != null
                      ? SizedBox()
                      : editingItem?.profilePictureUrl != null
                      ? SizedBox()
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 40,
                        ),
                ),
              ),
            ),
          );
        case "button":
          return Padding(
            padding: EdgeInsets.only(
              top: topPadding ?? 0.0,
              bottom: bottomPadding ?? 0.0,
              right: rightPadding ?? 0.0,
              left: leftPadding ?? 0.0,
            ),
            child: SriButton(
              label: label ?? '',
              onPressed: onPressed,
              isLoading: isLoading ?? false,
              isFullWidth: isFullWidth ?? false,
            ),
          );
        case "file":
          return Obx(
            () => GestureDetector(
              onTap: onTap,
              child: Container(
                height: 80.0,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: selectedFile?.value != null
                        ? AppColors.primary
                        : AppColors.textMuted.withOpacity(0.1),
                    width: selectedFile?.value != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selectedFile?.value != null
                          ? Icons.check_circle
                          : Icons.upload_file_outlined,
                      color: selectedFile?.value != null
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedFile?.value != null
                          ? 'Document uploaded'
                          : 'Upload Document',
                      style: TextStyle(
                        color: selectedFile?.value != null
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        default:
          return SizedBox();
      }
    }

    return fields(
      label: label,
      hint: hint,
      type: type,
      value: value,
      items: items,
      textArea: textArea,
      onChanged: onChanged,
      onTapDate: onTapDate,
      textEditingController: textEditingController,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      validator: validator,
      readOnly: readOnly,
      obscureText: obscureText,
      switchValue: switchValue,
      onSwitchChanged: onSwitchChanged,
      suffixIcon: suffixIcon,
      onSuffixTap: onSuffixTap,
      onPressed: onPressed,
      onTap: onTap,
      isLoading: isLoading,
      selectedProfile: selectedProfile,
      selectedFile: selectedFile,
      editingItem: editingItem,
      isFullWidth: isFullWidth,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      leftPadding: leftPadding,
      rightPadding: rightPadding,
    );
  }
}
