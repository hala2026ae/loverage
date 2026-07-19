import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../authentication/domain/auth_repository_interface.dart';

final verificationVideoPathProvider = StateProvider<String?>((ref) => null);

class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  ConsumerState<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends ConsumerState<FaceVerificationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _recordedVideoPath;
  bool _isLoading = false;
  String _guideText = "Press Start Verification";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false, // No audio permission needed
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      // If camera setup fails (e.g. simulator), we proceed with a mock camera layout
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _elapsedSeconds = 0;
      _guideText = "Place your face in the circle";
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.startVideoRecording();
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds == 3) {
          _guideText = "Move closer";
        } else if (_elapsedSeconds >= 5) {
          timer.cancel();
          _stopRecording();
        }
      });
    });
  }

  void _stopRecording() async {
    XFile? videoFile;
    if (_cameraController != null &&
        _cameraController!.value.isRecordingVideo) {
      try {
        videoFile = await _cameraController!.stopVideoRecording();
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _recordedVideoPath = videoFile?.path ?? 'mock_verification_video.mp4';
      _guideText = "Done";
    });
  }

  Future<void> _submitVerification() async {
    if (_recordedVideoPath == null) return;

    ref.read(verificationVideoPathProvider.notifier).state = _recordedVideoPath;
    if (mounted) {
      context.go('/community-rules');
    }
  }

  void _retake() {
    setState(() {
      _recordedVideoPath = null;
      _elapsedSeconds = 0;
      _guideText = "Press Start Verification";
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = (screenWidth - 66.0).clamp(240.0, 330.0);
    final isFinished = _recordedVideoPath != null;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF3C1321),
          ),
          onPressed: () async {
            if (context.canPop()) {
              context.pop();
            } else {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            }
          },
        ),
        title: const Text(
          'Verification',
          style: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              )
            : Column(
                children: [
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                    color: const Color(0xFF5E0B24),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 12.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 1,
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.favorite_border_rounded,
                                color: Color(0xFFD4AF37),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 24,
                                height: 1,
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          const Text(
                            'Identity Verification',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 32.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3C1321),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          const Text(
                            'Start face verification and place your face inside the circle. The process is private and your verification will never be shown publicly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Color(0xFF9E9E9E),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24.0),

                          Expanded(
                            child: ClipPath(
                              clipper: BaroqueClipper(),
                              child: CustomPaint(
                                painter: BaroqueDarkFramePainter(
                                  showFill: true,
                                ),
                                foregroundPainter: BaroqueDarkFramePainter(
                                  showFill: false,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 1. Actual camera or simulated view filling the entire square
                                      if (_isCameraInitialized &&
                                          _cameraController != null)
                                        Positioned.fill(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .height,
                                              height: _cameraController!
                                                  .value
                                                  .previewSize!
                                                  .width,
                                              child: CameraPreview(
                                                _cameraController!,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        const Positioned.fill(
                                          child: Center(
                                            child: Text(
                                              'Camera Preview Mode',
                                              style: TextStyle(
                                                color: Color(0xFF7D686E),
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),

                                      // 2. Camera overlay mask: semi-transparent black overlay everywhere EXCEPT the circle
                                      if (_isCameraInitialized &&
                                          _cameraController != null)
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: CameraMaskPainter(
                                              circleSize: circleSize,
                                            ),
                                          ),
                                        ),

                                      // 3. Circular Viewport Guide & Text overlay
                                      IgnorePointer(
                                        child: Container(
                                          width: circleSize,
                                          height: circleSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _isRecording
                                                  ? const Color(0xFFCFF02B)
                                                  : const Color(
                                                      0xFFD4AF37,
                                                    ).withOpacity(0.6),
                                              width: 2.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Positioned(
                                                bottom: 24.0,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16.0,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _guideText,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28.0),

                          // Action button at the bottom
                          SizedBox(
                            width: double.infinity,
                            height: 56.0,
                            child: Opacity(
                              opacity: _isRecording ? 0.6 : 1.0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5E0B24),
                                      Color(0xFF3C1321),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28.0),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD4AF37,
                                    ).withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF3C1321,
                                      ).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isRecording
                                      ? null
                                      : (isFinished
                                            ? _submitVerification
                                            : _startRecording),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28.0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!isFinished && !_isRecording)
                                        Image.asset(
                                          'Assets/face verify.png',
                                          width: 28.0,
                                          height: 28.0,
                                          fit: BoxFit.contain,
                                        ),
                                      if (!isFinished && !_isRecording)
                                        const SizedBox(width: 8.0),
                                      Text(
                                        _isRecording
                                            ? 'Verification...'
                                            : (isFinished
                                                  ? 'Continue'
                                                  : 'Start Verification'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (isFinished)
                                        const SizedBox(width: 8.0),
                                      if (isFinished)
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white,
                                          size: 20.0,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (isFinished && !_isRecording) ...[
                            const SizedBox(height: 8.0),
                            TextButton(
                              onPressed: _retake,
                              child: const Text(
                                'Restart Verification',
                                style: TextStyle(
                                  color: Color(0xFF5E0B24),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 48.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class BaroqueDarkFramePainter extends CustomPainter {
  final bool showFill;
  BaroqueDarkFramePainter({this.showFill = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFF150A0E) // Dark burgundy fill
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
          .withOpacity(0.5) // gold outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;
    const r = 24.0; // corner radius/notch size
    const offset = 12.0; // corner inset offset

    // Notched path
    path.moveTo(offset + r, offset);
    path.lineTo(w - offset - r, offset);
    path.arcToPoint(
      Offset(w - offset, offset + r),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(w - offset, h - offset - r);
    path.arcToPoint(
      Offset(w - offset - r, h - offset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(offset + r, h - offset);
    path.arcToPoint(
      Offset(offset, h - offset - r),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(offset, offset + r);
    path.arcToPoint(
      Offset(offset + r, offset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.close();

    if (showFill) {
      // Draw shadow
      canvas.drawShadow(path, Colors.black.withOpacity(0.3), 12, true);

      // Draw fill
      canvas.drawPath(path, paint);
    }

    // Draw outer gold border
    canvas.drawPath(path, borderPaint);

    // Draw inner gold border
    final innerPath = Path();
    const inset = 4.0;
    innerPath.moveTo(offset + r + inset, offset + inset);
    innerPath.lineTo(w - offset - r - inset, offset + inset);
    innerPath.arcToPoint(
      Offset(w - offset - inset, offset + r + inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.lineTo(w - offset - inset, h - offset - r - inset);
    innerPath.arcToPoint(
      Offset(w - offset - r - inset, h - offset - inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.lineTo(offset + r + inset, h - offset - inset);
    innerPath.arcToPoint(
      Offset(offset + inset, h - offset - r - inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.lineTo(offset + inset, offset + r + inset);
    innerPath.arcToPoint(
      Offset(offset + r + inset, offset + inset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    innerPath.close();

    canvas.drawPath(innerPath, borderPaint..strokeWidth = 0.8);

    // Decorations paint
    final decPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;

    // 1. Fleur-de-lis Crest (Top center at cy = 35)
    final cx = w / 2;
    const cy = 35.0;

    // Left petal of fleur-de-lis
    final leftPetal = Path()
      ..moveTo(cx, cy + 10)
      ..cubicTo(cx - 10, cy + 5, cx - 12, cy - 2, cx - 8, cy - 5)
      ..cubicTo(cx - 4, cy - 8, cx, cy, cx, cy + 10);
    canvas.drawPath(leftPetal, fillPaint);

    // Right petal of fleur-de-lis
    final rightPetal = Path()
      ..moveTo(cx, cy + 10)
      ..cubicTo(cx + 10, cy + 5, cx + 12, cy - 2, cx + 8, cy - 5)
      ..cubicTo(cx + 4, cy - 8, cx, cy, cx, cy + 10);
    canvas.drawPath(rightPetal, fillPaint);

    // Center petal of fleur-de-lis (spearhead shape)
    final centerPetal = Path()
      ..moveTo(cx, cy - 12)
      ..quadraticBezierTo(cx - 5, cy, cx, cy + 12)
      ..quadraticBezierTo(cx + 5, cy, cx, cy - 12);
    canvas.drawPath(centerPetal, fillPaint);

    // Fleur-de-lis horizontal band
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 14.0, height: 2.5),
      fillPaint,
    );

    // Small star flanking fleur-de-lis
    canvas.drawCircle(Offset(cx - 16, cy + 5), 1.0, fillPaint);
    canvas.drawCircle(Offset(cx + 16, cy + 5), 1.0, fillPaint);

    // 2. Bottom Rose & Scroll (Centered at w/2, h - 30)
    final rx = w / 2;
    final ry = h - 30.0;

    canvas.drawCircle(Offset(rx, ry), 4.0, decPaint);
    canvas.drawCircle(Offset(rx, ry), 2.0, fillPaint);

    final petal1 = Path();
    petal1.addArc(
      Rect.fromCircle(center: Offset(rx, ry), radius: 6.0),
      0.0,
      3.14,
    );
    canvas.drawPath(petal1, decPaint);

    final petal2 = Path();
    petal2.addArc(
      Rect.fromCircle(center: Offset(rx, ry), radius: 8.0),
      3.14,
      3.14,
    );
    canvas.drawPath(petal2, decPaint);

    // Left scroll swirl
    final leftScroll = Path()
      ..moveTo(rx - 8, ry)
      ..quadraticBezierTo(rx - 30, ry - 10, rx - 55, ry)
      ..quadraticBezierTo(rx - 70, ry + 10, rx - 80, ry);
    canvas.drawPath(leftScroll, decPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx - 30, ry - 6), width: 6, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx - 55, ry + 2), width: 5, height: 3),
      fillPaint,
    );

    // Right scroll swirl
    final rightScroll = Path()
      ..moveTo(rx + 8, ry)
      ..quadraticBezierTo(rx + 30, ry - 10, rx + 55, ry)
      ..quadraticBezierTo(rx + 70, ry + 10, rx + 80, ry);
    canvas.drawPath(rightScroll, decPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx + 30, ry - 6), width: 6, height: 3),
      fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx + 55, ry + 2), width: 5, height: 3),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BaroqueClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    const r = 24.0;
    const offset = 12.0;

    path.moveTo(offset + r, offset);
    path.lineTo(w - offset - r, offset);
    path.arcToPoint(
      Offset(w - offset, offset + r),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(w - offset, h - offset - r);
    path.arcToPoint(
      Offset(w - offset - r, h - offset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(offset + r, h - offset);
    path.arcToPoint(
      Offset(offset, h - offset - r),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(offset, offset + r);
    path.arcToPoint(
      Offset(offset + r, offset),
      radius: const Radius.circular(r),
      clockwise: false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CameraMaskPainter extends CustomPainter {
  final double circleSize;
  CameraMaskPainter({required this.circleSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
          .withOpacity(0.55) // semi-transparent mask
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: circleSize / 2,
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CameraMaskPainter oldDelegate) {
    return oldDelegate.circleSize != circleSize;
  }
}
