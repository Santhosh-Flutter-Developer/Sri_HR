import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:sri_hr/widgets/sidebar_widget.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance>
    with TickerProviderStateMixin {
  // ── Clock ─────────────────────────────────────────────────
  late Timer _clockTimer;
  late DateTime _now;

  // ── Pulse animation on fingerprint button ─────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // ── Shimmer on the ring ───────────────────────────────────
  late AnimationController _ringCtrl;
  late Animation<double> _ringAngle;

  // ── Floating dots ─────────────────────────────────────────
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  // ── Tap feedback ─────────────────────────────────────────
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  final auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );

    // Pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseOpacity = Tween<double>(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    // Ring rotation
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _ringAngle = Tween<double>(begin: 0, end: 6.283).animate(_ringCtrl);

    // Float
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // Tap feedback
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _tapScale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    _clockTimer.cancel();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _floatCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  String get _timeStr {
    final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _amPm => _now.hour < 12 ? 'AM' : 'PM';

  String get _dateStr {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}, ${_now.year}';
  }

  void _onMarkAttendance() async {
    HapticFeedback.mediumImpact();
    await _tapCtrl.forward();
    await _tapCtrl.reverse();
    if (!auth.isAdmin && auth.kioskCompId.isEmpty) {
      Get.toNamed(AppRoutes.routeFaceRecognition);
      return;
    }
    Get.toNamed(AppRoutes.routeFaceDetection);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF060D1F),
        drawer: !auth.isAdmin && auth.kioskCompId.isEmpty
            ? Drawer(
                backgroundColor: AppColors.sidebarBg,
                width: 280,
                child: SidebarWidget(currentModule: "dashboard"),
              )
            : null,
        body: Stack(
          children: [
            // ── Gradient background ──────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [Color(0xFF1A2B6B), Color(0xFF060D1F)],
                  ),
                ),
              ),
            ),

            // ── Decorative top arc ───────────────────────────
            Positioned(
              top: -size.width * 0.3,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 1.4,
                height: size.width * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.08),
                    width: 60,
                  ),
                ),
              ),
            ),

            // ── Decorative bottom-right circle ───────────────
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.06),
                    width: 40,
                  ),
                ),
              ),
            ),

            // ── Floating particle dots ────────────────────────
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, __) => Stack(
                children: [
                  _dot(
                    left: size.width * 0.1,
                    top: size.height * 0.15 + _floatAnim.value,
                    size: 6,
                  ),
                  _dot(
                    right: size.width * 0.12,
                    top: size.height * 0.22 - _floatAnim.value * 0.7,
                    size: 4,
                  ),
                  _dot(
                    left: size.width * 0.2,
                    bottom: size.height * 0.2 + _floatAnim.value * 0.5,
                    size: 5,
                  ),
                  _dot(
                    right: size.width * 0.2,
                    bottom: size.height * 0.3 - _floatAnim.value * 0.8,
                    size: 3,
                  ),
                ],
              ),
            ),

            // ── Main content ─────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Logo/Brand
                        !auth.isAdmin && auth.kioskCompId.isEmpty
                            ? Builder(
                                builder: (context) {
                                  return IconButton(
                                    icon: const Icon(
                                      Icons.menu,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                  );
                                },
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      color: AppColors.primaryLight,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Sri HR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        const Spacer(),
                        if (auth.kioskCompId.isNotEmpty)
                          // Exit button
                          GestureDetector(
                            onTap: () => _showExitDialog(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white54,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Clock ─────────────────────────────────────
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _amPm,
                          style: TextStyle(
                            color: AppColors.primaryLight.withOpacity(0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(),

                  // ── Centre fingerprint button ─────────────────
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _floatAnim,
                      _pulseCtrl,
                      _ringAngle,
                      _tapScale,
                    ]),
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value * 0.4),
                        child: ScaleTransition(
                          scale: _tapScale,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outermost pulse ring
                              Opacity(
                                opacity: _pulseOpacity.value,
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // Mid pulse ring
                              Opacity(
                                opacity: _pulseOpacity.value * 0.6,
                                child: Transform.scale(
                                  scale: _pulseScale.value * 0.88,
                                  child: Container(
                                    width: 240,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryLight,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Spinning dashed ring
                              Transform.rotate(
                                angle: _ringAngle.value,
                                child: CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _DashedCirclePainter(
                                    color: AppColors.primary.withOpacity(0.4),
                                    strokeWidth: 1.5,
                                    dashCount: 24,
                                  ),
                                ),
                              ),

                              // Solid inner glow ring
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.25),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 40,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                              ),

                              // Main tap button
                              GestureDetector(
                                onTap: _onMarkAttendance,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF4B6FE5),
                                        Color(0xFF2B4CC8),
                                        Color(0xFF1A3AAF),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.6,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.face_retouching_natural,
                                    size: 72,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // ── Label ─────────────────────────────────────
                  const Text(
                    'Mark Attendance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the icon to start face recognition',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const Spacer(),

                  // ── Bottom info strip ─────────────────────────
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• Good lighting required. Face must be clearly visible',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot({
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Log out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to Log out?',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

// ── Dashed circle painter ────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final dashAngle = 3.14159 * 2 / dashCount;
    final gapFraction = 0.45;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashCount != dashCount;
}
