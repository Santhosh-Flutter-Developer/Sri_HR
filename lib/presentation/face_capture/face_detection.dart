import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:facesdk_plugin/facedetection_interface.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/handler/exception_handler.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/attendance_audio_service.dart';
import 'package:sri_hr/data/services/location_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/presentation/employee/repository/employee_repository.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FaceDetection extends StatefulWidget {
  FaceDetectionViewController? faceDetectionViewController;
  FaceDetection({super.key});

  @override
  State<FaceDetection> createState() => FaceRecognitionViewState();
}

final employeeController = Get.isRegistered<EmployeeController>()
    ? Get.find<EmployeeController>()
    : Get.put(EmployeeController());
final auth = Get.find<AuthController>();
final companyController = Get.isRegistered<CompanyController>()
    ? Get.find<CompanyController>()
    : Get.put(CompanyController());

final attendanceController = Get.isRegistered<AttendanceController>()
    ? Get.find<AttendanceController>()
    : Get.put(AttendanceController());

final _uuid = const Uuid();

RxList<EmployeeModel> allEmployees = <EmployeeModel>[].obs;

class FaceRecognitionViewState extends State<FaceDetection> {
  final location = Get.isRegistered<LocationService>()
      ? Get.find<LocationService>()
      : Get.put(LocationService());
  Position? currentPosition;
  bool isInsideGeofence = false;
  EmployeeModel? employee;
  List<AttendanceLogModel> todayLogs = [];
  bool showToast = true;
  bool callApi = true;
  bool faceRecognized = false;
  bool locationCheck = false;

  // ── Audio / TTS ──────────────────────────────────────────
  final _audio = AttendanceAudioService();
  String _notifLang = 'en'; // loaded from company settings

  dynamic _faces;
  double _livenessThreshold = 0;
  double _identifyThreshold = 0;
  bool _recognized = false;
  String _identifiedName = '';
  String _identifiedSimilarity = '';
  String _identifiedLiveness = '';
  var _identifiedFace;
  var _enrolledFace;
  final _facesdkPlugin = FacesdkPlugin();
  FaceDetectionViewController? faceDetectionViewController;
  String warningStates = '';
  bool visibleWarnings = false;
  Timer? _noMatchTimer;

  @override
  void initState() {
    super.initState();
    init();
    loadSettings();
    getAllEmployee();
    _loadNotifLang();
  }

  /// Load the company's notification language for TTS.
  Future<void> _loadNotifLang() async {
    try {
      // Give employee a moment to load
      await Future.delayed(const Duration(milliseconds: 400));
      if (auth.kioskCompId.value.isEmpty) return;
      final comp = await companyController.getCompany(auth.kioskCompId.value);
      if (comp != null && mounted) {
        setState(() => _notifLang = comp.notificationLanguage);
      }
    } catch (e) {
      debugPrint('[FaceRecognition] _loadNotifLang error: $e');
    }
  }

  @override
  void dispose() {
    // _audio.stop();
    _noMatchTimer?.cancel();
    super.dispose();
  }

  // ── Load ALL today's logs for this employee ──────────────
  Future<void> _loadTodayLogs() async {
    if (employee == null) return;
    if (employee!.id.isEmpty) return;
    if (employee!.companyId.isEmpty) return;
    final today = NetworkTime.now().toIso8601String().substring(0, 10);
    try {
      final rows = await attendanceController.repo.getAttendanceLogs(
        employee!.companyId,
        date: NetworkTime.now(),
        employeeId: employee!.id,
      );
      todayLogs =
          rows
              .where((l) => l.date.toIso8601String().substring(0, 10) == today)
              .toList()
            ..sort((a, b) => a.punchTime.compareTo(b.punchTime));
    } catch (_) {
      todayLogs = [];
    }
  }

