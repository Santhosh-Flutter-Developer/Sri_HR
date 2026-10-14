import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/widgets/current_location_button.dart';

class StepTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool showLocationButton;
  final TextEditingController? address;
  final TextEditingController? country;
  final TextEditingController? state;
  final TextEditingController? city;
  final TextEditingController? pincode;

  const StepTitle({
    super.key,
    required this.title,
    required this.icon,
    this.showLocationButton = false,
    this.address,
    this.country,
    this.state,
    this.city,
    this.pincode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (showLocationButton) const SizedBox(width: 12),
        if (showLocationButton)
          CurrentLocationButton(
            onFetched: (info) => info.applyTo(
              addressCtrl: address,
              countryCtrl: country,
              stateCtrl: state,
              cityCtrl: city,
              pincodeCtrl: pincode,
            ),
          ),
      ],
    );
  }
}
