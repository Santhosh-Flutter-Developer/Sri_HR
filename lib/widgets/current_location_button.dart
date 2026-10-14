import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/services/location_service.dart';
import 'package:sri_hr/presentation/helper/helper.dart';

/// One-tap "use my current location" icon button.
/// Gets GPS position, reverse-geocodes it and hands the result to [onFetched]
/// so the host screen can fill its own controllers.
class CurrentLocationButton extends StatefulWidget {
  final void Function(AddressInfo info) onFetched;
  final String label;

  const CurrentLocationButton({
    super.key,
    required this.onFetched,
    this.label = 'Use Current Location',
  });

  @override
  State<CurrentLocationButton> createState() => _CurrentLocationButtonState();
}

class _CurrentLocationButtonState extends State<CurrentLocationButton> {
  bool _loading = false;

  LocationService get _service => Get.isRegistered<LocationService>()
      ? Get.find<LocationService>()
      : Get.put(LocationService());

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final info = await _service.fetchCurrentAddress();
      if (!mounted) return;
      widget.onFetched(info);
    } on LocationException catch (e) {
      showError(e.message, title: 'Location');
    } catch (_) {
      showError('Something went wrong while fetching your location.',
          title: 'Location');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      child: IconButton(
        onPressed: _loading ? null : _fetch,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.all(10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location_rounded, size: 20),
      ),
    );
  }
}