import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/widgets/current_location_button.dart';

class SriDetailCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool showLocationButton;
  final TextEditingController? address;
  final TextEditingController? country;
  final TextEditingController? state;
  final TextEditingController? city;
  final TextEditingController? pincode;
  final TextEditingController? lat;
  final TextEditingController? lon;
  final List<Widget> children;
  const SriDetailCard({super.key, 
    required this.title, required this.icon, required this.children, this.showLocationButton = false, this.address, this.country, this.state, this.city, this.pincode, this.lat, this.lon});

  @override
  State<SriDetailCard> createState() => _SriDetailCardState();
}

class _SriDetailCardState extends State<SriDetailCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(widget.icon, color: AppColors.primary, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.title, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
          ),
          if(widget.showLocationButton)
            const SizedBox(width: 10),
            if(widget.showLocationButton)
              CurrentLocationButton(
                                onFetched: (info) => setState(
                                  () => info.applyTo(
                                    addressCtrl: widget.address,
                                    countryCtrl: widget.country,
                                    stateCtrl: widget.state,
                                    cityCtrl: widget.city,
                                    pincodeCtrl: widget.pincode,
                                    latCtrl: widget.lat,
                                    lonCtrl: widget.lon,
                                  ),
                                ),
                              ),
        ]),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        ...widget.children,
      ]),
    );
  }
}