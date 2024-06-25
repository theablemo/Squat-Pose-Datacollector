import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:posecheck_datacollector/camera_helper/camera_model.dart';
import 'package:posecheck_datacollector/camera_helper/camera_view.dart';
import 'package:posecheck_datacollector/pose_model.dart';
import 'package:provider/provider.dart';

import 'camera_helper/painters/pose_painter.dart';

class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({super.key});

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  late String? _text;
  var _cameraLensDirection = CameraLensDirection.front;

  @override
  void dispose() async {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      CameraView(
        customPaint: _customPaint,
        onImage: _processImage,
      ),
      // Positioned(child: Text(posesGlobal[1].), top: 10, left: 10),
    ]);
    // return DetectorView(
    //   title: 'Pose Detector',
    //   customPaint: _customPaint,
    //   text: _text,
    //   onImage: _processImage,
    //   initialCameraLensDirection: _cameraLensDirection,
    //   onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    // );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final poses = await _poseDetector.processImage(inputImage);

    // print("time is " + DateTime.now().toString());

    final cameraController = context.read<CameraModel>().controller!;
    if (cameraController.value.isRecordingVideo) {
      context.read<PoseModel>().addPose(poses);
      context.read<PoseModel>().addSize(inputImage.metadata?.size);
      context.read<PoseModel>().addRotation(inputImage.metadata?.rotation);
      // context.read<PoseModel>().addLensDirection(_cameraLensDirection);
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null &&
        poses.isNotEmpty) {
      poses.forEach((p) => print("pose ${p.landmarks}"));

      final painter = PosePainter(
        poses,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _text = 'Poses found: ${poses.length}\n\n';
      // TODO: set _customPaint to draw landmarks on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
