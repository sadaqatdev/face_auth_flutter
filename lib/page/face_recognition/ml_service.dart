import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_auth_flutter/page/face_recognition/camera_page.dart';
import 'package:face_auth_flutter/utils/local_db.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import '../../../models/user.dart';
import '../../utils/utils.dart';
import 'image_converter.dart';

class MLService {
  Interpreter? interpreter;
  Delegate? delegate;

  void disposeResources() {
    //

    interpreter?.close();
    delegate?.delete();

    dp("Dispose resources", "interpreter");
  }

  Future<double?> predict(CameraImage cameraImage, Face face, ScanType scanType,
      context, bool isBack) async {
    //

    List input = await _preProcess(cameraImage, face, context, isBack);

    input = input.reshape([1, 112, 112, 3]);

    List output = List.generate(1, (index) => List.filled(192, 0));

    await initializeInterpreter(context);

    interpreter!.run(input, output);

    output = output.reshape([192]);

    List? predictedArray = List.from(output);

    if (scanType == ScanType.register) {
      await HiveBoxes.clearAllBox();
      LocalDB.setUserDetails(User(name: "name", array: predictedArray));
      return null;
    } else {
      User? user = LocalDB.getUser();

      List userArray = user.array!;

      var dist = euclideanDistance(predictedArray, userArray);

      dp("Match s", dist);

      return dist;
    }
  }

  euclideanDistance(List l1, List l2) {
    double sum = 0;
    for (int i = 0; i < l1.length; i++) {
      sum += pow((l1[i] - l2[i]), 2);
    }

    return pow(sum, 0.5);
  }

  initializeInterpreter(context) async {
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
          // inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
          // inferencePriority1: TfLiteGpuInferencePriority
          //     .TFLITE_GPU_INFERENCE_PRIORITY_MAX_PRECISION,
          // inferencePriority2: TfLiteGpuInferencePriority.auto,
          // inferencePriority3: TfLiteGpuInferencePriority.auto,
        ));
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
              allowPrecisionLoss: true,
              // waitType: TFLGpuDelegateWaitType.active,
              waitType: 1),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate!);

      interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e, s) {
      dp('Failed to load model $e', s);
    }
  }

  Future<List> _preProcess(
      CameraImage image, Face faceDetected, context, bool isBack) async {
    imglib.Image croppedImage =
        await _cropFace(image, faceDetected, context, isBack);

    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, size: 112);

    // final Uint8List imageBytes = Uint8List.fromList(imglib.encodePng(img));

    // await showDialog(
    //   builder: (context) {
    //     return Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         const Text("First image UI"),
    //         Center(
    //           child: Image.memory(
    //             imageBytes,
    //             height: 100,
    //           ),
    //         ),
    //         Material(
    //           child: MaterialButton(
    //             onPressed: () {
    //               Navigator.pop(context);
    //             },
    //             child: Text("OK"),
    //           ),
    //         )
    //       ],
    //     );
    //   },
    //   context: context,
    // );

    Float32List imageAsList = _imageToByteListFloat32(img);

    return imageAsList;
  }

  Uint8List float32ListToUint8List(Float32List float32List) {
    // Create a Uint8List with the same length as Float32List
    final Uint8List uint8List = Uint8List(float32List.length);

    // Iterate through the Float32List and convert each value to Uint8
    for (int i = 0; i < float32List.length; i++) {
      // Convert the float value to the range 0-255
      int value = (float32List[i] * 255).clamp(0, 255).toInt();
      uint8List[i] = value;
    }

    return uint8List;
  }

  Future<imglib.Image> _cropFace(
      CameraImage image, Face faceDetected, context, bool isBack) async {
    imglib.Image convertedImage = _convertCameraImage(image, isBack);

    // final Uint8List imageBytes =
    //     Uint8List.fromList(imglib.encodePng(convertedImage));

    // await showDialog(
    //   builder: (context) {
    //     return Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         const Text("First image UI"),
    //         Center(
    //           child: Image.memory(imageBytes, height: 300),
    //         ),
    //         Material(
    //           child: MaterialButton(
    //             onPressed: () {
    //               Navigator.pop(context);
    //             },
    //             child: Text("OK"),
    //           ),
    //         )
    //       ],
    //     );
    //   },
    //   context: context,
    // );

    double x = faceDetected.boundingBox.left + 3;
    double y = faceDetected.boundingBox.top;

    double w = faceDetected.boundingBox.width;
    double h = faceDetected.boundingBox.height + 10.0;

    return imglib.copyCrop(convertedImage,
        x: x.round(), y: y.round(), width: w.round(), height: h.round());
  }

  imglib.Image _convertCameraImage(CameraImage image, bool isBack) {
    var img = convertToImage(image);

    var img1 = imglib.copyRotate(img!, angle: isBack ? 90 : -90);

    return img1;
  }

  Float32List _imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);

        buffer[pixelIndex++] = (pixel.r - 128) / 128;
        buffer[pixelIndex++] = (pixel.g - 128) / 128;
        buffer[pixelIndex++] = (pixel.b - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
