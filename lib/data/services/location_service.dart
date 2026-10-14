import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// ============================================================
//  AddressInfo -- result of "use my current location"
// ============================================================
class AddressInfo {
  final String address; // street / area level text
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double latitude;
  final double longitude;

  /// GPS accuracy radius in metres (smaller = better).
  final double accuracyMeters;

  /// true when at least two independent address sources returned the
  /// same pincode.
  final bool pincodeVerified;

  const AddressInfo({
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 0,
    this.pincodeVerified = false,
  });

  String get latText => latitude.toStringAsFixed(6);
  String get lonText => longitude.toStringAsFixed(6);

  /// Fills whichever controllers are passed. Anything left null is untouched,
  /// so each screen only receives the fields it actually has.
  void applyTo({
    TextEditingController? addressCtrl,
    TextEditingController? cityCtrl,
    TextEditingController? stateCtrl,
    TextEditingController? countryCtrl,
    TextEditingController? pincodeCtrl,
    TextEditingController? latCtrl,
    TextEditingController? lonCtrl,
  }) {
    if (addressCtrl != null && address.isNotEmpty) addressCtrl.text = address;
    if (cityCtrl != null && city.isNotEmpty) cityCtrl.text = city;
    if (stateCtrl != null && state.isNotEmpty) stateCtrl.text = state;
    if (countryCtrl != null && country.isNotEmpty) countryCtrl.text = country;
    if (pincodeCtrl != null && pincode.isNotEmpty) pincodeCtrl.text = pincode;
    if (latCtrl != null) latCtrl.text = latText;
    if (lonCtrl != null) lonCtrl.text = lonText;
  }
}

/// Friendly, user-displayable failure.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}

/// Internal: one provider's reverse-geocode answer.
class _Geo {
  final String address, city, state, country, pincode;
  const _Geo({
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.pincode = '',
  });
}

// ============================================================
//  LocationService
// ============================================================
class LocationService extends GetxService {
  final Rx<Position?> currentPosition = Rx(null);
  final RxBool isInsideGeofence = false.obs;

  /// Stop collecting GPS readings as soon as one is this accurate (metres).
  static const double _goodEnoughAccuracy = 20;

  /// Otherwise keep listening this long and use the most accurate reading.
  static const Duration _collectWindow = Duration(seconds: 10);

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location', 'Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  // ----------------------------------------------------------
  //  Current location -> full address (city, state, country,
  //  pincode, latitude, longitude)
  //  Throws [LocationException] with a user-friendly message.
  // ----------------------------------------------------------
  Future<AddressInfo> fetchCurrentAddress() async {
    final pos = await _getBestPosition();
    currentPosition.value = pos;

    final lat = pos.latitude;
    final lng = pos.longitude;

    // Ask three independent services in parallel, then cross-check.
    final results = await Future.wait<_Geo?>([
      _safe(() => _nominatim(lat, lng)),
      _safe(() => _photon(lat, lng)),
      _safe(() => _bigDataCloud(lat, lng)),
    ]);
    final geos = results.whereType<_Geo>().toList(); // priority order kept

    if (geos.isEmpty) {
      throw const LocationException(
        'Got your location but could not look up the address. '
        'Check your internet connection and try again.',
      );
    }

    String first(String Function(_Geo g) pick) {
      for (final g in geos) {
        final v = pick(g);
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final country = first((g) => g.country);
    final isIndia = country.toLowerCase() == 'india';

    // Pincode: majority vote across sources (priority order breaks ties)
    bool validPin(String p) =>
        p.isNotEmpty && (!isIndia || RegExp(r'^[1-9]\d{5}$').hasMatch(p));
    final pins = geos.map((g) => g.pincode).where(validPin).toList();
    final counts = <String, int>{};
    for (final p in pins) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    var pincode = '';
    var bestCount = 0;
    for (final p in pins) {
      if (counts[p]! > bestCount) {
        pincode = p;
        bestCount = counts[p]!;
      }
    }

    return AddressInfo(
      address: first((g) => g.address),
      city: first((g) => g.city),
      state: first((g) => g.state),
      country: country,
      pincode: pincode,
      latitude: lat,
      longitude: lng,
      accuracyMeters: pos.accuracy,
      pincodeVerified: bestCount >= 2,
    );
  }

  Future<T?> _safe<T>(Future<T?> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------
  //  GPS: collect several readings and keep the most accurate.
  //  A single getCurrentPosition() often returns a coarse
  //  Wi-Fi / cell / IP based fix, which is why the result
  //  used to jump around between taps.
  // ----------------------------------------------------------
  Future<Position> _getBestPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are turned off. Please enable GPS and try again.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission was denied. Allow it to use this feature.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is blocked. Enable it from your '
        'browser / phone app settings and try again.',
      );
    }

    final completer = Completer<Position?>();
    Position? best;
    StreamSubscription<Position>? sub;
    Timer? timer;

    void finish([Object? error]) {
      if (completer.isCompleted) return;
      timer?.cancel();
      sub?.cancel();
      if (error != null && best == null) {
        completer.completeError(error);
      } else {
        completer.complete(best);
      }
    }

    sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(
      (p) {
        if (best == null || p.accuracy < best!.accuracy) best = p;
        if (best!.accuracy <= _goodEnoughAccuracy) finish();
      },
      onError: (e) => finish(e),
    );
    timer = Timer(_collectWindow, finish);

    final Position? result;
    try {
      result = await completer.future;
    } catch (_) {
      throw const LocationException('Could not get your current location.');
    }
    if (result == null) {
      throw const LocationException(
        'Timed out while getting your location. '
        'Move to an open area and try again.',
      );
    }
    return result;
  }

