import 'dart:convert';
import 'dart:io';

import 'package:facesdk_plugin/facedetection_interface.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';
import 'package:sri_hr/data/models/employee_model.dart';
import 'package:sri_hr/data/services/location_service.dart';
import 'package:sri_hr/data/utils/network_time.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/presentation/company/controller/company_controller.dart';
import 'package:sri_hr/presentation/employee/controller/employee_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FaceRecognitionView extends StatefulWidget {
  FaceDetectionViewController? faceDetectionViewController;
  FaceRecognitionView({super.key});

  @override
  State<FaceRecognitionView> createState() => FaceRecognitionViewState();
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

RxList<EmployeeModel> employees = <EmployeeModel>[].obs;

class FaceRecognitionViewState extends State<FaceRecognitionView> {
  final location = Get.isRegistered<LocationService>()
      ? Get.find<LocationService>()
      : Get.put(LocationService());
  Position? currentPosition;
  bool isInsideGeofence = false;
  EmployeeModel? employee;
  AttendanceLogModel? todayAttendance;
  bool isCheckIn = true;
  bool showToast = true;
  bool callApi = true;
  bool faceRecognized = false;

  dynamic _faces;
  double _livenessThreshold = 0;
  double _identifyThreshold = 0;
  bool _recognized = false;
  String _identifiedName = "";
  String _identifiedSimilarity = "";
  String _identifiedLiveness = "";
  String _identifiedYaw = "";
  String _identifiedRoll = "";
  String _identifiedPitch = "";
  String warningStates = "";
  bool visibleWarnings = false;

  var _identifiedFace;

  var _enrolledFace;
  final _facesdkPlugin = FacesdkPlugin();
  FaceDetectionViewController? faceDetectionViewController;

  @override
  void initState() {
    super.initState();
    init();
    loadSettings();
    getEmployee();
  }

  Future<void> _loadTodayAttendance() async {
    if (employee != null) {
      todayAttendance = await attendanceController.getTodayAttendance(
        employee!.id,
      );
      isCheckIn = todayAttendance?.punchTime == null;
    }
    setState(() {});
  }

