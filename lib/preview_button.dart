import 'package:flutter/material.dart';
import 'package:posecheck_datacollector/video_preview_helper.dart';

class PreviewButtonDirection extends StatelessWidget {
  final String text;
  final bool isSelected;
  final Function(BodyPose bodyPose) onPressed;
  final BodyPose poseSelected;

  const PreviewButtonDirection({
    super.key,
    required this.text,
    this.isSelected = false,
    required this.onPressed,
    required this.poseSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return SizedBox(
      width: mq.size.width * 0.47,
      height: 130,
      child: ElevatedButton(
        onPressed: () => onPressed(poseSelected),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          backgroundColor: isSelected ? Colors.blueGrey[100] : Colors.blueGrey,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 25,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