  // -- Provider 1: OpenStreetMap Nominatim ---------------------
  Future<_Geo?> _nominatim(double lat, double lng) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '18',
      'addressdetails': '1',
      'accept-language': 'en',
    });

    // Browsers forbid setting User-Agent; Nominatim policy wants one on native.
    final headers = <String, String>{
      'Accept': 'application/json',
      if (!kIsWeb) 'User-Agent': 'SriHR/1.0 (address-autofill)',
    };

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    if (body is! Map || body['address'] is! Map) return null;
    final a = Map<String, dynamic>.from(body['address'] as Map);

    String pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k]?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final street = [
      [pick(['house_number']), pick(['road'])]
          .where((e) => e.isNotEmpty)
          .join(' '),
      pick(['neighbourhood', 'quarter']),
      pick(['suburb']),
    ].where((e) => e.isNotEmpty).join(', ');

    return _Geo(
      address:
          street.isNotEmpty ? street : (body['display_name']?.toString() ?? ''),
      city: pick([
        'city',
        'town',
        'village',
        'municipality',
        'city_district',
        'county',
        'state_district',
      ]),
      state: pick(['state', 'region', 'state_district']),
      country: pick(['country']),
      pincode: _cleanPincode(pick(['postcode'])),
    );
  }

  // -- Provider 2: Photon (komoot, OSM based, CORS-friendly) ---
  Future<_Geo?> _photon(double lat, double lng) async {
    final uri = Uri.https('photon.komoot.io', '/reverse', {
      'lat': '$lat',
      'lon': '$lng',
      'lang': 'en',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    if (body is! Map || body['features'] is! List) return null;
    final feats = body['features'] as List;
    if (feats.isEmpty) return null;
    final p = (feats.first as Map)['properties'];
    if (p is! Map) return null;

    String s(String k) => p[k]?.toString().trim() ?? '';

    final street = [
      [s('housenumber'), s('street')].where((e) => e.isNotEmpty).join(' '),
      s('locality'),
      s('district'),
    ].where((e) => e.isNotEmpty).join(', ');

    final city = [s('city'), s('town'), s('village'), s('county')]
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');

    return _Geo(
      address: street,
      city: city,
      state: s('state'),
      country: s('country'),
      pincode: _cleanPincode(s('postcode')),
    );
  }

  // -- Provider 3: BigDataCloud (free, no key, CORS-friendly) --
  Future<_Geo?> _bigDataCloud(double lat, double lng) async {
    final uri = Uri.https(
      'api.bigdatacloud.net',
      '/data/reverse-geocode-client',
      {
        'latitude': '$lat',
        'longitude': '$lng',
        'localityLanguage': 'en',
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;

    final b = jsonDecode(res.body);
    if (b is! Map) return null;

    String s(String k) => b[k]?.toString().trim() ?? '';

    return _Geo(
      address: s('locality'),
      city: s('city').isNotEmpty ? s('city') : s('locality'),
      state: s('principalSubdivision'),
      country: s('countryName'),
      pincode: _cleanPincode(s('postcode')),
    );
  }

  /// "625 001" -> "625001", "625001;625002" -> "625001"
  String _cleanPincode(String raw) {
    if (raw.isEmpty) return '';
    final first = raw.split(RegExp(r'[;,]')).first;
    return first.replaceAll(RegExp(r'\s+'), '');
  }

  // ----------------------------------------------------------
  //  Geofence helpers (unchanged)
  // ----------------------------------------------------------

  /// Returns distance in meters between two coordinates
  double distanceBetween({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if current position is within geofence
  bool checkGeofence({
    required double officeLat,
    required double officeLng,
    required double radiusInMeters,
    required Position currentPos,
  }) {
    final distance = distanceBetween(
      startLat: officeLat,
      startLng: officeLng,
      endLat: currentPos.latitude,
      endLng: currentPos.longitude,
    );
    final inside = distance <= radiusInMeters;
    isInsideGeofence.value = inside;
    return inside;
  }
}