  Future<void> init() async {
    int facepluginState = -1;
    String warningState = '';
    bool visibleWarning = false;
    try {
      if (Platform.isAndroid) {
        await _facesdkPlugin
            .setActivation(AppConstants.androidfacesdkLicence)
            .then((value) {
              setState(() => facepluginState = value ?? -1);
              return facepluginState;
            });
      } else {
        await _facesdkPlugin.setActivation(AppConstants.iosfacesdkLicence).then(
          (value) {
            setState(() => facepluginState = value ?? -1);
            return facepluginState;
          },
        );
      }
      if (facepluginState == 0) {
        await _facesdkPlugin.init().then(
          (value) => facepluginState = value ?? -1,
        );
      }
    } catch (e) {
      debugPrint('Init Error:$e');
    }

    try {
      await _facesdkPlugin.setParam({'check_liveness_level': 0});
    } catch (e) {
      debugPrint('CHECK_LIVENESS_ERROR:$e');
    }

    if (facepluginState == -1) {
      warningState = 'Invalid license!';
      visibleWarning = true;
      _audio.play(AttendanceAudioEvent.invalidLicense, _notifLang); // 🔊
    } else if (facepluginState == -2) {
      warningState = 'License expired!';
      visibleWarning = true;
      _audio.play(AttendanceAudioEvent.licenseExpired, _notifLang); // 🔊
    } else if (facepluginState == -3) {
      warningState = 'Invalid license!';
      visibleWarning = true;
      _audio.play(AttendanceAudioEvent.invalidLicense, _notifLang); // 🔊
    } else if (facepluginState == -4) {
      warningState = 'No activated!';
      visibleWarning = true;
      _audio.play(AttendanceAudioEvent.notActivated, _notifLang); // 🔊
    } else if (facepluginState == -5) {
      warningState = 'Init error!';
      visibleWarning = true;
      _audio.play(AttendanceAudioEvent.initError, _notifLang); // 🔊
    }

    setState(() {
      warningStates = warningState;
      visibleWarnings = visibleWarning;
    });
  }

  Future<void> loadSettings() async {
    setState(() {
      _livenessThreshold = 0.7;
      _identifyThreshold = 0.8;
    });
  }

