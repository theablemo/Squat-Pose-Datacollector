import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseModel extends ChangeNotifier {
  List<List<Pose>> poses = List.empty(growable: true);
  List<Size?> sizes = List.empty(growable: true);
  List<InputImageRotation?> rotations = List.empty(growable: true);
  // List<CameraLensDirection?> lensDirections = List.empty(growable: true);

  void addPose(List<Pose> poses) {
    this.poses.add(poses);
    notifyListeners();
  }

  void addSize(Size? size) {
    sizes.add(size);
    notifyListeners();
  }

  void addRotation(InputImageRotation? rotation) {
    rotations.add(rotation);
    notifyListeners();
  }

  // void addLensDirection(CameraLensDirection lensDirection) {
  //   lensDirections.add(lensDirection);
  //   notifyListeners();
  // }

  void resetAll() {
    poses.clear();
    sizes.clear();
    rotations.clear();
    // lensDirections.clear();
  }
}
