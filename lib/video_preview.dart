import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:posecheck_datacollector/camera_helper/painters/pose_painter.dart';
import 'package:posecheck_datacollector/file_utils.dart';
import 'package:posecheck_datacollector/pose_model.dart';
import 'package:posecheck_datacollector/preview_button.dart';
import 'package:posecheck_datacollector/video_preview_helper.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  final String filePath;

  const VideoPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _VideoPageState createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoPlayerController;
  bool isVideoEnded = false;
  BodyPose? currentPose;
  late VideoSituation currentVideoSituation;
  bool upSelected = false;
  bool downSelected = false;
  int poseDrawingIdx = 0;
  late int maxPoseDrawingIdx;
  PosePainter? posePainter;
  late List<List<Pose>> poses;
  late List<Size?> sizes;
  late List<InputImageRotation?> rotations;
  late CameraLensDirection lensDirections = CameraLensDirection.front;
  late Timer posePlaybackTimer;
  List<Map<String, double>> exportData = List.empty(growable: true);
  final fileNameTextController = TextEditingController();

  @override
  void initState() {
    poses = context.read<PoseModel>().poses;
    sizes = context.read<PoseModel>().sizes;
    rotations = context.read<PoseModel>().rotations;
    // lensDirections = context.watch<PoseModel>().lensDirections;
    maxPoseDrawingIdx = poses.length;

    currentVideoSituation = VideoSituation.initializing;
    _videoPlayerController = VideoPlayerController.file(File(widget.filePath))
      ..initialize()
          // ..setLooping(true)
          // ..play()
          .then((_) => setState(() {}));

    _videoPlayerController.addListener(videoPlaybackCallback);
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    fileNameTextController.dispose();
    posePlaybackTimer.cancel();
    currentVideoSituation = VideoSituation.initializing;
    currentPose = null;
    super.dispose();
  }

  // Future _initVideoPlayer() async {
  //   _videoPlayerController = VideoPlayerController.file(File(widget.filePath));
  //   await _videoPlayerController.initialize();
  //   await _videoPlayerController.setLooping(true);
  //   await _videoPlayerController.play();
  // }

  void videoPlaybackCallback() {
    // Implement your calls inside these conditions' bodies :
    // if (_videoPlayerController.value.position ==
    //     Duration(seconds: 0, minutes: 0, hours: 0)) {
    //   setState(() {
    //     _isPlaying = true;
    //   });
    //   print('video Started');
    // }

    // if (_videoPlayerController.value.position ==
    //     _videoPlayerController.value.duration) {
    //   setState(() {
    //     isVideoEnded = true;
    //   });
    //   print('video Ended');
    // }
  }

  void posePlaybackDataAdder(Timer? timer) {
    final frameSize = sizes[poseDrawingIdx];
    final framePose = poses[poseDrawingIdx];
    final frameRotation = rotations[poseDrawingIdx];

    if (frameSize != null && frameRotation != null && framePose.isNotEmpty) {
      posePainter =
          PosePainter(framePose, frameSize, frameRotation, lensDirections);
      framePose.forEach(
        (frame) {
          Map<String, double> localExportPoseData = {};
          frame.landmarks.forEach(
            (landmarkType, landmarkValue) {
              localExportPoseData["${landmarkType.name}_x"] = landmarkValue.x;
              localExportPoseData["${landmarkType.name}_y"] = landmarkValue.y;
              localExportPoseData["${landmarkType.name}_z"] = landmarkValue.z;
            },
          );
          localExportPoseData["position"] = currentPose! == BodyPose.up ? 1 : 0;
          exportData.add(localExportPoseData);
        },
      );
    } else {
      posePainter = null;
    }

    if (currentVideoSituation == VideoSituation.playing) {
      poseDrawingIdx++;
      if (poseDrawingIdx >= maxPoseDrawingIdx) {
        isVideoEnded = true;
        poseDrawingIdx = 0;
        videoEndedProcedure();
        restartVideo();
        setState(() {});
        if (timer != null) timer.cancel();
      }
      setState(() {});
    }
  }

  void playVideo() {
    _videoPlayerController.play();
    currentVideoSituation = VideoSituation.playing;

    posePlaybackDataAdder(null);

    ///
    posePlaybackTimer = Timer.periodic(
      const Duration(milliseconds: 87),
      (timer) {
        posePlaybackDataAdder(timer);
      },
    );

    ///
    setState(() {});
  }

  void pauseVideo() {
    _videoPlayerController.pause();
    currentVideoSituation = VideoSituation.paused;

    posePlaybackTimer.cancel();
    setState(() {});
  }

  void restartVideo() {
    _videoPlayerController.seekTo(
      const Duration(seconds: 0, minutes: 0, hours: 0),
    );

    currentVideoSituation = VideoSituation.initializing;
    isVideoEnded = false;
    poseDrawingIdx = 0;
    currentPose = null;
    upSelected = false;
    downSelected = false;
    posePainter = null;
    setState(() {});
  }

  void clickedOnPoseButton(BodyPose poseSelected) {
    currentPose = poseSelected;
    if (currentVideoSituation == VideoSituation.initializing) {
      currentVideoSituation = VideoSituation.playing;
      playVideo();
    }
    if (poseSelected == BodyPose.up) {
      upSelected = true;
      downSelected = false;
    } else {
      downSelected = true;
      upSelected = false;
    }

    setState(() {});
  }

  void videoEndedProcedure() {
    print("tamoom");
    List<List<dynamic>> rows = [];
    rows.add(exportData.first.keys.toList());
    rows.addAll(exportData.map((map) => map.values.toList()));
    String csvData = const ListToCsvConverter().convert(rows);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: TextField(
          controller: fileNameTextController,
          decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            labelText: 'Enter the file name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }, // function used to perform after pressing the button
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Save file
              final fileName =
                  "${fileNameTextController.text}_${DateTime.now()}.csv";
              File file = await FileUtils.localFile(fileName);
              file.writeAsString(csvData);
              // Save file name
              final fileList = await FileUtils.getFileList();
              fileList.add(fileName);
              await FileUtils.saveFileList(fileList);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        backgroundColor: Colors.orangeAccent[300],
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.check),
        //     onPressed: () {
        //       print('do something with the file');
        //     },
        //   )
        // ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: RotatedBox(
                  quarterTurns: -1,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: SizedBox(
                        height: mq.size.height * 2 / 3,
                        width: double.infinity,
                        child: VideoPlayer(_videoPlayerController)),
                  ),
                ),
              ),
              if (posePainter != null)
                Positioned(
                  top: 10,
                  child: Center(
                    child: SizedBox(
                      width: mq.size.width * 2 / 3,
                      height: mq.size.height * 2 / 3,
                      child: CustomPaint(
                        painter: posePainter,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                child: Container(
                  width: mq.size.width,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                  child: Column(
                    children: [
                      if (currentVideoSituation == VideoSituation.playing)
                        Container(
                          padding: const EdgeInsets.all(5),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.7),
                          ),
                          child: IconButton(
                            onPressed: pauseVideo,
                            icon: const Icon(Icons.pause),
                            padding: const EdgeInsets.all(10),
                            iconSize: 30,
                            color: Colors.white,
                          ),
                        ),
                      if (currentVideoSituation == VideoSituation.paused)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              child: IconButton(
                                onPressed: restartVideo,
                                icon: const Icon(Icons.replay),
                                padding: const EdgeInsets.all(10),
                                iconSize: 30,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              child: IconButton(
                                onPressed: playVideo,
                                icon: const Icon(Icons.play_arrow),
                                padding: const EdgeInsets.all(10),
                                iconSize: 30,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PreviewButtonDirection(
                            text: "Down",
                            onPressed: clickedOnPoseButton,
                            poseSelected: BodyPose.down,
                            isSelected: downSelected,
                          ),
                          PreviewButtonDirection(
                            text: "Up",
                            onPressed: clickedOnPoseButton,
                            poseSelected: BodyPose.up,
                            isSelected: upSelected,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (currentVideoSituation == VideoSituation.initializing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Positioned(
                      child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.orangeAccent.withOpacity(0.8)),
                    child: const Text(
                      "Please Select an initial position of body to begin the playback.",
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  )),
                ),
              if (currentPose != null &&
                  currentVideoSituation == VideoSituation.playing)
                Positioned(
                  top: 20,
                  child: SafeArea(
                    child: Container(
                      child: Text("Current State is ${currentPose!.name}"),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
