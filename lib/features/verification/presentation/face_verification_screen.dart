import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import '../../../app/theme/app_theme.dart';
import '../../authentication/domain/auth_repository_interface.dart';

class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  ConsumerState<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  int _countdownSeconds = 5;
  Timer? _timer;
  String? _recordedVideoPath;
  bool _isLoading = false;

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
      _countdownSeconds = 5;
    });

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.startVideoRecording();
      } catch (e) {
        debugPrint('Error starting video recording: $e');
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdownSeconds == 1) {
        timer.cancel();
        _stopRecording();
      } else {
        setState(() {
          _countdownSeconds--;
        });
      }
    });
  }

  void _stopRecording() async {
    XFile? videoFile;
    if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
      try {
        videoFile = await _cameraController!.stopVideoRecording();
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
      }
    }

    setState(() {
      _isRecording = false;
      _recordedVideoPath = videoFile?.path ?? 'mock_verification_video.mp4';
    });
  }

  Future<void> _submitVerification() async {
    if (_recordedVideoPath == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // 1. Submit video and progress state to verification_pending
      await ref.read(authRepositoryProvider).submitFaceVerification(_recordedVideoPath!);
      
      // 2. Navigate to rules acceptance before locking user into verification-pending screen
      if (mounted) {
        context.go('/community-rules');
      }
    } catch (_) {}
    
    setState(() => _isLoading = false);
  }

  void _retake() {
    setState(() {
      _recordedVideoPath = null;
      _countdownSeconds = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDarkBurgundy,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentRoseGold))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  const Text(
                    'Identity Verification',
                    style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Record a short 5-second video holding your face in the guide. This is confidential and never shown publicly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.0, color: Colors.white70),
                  ),
                  const SizedBox(height: 32.0),
                  
                  // Camera / Preview Container
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.l),
                      child: Container(
                        width: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Actual camera or simulated view
                            if (_recordedVideoPath != null)
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.video_collection_outlined, size: 64.0, color: AppColors.accentRoseGold),
                                    SizedBox(height: 16.0),
                                    Text('Video captured successfully', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              )
                            else if (_isCameraInitialized && _cameraController != null)
                              CameraPreview(_cameraController!)
                            else
                              const Center(
                                child: Text(
                                  'Camera Preview Mode',
                                  style: TextStyle(color: Colors.white30, fontSize: 16.0),
                                ),
                              ),
                            
                            // 2. Circular Guide Overlay
                            if (_recordedVideoPath == null)
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _isRecording ? const Color(0xFFCFF02B) : AppColors.accentRoseGold.withOpacity(0.5),
                                    width: 3.0,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                margin: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
                              ),
                            
                            // 3. Timer text overlay
                            if (_isRecording)
                              Positioned(
                                top: 20.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Text(
                                    'Recording: $_countdownSeconds s',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32.0),
                  
                  // Action buttons at the bottom
                  if (_recordedVideoPath != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _retake,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            child: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitVerification,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentRoseGold,
                              foregroundColor: AppColors.primaryDarkBurgundy,
                            ),
                            child: const Text('Submit Verification'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    FilledButton(
                      onPressed: _isRecording ? null : _startRecording,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCFF02B),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: Text(_isRecording ? 'Recording...' : 'Start Verification'),
                    ),
                  ],
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
      ),
    );
  }
}