  Future<void> init() async {
    int facepluginState = -1;
    String warningState = "";
    bool visibleWarning = false;
    try {
      if (Platform.isAndroid) {
        await _facesdkPlugin
            .setActivation(AppConstants.androidfacesdkLicence)
            .then((value) {
              setState(() {
                facepluginState = value ?? -1;
              });
              return facepluginState;
            });
      } else {
        await _facesdkPlugin.setActivation(AppConstants.iosfacesdkLicence).then(
          (value) {
            setState(() {
              facepluginState = value ?? -1;
            });
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
      debugPrint("Init Error:$e");
    }

    int? livenessLevel = 0;
    try {
      await _facesdkPlugin.setParam({'check_liveness_level': livenessLevel});
    } catch (e) {
      debugPrint("CHECK_LIVENESS_ERROR:$e");
    }

    if (facepluginState == -1) {
      setState(() {
        warningState = "Invalid license!";
        visibleWarning = true;
      });
    } else if (facepluginState == -2) {
      setState(() {
        warningState = "License expired!";
        visibleWarning = true;
      });
    } else if (facepluginState == -3) {
      setState(() {
        warningState = "Invalid license!";
        visibleWarning = true;
      });
    } else if (facepluginState == -4) {
      warningState = "No activated!";
      visibleWarning = true;
    } else if (facepluginState == -5) {
      warningState = "Init error!";
      visibleWarning = true;
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

  Future<void> getEmployee() async {
    employee = await employeeController.getEmployee(auth.userId);
  }

  Future<void> faceRecognitionStart() async {
    var cameraLens = 1;
    setState(() {
      _faces = null;
      _recognized = false;
      faceRecognized = false;
    });
    await faceDetectionViewController?.startCamera(cameraLens);
  }

  Future<bool> onFaceDetected(faces) async {
    if (_recognized == true) {
      return false;
    }
    if (!mounted) return false;

    setState(() {
      _faces = faces;
    });

    bool recognized = false;
    double maxSimilarity = -1;
    String maxSimilarityName = "";
    double maxLiveness = -1;
    double maxYaw = -1;
    double maxRoll = -1;
    double maxPitch = -1;

    var enrolledFace, identifiedFace;

    if (faces.length > 0) {
      if (faces.length > 1) {
        Get.snackbar(
          "Warning",
          "Multiple Face Detected",
          backgroundColor: AppColors.warning,
        );
      }
      var face = faces[0];

      String storedTemplateString = employee?.profileTemplate ?? '';
      if (storedTemplateString == "") {
        faceDetectionViewController?.stopCamera();
        Get.back();
        Get.snackbar(
          "Warning",
          "Logged-in user's face is not registered in the employee records",
          backgroundColor: AppColors.warning,
        );
        return false;
      }
      Uint8List storedTemplate = base64Decode(storedTemplateString);
      double similarity =
          await _facesdkPlugin.similarityCalculation(
            face["templates"],
            storedTemplate,
          ) ??
          -1;

      if (maxSimilarity < similarity) {
        maxSimilarity = similarity;
        maxSimilarityName = employee!.fullName;
        maxLiveness = face["liveness"];
        maxYaw = face["yaw"];
        maxRoll = face["roll"];
        maxPitch = face["pitch"];
        identifiedFace = face["faceJpg"];
        enrolledFace = employee!.profilePicture;
      }
      if (showToast == true) {
        Future.delayed(Duration(seconds: 10), () {
          if (faceRecognized == false) {
            faceDetectionViewController?.stopCamera();
            Get.back();
            Get.snackbar(
              "Warning",
              "No Face Matched",
              backgroundColor: AppColors.warning,
            );
          }
        });
      }
      setState(() {
        showToast = false;
      });

      if (maxSimilarity > _identifyThreshold &&
          maxLiveness > _livenessThreshold) {
        recognized = true;
      }
    }
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return false;
      await _loadTodayAttendance();
      // ── Get GPS ──────────────────────────────────────────
      currentPosition = await location.getCurrentPosition();
      if (currentPosition == null) {
        throw Exception('Unable to get GPS location. Please enable location.');
      }

      // ── Check geofence ───────────────────────────────────
      final compId = employee!.companyId;
      final comp = await companyController.getCompany(compId);
      if (comp != null) {
        if (comp.latitude != null && comp.longitude != null) {
          isInsideGeofence = location.checkGeofence(
            officeLat: comp.latitude!,
            officeLng: comp.longitude!,
            radiusInMeters: double.parse(comp.radius.toString()),
            currentPos: currentPosition!,
          );

          if (employee?.outsideOffice != true && isInsideGeofence == false) {
            faceDetectionViewController?.stopCamera();
            Get.back();
            Get.snackbar(
              "Warning",
              "You are an outside of office location",
              backgroundColor: AppColors.warning,
            );
            return false;
          }
        } else {
          faceRecognized = true;
          faceDetectionViewController?.stopCamera();
          Get.back();
          Get.snackbar(
            "Warning",
            "Please configure Company Latitude and Longitude before proceeding. Contact Admin",
            backgroundColor: AppColors.warning,
          );
          return false;
        }
      }

      setState(() {
        _recognized = recognized;
        _identifiedName = maxSimilarityName;
        _identifiedSimilarity = maxSimilarity.toString();
        _identifiedLiveness = maxLiveness.toString();
        _identifiedYaw = maxYaw.toString();
        _identifiedRoll = maxRoll.toString();
        _identifiedPitch = maxPitch.toString();
        _enrolledFace = enrolledFace;
        _identifiedFace = identifiedFace;
        // callApi = true;
      });

      if (recognized) {
        faceDetectionViewController?.stopCamera();

        setState(() {
          _faces = null;
          faceRecognized = true;
        });

        //Upload face image
        String? faceUrl;
        File imageFile = await uint8ListToFile(identifiedFace, 'image.png');
        if (employee != null) {
          faceUrl = await uploadAttendanceImage(imageFile, const Uuid().v4());
        }

        if (employee == null || comp == null) {
          throw Exception("Employee or organization not found");
        }
        if (callApi == true) {
          setState(() {
            callApi = false;
          });
          await NetworkTime.syncTime();
          if (isCheckIn) {
            await attendanceController.adjustPunch({
              'employee_id': employee!.id,
              'date': NetworkTime.now().toIso8601String().substring(0, 10),
              'punch_time': NetworkTime.now().toIso8601String(),
              'punch_type': 'in',
            }, showToast: false);
          } else {
            await attendanceController.adjustPunch({
              'employee_id': employee!.id,
              'date': NetworkTime.now().toIso8601String().substring(0, 10),
              'punch_time': NetworkTime.now().toIso8601String(),
              'punch_type': 'out',
            }, showToast: false);
          }

          Get.snackbar(
            "Success",
            "Face Recognized Successfully",
            backgroundColor: AppColors.success,
          );
        }

        Future.delayed(Duration(seconds: 3), () {
          Get.offAllNamed(AppRoutes.routeDashboard);
        });
      }
    });

    return recognized;
  }

  Future<String?> uploadAttendanceImage(
    File imageFile,
    String attendanceId,
  ) async {
    try {
      final fileName = 'att_${attendanceId}_${_uuid.v4()}.jpg';
      final bytes = await imageFile.readAsBytes();

      await Supabase.instance.client.storage
          .from("attendance")
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = Supabase.instance.client.storage
          .from("attendance")
          .getPublicUrl(fileName);
      return url;
    } catch (e) {
      Get.snackbar('Upload Error', e.toString());
      return null;
    }
  }

  Future<File> uint8ListToFile(Uint8List bytes, String fileName) async {
    final directory =
        await getTemporaryDirectory(); // or getApplicationDocumentsDirectory()
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
          appBar: AppBar(
            title: const Text('Face Recognition'),
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
              Visibility(
                visible: _recognized,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 60.0,
                      ),
                      SizedBox(height: 6.0),
                      Text(
                        _identifiedName.toString(),
                        style: TextStyle(
                          fontFamily: "Sora",
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20.0,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Identity Verified",
                            style: TextStyle(
                              fontFamily: "Sora",
                              fontSize: 14.0,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _enrolledFace != null
                              ? Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.success,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(2),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image.network(
                                          _enrolledFace,
                                          width: 160,
                                          height: 160,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text('Enrolled'),
                                  ],
                                )
                              : const SizedBox(height: 1),
                          _identifiedFace != null
                              ? Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: AppColors.success,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      padding: EdgeInsets.all(2),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image.memory(
                                          _identifiedFace,
                                          width: 160,
                                          height: 160,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text('Identified'),
                                  ],
                                )
                              : const SizedBox(height: 1),
                        ],
                      ),
                      const SizedBox(height: 30),
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
}

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
    var cameraLens = 1;

    widget.faceRecognitionViewState.faceDetectionViewController =
        FaceDetectionViewController(id, widget);

    await widget.faceRecognitionViewState.faceDetectionViewController
        ?.initHandler();

    int? livenessLevel = 0;
    await widget.faceRecognitionViewState._facesdkPlugin.setParam({
      'check_liveness_level': livenessLevel,
    });

    await widget.faceRecognitionViewState.faceDetectionViewController
        ?.startCamera(cameraLens);
  }
}

class FacePainter extends CustomPainter {
  dynamic faces;
  double livenessThreshold;
  FacePainter({required this.faces, required this.livenessThreshold});

  @override
  void paint(Canvas canvas, Size size) {
    if (faces != null) {
      var paint = Paint();
      paint.color = const Color.fromARGB(0xff, 0xff, 0, 0);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;

      for (var face in faces) {
        double xScale = face['frameWidth'] / size.width;
        double yScale = face['frameHeight'] / size.height;

        String title = "";
        Color color = const Color.fromARGB(0xff, 0xff, 0, 0);
        if (face['liveness'] < livenessThreshold) {
          color = const Color.fromARGB(0xff, 0xff, 0, 0);
          title = "Spoof${face['liveness']}";
        } else {
          color = const Color.fromARGB(0xff, 0, 0xff, 0);
          title = "Real ${face['liveness']}";
        }

        TextSpan span = TextSpan(
          style: TextStyle(color: color, fontSize: 20),
          text: title,
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(face['x1'] / xScale, face['y1'] / yScale - 30));

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
