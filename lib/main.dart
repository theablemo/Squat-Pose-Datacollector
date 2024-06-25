import 'dart:async';

import 'package:flutter/material.dart';
import 'package:posecheck_datacollector/camera_helper/camera_model.dart';
import 'package:posecheck_datacollector/file_explorer_page.dart';
import 'package:posecheck_datacollector/pose_model.dart';
import 'package:posecheck_datacollector/pose_detector.dart';
import 'package:posecheck_datacollector/video_preview.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CameraModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => PoseModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Pose Checker Data Collector',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Pose Checker Data Collector'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late bool recording;
  late bool preparingToRecord;
  int startRecordingCounter = 3;
  // late CameraController _cameraController;

  // void _initCamera() async {
  //   final cameras = await availableCameras();
  //   final front = cameras.firstWhere(
  //       (camera) => camera.lensDirection == CameraLensDirection.front);
  //   _cameraController = CameraController(front, ResolutionPreset.max);
  //   await _cameraController.initialize();
  //   // setState(() => _isLoading = false);
  // }

  @override
  void initState() {
    recording = false;
    preparingToRecord = false;
    // _initCamera();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const PoseDetectorView(),
          preparingToRecord
              ? Center(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.black.withOpacity(0.8),
                    ),
                    child: Text(
                      startRecordingCounter.toString(),
                      style: const TextStyle(
                        fontSize: 50,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
          Positioned(
            bottom: 35,
            child: InkWell(
              onTap: () => _startRecording(context),
              child: Container(
                // color: Colors.red,
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: recording ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: recording ? BorderRadius.circular(10) : null,
                  color: Colors.red,
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FileListPage(),
            ),
          );
        },
        tooltip: 'Increment',
        isExtended: true,
        splashColor: Theme.of(context).splashColor,
        child: const Icon(Icons.folder_outlined),
      ),
    );
  }

  void _startRecording(BuildContext context) async {
    final cameraController = context.read<CameraModel>().controller!;

    if (recording) {
      final file = await cameraController.stopVideoRecording();
      // print("path in ast" + file.path);
      // final path = await getExternalDocumentPath();
      // print("save mikonim " + path);
      // File filef = File(file.path);
      // filef.copy(path + "/posecheck.mp4");
      context.read<CameraModel>().startLiveFeed();
      setState(() => recording = false);
      final route = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPage(filePath: file.path),
      );
      Navigator.push(context, route);
    } else {
      context.read<PoseModel>().resetAll();
      setState(() {
        preparingToRecord = true;
      });
      Timer.periodic(
        const Duration(seconds: 1),
        (timer) async {
          setState(() {
            startRecordingCounter--;
          });

          if (startRecordingCounter == 0) {
            startRecordingCounter = 3;
            timer.cancel();
            await cameraController.prepareForVideoRecording();
            context.read<CameraModel>().startVideoRecording();
            setState(() {
              preparingToRecord = false;
              recording = true;
            });
          }
        },
      );
    }
  }
}