  Future<void> getAllEmployee() async {
    if (auth.kioskCompId.value.isEmpty) {
      debugPrint('[FaceDetection] kioskCompId is empty — skipping getAllEmployee');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Get.back();
          Get.snackbar(
            'Session Error',
            'No session found. Please log in again.',
            backgroundColor: AppColors.warning,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        });
      }
      return;
    }
    final employees = await EmployeeRepository().getAllEmployees(
      auth.kioskCompId.value,
    );
    allEmployees.value = employees.isNotEmpty ? employees : [];
  }

  Future<bool> onFaceDetected(faces) async {
  if (_recognized == true) return false;
  if (!mounted) return false;
  if (allEmployees.isEmpty) return false; // ✅ wait until employees loaded

  setState(() => _faces = faces);

  bool recognized = false;
  double maxSimilarity = -1;
  String maxSimilarityName = '';
  double maxLiveness = -1;
  var enrolledFace, identifiedFace;
  EmployeeModel? matchedEmployee;

  if (faces.length > 0) {
    if (faces.length > 1) {
      _audio.play(AttendanceAudioEvent.multipleFaceDetected, _notifLang);
      Get.back();
      Get.snackbar('Warning', 'Multiple Face Detected',
          backgroundColor: AppColors.warning);
      return false;
    }

    var face = faces[0];

    // ✅ Start timer ONCE, AFTER employees confirmed, flag set BEFORE scheduling
    if (showToast == true) {
      setState(() => showToast = false);
      _noMatchTimer?.cancel();
      _noMatchTimer = Timer(const Duration(seconds: 15), () {
        if (!mounted) return;
        if (faceRecognized == false && !_recognized) {
          faceDetectionViewController?.stopCamera();
          setState(() => faceRecognized = true);
          Get.back();
          _audio.play(AttendanceAudioEvent.noFaceMatched, _notifLang);
          Get.snackbar('Warning', 'No Face Matched',
              backgroundColor: AppColors.warning);
        }
      });
    }

    // ✅ Guard inside loop after every await
    for (final emp in allEmployees) {
      if (!mounted || faceRecognized || _recognized) break;

      String storedTemplateString = emp.profileTemplate ?? '';
      if (storedTemplateString.isEmpty) continue;

      Uint8List storedTemplate = base64Decode(storedTemplateString);
      double similarity =
          await _facesdkPlugin.similarityCalculation(
            face['templates'],
            storedTemplate,
          ) ?? -1;

      if (!mounted || faceRecognized || _recognized) break; // ✅ guard after await

      if (maxSimilarity < similarity) {
        maxSimilarity = similarity;
        maxSimilarityName = emp.fullName;
        maxLiveness = face['liveness'];
        identifiedFace = face['faceJpg'];
        enrolledFace = emp.profilePicture;
        matchedEmployee = emp;
      }
    }

    if (matchedEmployee != null) {
      employee = matchedEmployee;
    }

    // ✅ Bail if another frame already handled it
    if (!mounted || faceRecognized || _recognized) return false;

    if (maxSimilarity > _identifyThreshold && maxLiveness > _livenessThreshold) {
      recognized = true;
    }
  }

  if (faceRecognized || _recognized) return recognized;

  Future.delayed(const Duration(milliseconds: 100), () async {
    if (!mounted) return false;
    if (faceRecognized || _recognized) return false; // ✅ early exit

    currentPosition = await location.getCurrentPosition();
    if (!mounted || faceRecognized) return false;

    if (currentPosition == null) {
      setState(() { faceRecognized = true; locationCheck = true; });
      _noMatchTimer?.cancel();
      faceDetectionViewController?.stopCamera();
      _audio.play(AttendanceAudioEvent.gpsUnavailable, _notifLang);
      Get.back();
      Get.snackbar('Error',
          'Unable to get GPS location. Please enable location services.',
          backgroundColor: AppColors.error);
      return false;
    }

    final compId = auth.kioskCompId.value;
    if (compId.isEmpty) {
      setState(() { faceRecognized = true; locationCheck = true; });
      _noMatchTimer?.cancel();
      faceDetectionViewController?.stopCamera();
      Get.back();
      Get.snackbar('Session Error', 'No session found. Please log in again.',
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
          duration: const Duration(seconds: 4));
      return false;
    }

    final comp = await companyController.getCompany(compId);
    if (!mounted || faceRecognized) return false; // ✅ re-check after await

    if (comp != null) {
      if (comp.latitude != null && comp.longitude != null) {
        isInsideGeofence = location.checkGeofence(
          officeLat: comp.latitude!,
          officeLng: comp.longitude!,
          radiusInMeters: double.parse(comp.radius.toString()),
          currentPos: currentPosition!,
        );
        if (employee?.outsideOffice != true && isInsideGeofence == false) {
          if (locationCheck == false) {
            setState(() { locationCheck = true; faceRecognized = true; });
            _noMatchTimer?.cancel();
            faceDetectionViewController?.stopCamera();
            _audio.play(AttendanceAudioEvent.outsideOffice, _notifLang);
            Get.back();
            Get.snackbar('Warning', 'You are outside the office location',
                backgroundColor: AppColors.warning);
            return false;
          }
        }
      } else {
        if (locationCheck == false) {
          setState(() { locationCheck = true; faceRecognized = true; });
          _noMatchTimer?.cancel();
          faceDetectionViewController?.stopCamera();
          _audio.play(AttendanceAudioEvent.configureLocation, _notifLang);
          Get.back();
          Get.snackbar('Warning',
              'Please configure Company Latitude and Longitude. Contact Admin.',
              backgroundColor: AppColors.warning);
          return false;
        }
      }
    }

    if (!mounted || faceRecognized) return false;

    setState(() {
      _recognized = recognized;
      _identifiedName = maxSimilarityName;
      _identifiedSimilarity = maxSimilarity.toString();
      _identifiedLiveness = maxLiveness.toString();
      _enrolledFace = enrolledFace;
      _identifiedFace = identifiedFace;
    });

    if (recognized) {
      _noMatchTimer?.cancel(); // ✅ success — cancel timeout
      faceDetectionViewController?.stopCamera();
      if (!mounted) return false;
      setState(() { _faces = null; faceRecognized = true; });

      String? faceUrl;
      File imageFile = await uint8ListToFile(identifiedFace, 'image.png');
      if (!mounted) return false;
      if (employee != null) {
        faceUrl = await uploadAttendanceImage(imageFile, const Uuid().v4());
      }
      if (!mounted) return false;

      if (employee == null || comp == null) {
        _audio.play(AttendanceAudioEvent.employeeNotFound, _notifLang);
        Get.snackbar('Error', 'Employee or organization not found',
            backgroundColor: AppColors.error);
        return false;
      }

      if (callApi == true) {
        setState(() => callApi = false);
        await NetworkTime.syncTime();
        if (!mounted) return false;
        if (employee != null &&
            employee!.id.isNotEmpty &&
            employee!.companyId.isNotEmpty) {
          await _loadTodayLogs();
        }
        if (!mounted) return false;
        await _showPunchSelectorSheet();
      }
    }
  });

  return recognized;
}

  // ─────────────────────────────────────────────────────────
  // PUNCH SELECTOR BOTTOM SHEET
  // ─────────────────────────────────────────────────────────
  Future<void> _showPunchSelectorSheet() async {
    final inLogs = todayLogs
        .where((l) => l.punchType == PunchType.in_)
        .toList();
    final outLogs = todayLogs
        .where((l) => l.punchType == PunchType.out)
        .toList();

    // Determine which punch type is valid next
    // Rule: must alternate IN → OUT → IN → OUT
    // If more INs than OUTs → next must be OUT
    // If equal → next must be IN
    final bool mustBeOut = inLogs.length > outLogs.length;
    final bool mustBeIn = inLogs.length == outLogs.length;

    // Pre-select the required type
    String selectedType = mustBeOut ? 'out' : 'in';

    Future.delayed(Duration(seconds: 3), () async {
      Navigator.of(context).pop();
      await _savePunch(selectedType);
    });
    /*await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _PunchSelectorSheet(
        employeeName: employee!.fullName,
        todayLogs: todayLogs,
        inLogs: inLogs,
        outLogs: outLogs,
        mustBeOut: mustBeOut,
        mustBeIn: mustBeIn,
        preSelectedType: selectedType,
        onConfirm: (type) async {
          Navigator.of(ctx).pop();
          await _savePunch(type);
        },
        onCancel: () {
          Navigator.of(ctx).pop();
          // Reset so camera can be used again
          setState(() {
            _recognized = false;
            faceRecognized = false;
            callApi = true;
            showToast = true;
          });
          Get.offAllNamed(AppRoutes.routeKioskAttendance);
        },
      ),
    );*/
  }

  Future<void> _savePunch(String punchType) async {
    try {
      await attendanceController.adjustPunch(
        {
          'employee_id': employee!.id,
          'company_id': employee!.companyId,
          'date': NetworkTime.now().toIso8601String().substring(0, 10),
          'punch_time': NetworkTime.now().toIso8601String(),
          'punch_type': punchType,
          'latitude': currentPosition?.latitude,
          'longitude': currentPosition?.longitude,
        },
        showToast: false,
        isManual: false,
      );
      final label = punchType == 'in' ? 'Punch IN' : 'Punch OUT';
      if (attendanceController.showErr.value) {
        // 🔊 Play punch success audio
        _audio.play(
          punchType == 'in'
              ? AttendanceAudioEvent.punchInSuccess
              : AttendanceAudioEvent.punchOutSuccess,
          _notifLang,
        );
        Get.snackbar(
          'Success ✓',
          '$label recorded for ${employee!.fullName}',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      } else {
        _audio.play(AttendanceAudioEvent.punchFailed, _notifLang);
      }
    } catch (e) {
      _audio.play(AttendanceAudioEvent.punchFailed, _notifLang); // 🔊
      Get.snackbar(
        'Error',
        handleException(e),
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }

    await Future.delayed(const Duration(seconds: 4));
    Get.offAllNamed(AppRoutes.routeKioskAttendance);
  }

  Future<String?> uploadAttendanceImage(
    File imageFile,
    String attendanceId,
  ) async {
    try {
      final fileName = 'att_${attendanceId}_${_uuid.v4()}.jpg';
      final bytes = await imageFile.readAsBytes();
      await Supabase.instance.client.storage
          .from('attendance')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return Supabase.instance.client.storage
          .from('attendance')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  Future<File> uint8ListToFile(Uint8List bytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    File file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        faceDetectionViewController?.stopCamera();
        return true;
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text(
              'Face Recognition',
              style: TextStyle(color: Colors.white),
            ),
            toolbarHeight: 70,
            centerTitle: false,
          ),
          body: Stack(
            children: <Widget>[
              FaceDetectionView(faceRecognitionViewState: this),
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: FacePainter(
                    faces: _faces,
                    livenessThreshold: _livenessThreshold,
                  ),
                ),
              ),
              // ── Success overlay after recognition ──────────
              if (_recognized)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 60,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _identifiedName,
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                       const SizedBox(height: 8),
                      Text(
                        "Punch Date: ${NetworkTime.now().toIso8601String().substring(0, 10)}",
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                       const SizedBox(height: 8),
                      Text(
                        "Punch Time: ${NetworkTime.now().hour.toString().padLeft(2, '0')}:${NetworkTime.now().minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Identity Verified',
                            style: TextStyle(
                              color: AppColors.success,
                              fontFamily: 'Sora',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_enrolledFace != null)
                            _FaceCard(
                              label: 'Enrolled',
                              child: Image.network(
                                _enrolledFace,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (_identifiedFace != null)
                            _FaceCard(
                              label: 'Captured',
                              child: Image.memory(
                                _identifiedFace,
                                width: 140,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      const Text(
                        'Preparing punch options...',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PUNCH SELECTOR BOTTOM SHEET WIDGET
// ─────────────────────────────────────────────────────────
class _PunchSelectorSheet extends StatefulWidget {
  final String employeeName;
  final List<AttendanceLogModel> todayLogs;
  final List<AttendanceLogModel> inLogs;
  final List<AttendanceLogModel> outLogs;
  final bool mustBeOut;
  final bool mustBeIn;
  final String preSelectedType;
  final Future<void> Function(String type) onConfirm;
  final VoidCallback onCancel;

  const _PunchSelectorSheet({
    required this.employeeName,
    required this.todayLogs,
    required this.inLogs,
    required this.outLogs,
    required this.mustBeOut,
    required this.mustBeIn,
    required this.preSelectedType,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_PunchSelectorSheet> createState() => _PunchSelectorSheetState();
}

class _PunchSelectorSheetState extends State<_PunchSelectorSheet> {
  late String selectedType;
  bool loading = false;
  String? validationError;

  @override
  void initState() {
    super.initState();
    selectedType = widget.preSelectedType;
    _validate(selectedType);
  }

  void _validate(String type) {
    String? err;
    if (type == 'out' && widget.inLogs.length <= widget.outLogs.length) {
      err = 'You must Punch IN before punching OUT.';
    } else if (type == 'in' && widget.inLogs.length > widget.outLogs.length) {
      err = 'You must Punch OUT before punching IN again.';
    }
    setState(() => validationError = err);
  }

  void _select(String type) {
    setState(() => selectedType = type);
    _validate(type);
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _totalHours() {
    int totalMins = 0;
    final pairs = widget.inLogs.length < widget.outLogs.length
        ? widget.inLogs.length
        : widget.outLogs.length;
    for (int i = 0; i < pairs; i++) {
      final diff = widget.outLogs[i].punchTime
          .difference(widget.inLogs[i].punchTime)
          .inMinutes;
      if (diff > 0) totalMins += diff;
    }
    if (totalMins == 0) return '0h 0m';
    return '${totalMins ~/ 60}h ${totalMins % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final now = NetworkTime.now();
    final nowStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ── Header ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark Attendance',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.employeeName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current time chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            nowStr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              // ── Today's Punch History ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Today's Punch History",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (widget.todayLogs.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Total: ${_totalHours()}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (widget.todayLogs.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No punches recorded today',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Timeline of today's punches
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            ...widget.todayLogs.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final log = entry.value;
                              final isIn = log.punchType == PunchType.in_;
                              final isLast = idx == widget.todayLogs.length - 1;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        // Punch type badge
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isIn
                                                ? AppColors.success.withOpacity(
                                                    0.12,
                                                  )
                                                : AppColors.error.withOpacity(
                                                    0.12,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            isIn
                                                ? Icons.login_rounded
                                                : Icons.logout_rounded,
                                            size: 17,
                                            color: isIn
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isIn ? 'Punch IN' : 'Punch OUT',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: isIn
                                                      ? AppColors.success
                                                      : AppColors.error,
                                                ),
                                              ),
                                              Text(
                                                log.isManual
                                                    ? 'Manual adjustment'
                                                    : 'Face attendance',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: log.isManual
                                                      ? AppColors.textMuted
                                                      : AppColors.primary,
                                                  fontWeight: log.isManual
                                                      ? FontWeight.normal
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _fmt(log.punchTime),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Punch Type Selector ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Select Punch Type',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // IN button
                        Expanded(
                          child: _PunchOptionCard(
                            label: 'Punch IN',
                            icon: Icons.login_rounded,
                            color: AppColors.success,
                            selected: selectedType == 'in',
                            disabled: widget.mustBeOut,
                            onTap: widget.mustBeOut
                                ? null
                                : () => _select('in'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // OUT button
                        Expanded(
                          child: _PunchOptionCard(
                            label: 'Punch OUT',
                            icon: Icons.logout_rounded,
                            color: AppColors.error,
                            selected: selectedType == 'out',
                            disabled: widget.mustBeIn,
                            onTap: widget.mustBeIn
                                ? null
                                : () => _select('out'),
                          ),
                        ),
                      ],
                    ),

                    // ── Validation error ────────────────────
                    if (validationError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Info hint ───────────────────────────
                    if (validationError == null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedType == 'in'
                                    ? 'This will record your entry time as $nowStr'
                                    : 'This will record your exit time as $nowStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Action Buttons ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: OutlinedButton(
                        onPressed: loading ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Confirm
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (loading || validationError != null)
                            ? null
                            : () async {
                                setState(() => loading = true);
                                await widget.onConfirm(selectedType);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedType == 'in'
                              ? AppColors.success
                              : AppColors.error,
                          disabledBackgroundColor: AppColors.border,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selectedType == 'in'
                                        ? Icons.login_rounded
                                        : Icons.logout_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedType == 'in'
                                        ? 'Confirm Punch IN'
                                        : 'Confirm Punch OUT',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PUNCH OPTION CARD (IN / OUT selector)
// ─────────────────────────────────────────────────────────
class _PunchOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _PunchOptionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.disabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.surfaceVariant
              : selected
              ? color.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled
                ? AppColors.border
                : selected
                ? color
                : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: disabled
                    ? AppColors.border.withOpacity(0.3)
                    : selected
                    ? color.withOpacity(0.15)
                    : AppColors.border.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: disabled
                    ? AppColors.textMuted
                    : selected
                    ? color
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: disabled
                    ? AppColors.textMuted
                    : selected
                    ? color
                    : AppColors.textSecondary,
              ),
            ),
            if (disabled) ...[
              const SizedBox(height: 4),
              Text(
                'Not allowed',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// FACE CARD HELPER
// ─────────────────────────────────────────────────────────
class _FaceCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _FaceCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────
// FACE DETECTION VIEW (platform view, unchanged)
// ─────────────────────────────────────────────────────────
class FaceDetectionView extends StatefulWidget
    implements FaceDetectionInterface {
  FaceRecognitionViewState faceRecognitionViewState;
  FaceDetectionView({super.key, required this.faceRecognitionViewState});

  @override
  Future<void> onFaceDetected(faces) async {
    await faceRecognitionViewState.onFaceDetected(faces);
  }

  @override
  State<StatefulWidget> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return UiKitView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
  }

  void _onPlatformViewCreated(int id) async {
    widget.faceRecognitionViewState.faceDetectionViewController =
        FaceDetectionViewController(id, widget);
    await widget.faceRecognitionViewState.faceDetectionViewController
        ?.initHandler();
    await widget.faceRecognitionViewState._facesdkPlugin.setParam({
      'check_liveness_level': 0,
    });
    await widget.faceRecognitionViewState.faceDetectionViewController
        ?.startCamera(1);
  }
}

// ─────────────────────────────────────────────────────────
// FACE PAINTER (draws bounding boxes, unchanged)
// ─────────────────────────────────────────────────────────
class FacePainter extends CustomPainter {
  dynamic faces;
  double livenessThreshold;
  FacePainter({required this.faces, required this.livenessThreshold});

  @override
  void paint(Canvas canvas, Size size) {
    if (faces != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      for (var face in faces) {
        double xScale = face['frameWidth'] / size.width;
        double yScale = face['frameHeight'] / size.height;
        final Color color = face['liveness'] < livenessThreshold
            ? const Color(0xFFFF0000)
            : const Color(0xFF00FF00);
        final String title = face['liveness'] < livenessThreshold
            ? 'Spoof ${face['liveness'].toStringAsFixed(2)}'
            : 'Real ${face['liveness'].toStringAsFixed(2)}';

        final tp = TextPainter(
          text: TextSpan(
            style: TextStyle(color: color, fontSize: 18),
            text: title,
          ),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(face['x1'] / xScale, face['y1'] / yScale - 28));

        paint.color = color;
        canvas.drawRect(
          Offset(face['x1'] / xScale, face['y1'] / yScale) &
              Size(
                (face['x2'] - face['x1']) / xScale,
                (face['y2'] - face['y1']) / yScale,
              ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
