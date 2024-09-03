import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_auth_flutter/face_auth/face_recognition/image_converter.dart';
import 'package:flutter/material.dart';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:lottie/lottie.dart';
import '../../utils/utils.dart';
import '../../widgets/common_widgets.dart';
import 'ml_service.dart';

enum CameraType { front, back }

enum ScanType { register, authenticate }

class FaceScanScreen extends StatefulWidget {
  final CameraType cameraType;
  final ScanType scanType;

  const FaceScanScreen(
      {Key? key, required this.cameraType, required this.scanType})
      : super(key: key);

  @override
  _FaceScanScreenState createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  late CameraController _cameraController;

  bool flash = false;

  bool isControllerInitialized = false;

  late FaceDetector _faceDetector;

  final MLService _mlService = MLService();

  List<CameraDescription>? cameras;

  List<Face> facesDetected = [];

  Future initializeCamera() async {
    //

    cameras = await availableCameras();

    _cameraController = CameraController(
      cameras![widget.cameraType == CameraType.front ? 1 : 0],
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    await _cameraController.initialize();

    isControllerInitialized = true;

    _cameraController.setFlashMode(FlashMode.off);

    setState(() {});

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
  }

  @override
  dispose() {
    //

    _mlService.disposeResources();
    cameras!.clear();
    facesDetected.clear();
    _cameraController.dispose();
    _faceDetector.close();

    dp("Dispose controllers", "");

    super.dispose();
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> detectFacesFromImage(CameraImage image) async {
    var _firebaseImageMetadata = InputImageMetadata(
        rotation: rotationIntToImageRotation(
            _cameraController.description.sensorOrientation),
        format: InputImageFormat.bgra8888,
        size: Size(image.width.toDouble(), image.height.toDouble()),
        bytesPerRow: image.planes.first.bytesPerRow);

    InputImage _firebaseVisionImage = InputImage.fromBytes(
      bytes: Uint8List.fromList(
        image.planes.fold(
            <int>[],
            (List<int> previousValue, element) =>
                previousValue..addAll(element.bytes)),
      ),
      metadata: _firebaseImageMetadata,
    );

    var result = await _faceDetector.processImage(_firebaseVisionImage);

    if (result.isNotEmpty) {
      facesDetected = result;
    }
  }

  Future<void> _predictFacesFromImage({required CameraImage image}) async {
    await detectFacesFromImage(image);

    if (facesDetected.isNotEmpty) {
      //

      dp("Detected faces", facesDetected.length);

      await stopCamera();

      setState(() {});

      // final imageBytes = convertToImage(image);

      // final Uint8List imageBytesC =
      //     Uint8List.fromList(img.encodePng(imageBytes!));
      // await showDialog(
      //   builder: (context) {
      //     return Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: [
      //         const Text("First image UI"),
      //         Center(
      //           child: Image.memory(imageBytesC),
      //         ),
      //         Material(
      //           child: MaterialButton(
      //             onPressed: () {
      //               Navigator.pop(context);
      //             },
      //             child: const Text("OK"),
      //           ),
      //         )
      //       ],
      //     );
      //   },
      //   context: context,
      // );

      double? dist = await _mlService.predict(
        image,
        facesDetected[0],
        widget.scanType,
        context,
        widget.cameraType == CameraType.back,
      );

      //

      setState(() {});

      dp("Navigator is pop", "");

      Navigator.pop(context, dist);
      return;
    } else {
      setState(() {});
      dp("Take picture", "");
      await takePicture();
    }
  }

  Future<void> takePicture() async {
    try {
      if (facesDetected.isNotEmpty) {
        await _cameraController.stopImageStream();
        _cameraController.setFlashMode(FlashMode.off);
      } else {
        showDialog(
            context: context,
            builder: (context) =>
                const AlertDialog(content: Text('No face detected!')));
      }
    } catch (e, s) {
      dp("Error in $e", s);
    }
  }

  Future<void> stopCamera() async {
    try {
      dp("Stop view", "arg");
      await _cameraController.stopImageStream();
      await _cameraController.takePicture();
      await _cameraController.pausePreview();
      _cameraController.setFlashMode(FlashMode.off);
    } catch (e, s) {
      dp("Error in $e", s);
    }
  }

  @override
  void initState() {
    initializeCamera();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: isControllerInitialized
                    ? CameraPreview(_cameraController)
                    : null),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: widget.scanType == ScanType.register
                          ? Image.asset("assets/svgviewer-outputh.png")
                          : Lottie.asset("assets/loading.json",
                              width: MediaQuery.of(context).size.width * 0.7),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: CWidgets.customExtendedButton(
                            text: "Capture",
                            context: context,
                            isClickable: true,
                            onTap: () {
                              //

                              bool canProcess = false;

                              setState(() {});

                              _cameraController
                                  .startImageStream((CameraImage image) async {
                                //

                                if (canProcess) return;

                                canProcess = true;

                                setState(() {});

                                _predictFacesFromImage(image: image)
                                    .then((value) {
                                  //

                                  canProcess = false;
                                  setState(() {});
                                });

                                return;
                              });
                            }),
                      ),
                      IconButton(
                          icon: Icon(
                            flash ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              flash = !flash;
                            });
                            flash
                                ? _cameraController
                                    .setFlashMode(FlashMode.torch)
                                : _cameraController.setFlashMode(FlashMode.off);
                          }),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
