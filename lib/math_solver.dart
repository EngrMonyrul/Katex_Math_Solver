import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:katex_flutter/katex_flutter.dart';

class MathSolver extends StatefulWidget {
  @override
  _MathSolverState createState() => _MathSolverState();
}

class _MathSolverState extends State<MathSolver> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late File _image;
  String _expression = '';
  String _result = '';

  @override
  void initState() {
    super.initState();
    // Get a list of available cameras
    availableCameras().then((cameras) {
      // Get a specific camera from the list
      final firstCamera = cameras.first;
      // Create a CameraController
      _controller = CameraController(
        // Get a specific camera from the list
        firstCamera,
        // Define the resolution to use
        ResolutionPreset.medium,
      );
      // Next, initialize the controller. This returns a Future
      _initializeControllerFuture = _controller.initialize();
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      // Ensure that the camera is initialized
      await _initializeControllerFuture;
      // Attempt to take a picture and get the file `image`
      final image = await _controller.takePicture();
      // If successful, set `_image` as `image`
      setState(() {
        _image = File(image.path);
      });
      // Recognize math expression from `_image`
      await _recognizeExpression();
    } catch (e) {
      // If an error occurs, log it
      print(e);
    }
  }

  Future<void> _pickImage() async {
    try {
      // Use ImagePicker class to select an image from the gallery
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      // If successful, set `_image` as `image`
      setState(() {
        _image = File(image!.path);
      });
      // Recognize math expression from `_image`
      await _recognizeExpression();
    } catch (e) {
      // If an error occurs, log it
      print(e);
    }
  }

  Future<void> _recognizeExpression() async {
    try {
      // Create a FirebaseVisionImage from `_image`
      final visionImage = FirebaseVisionImage.fromFile(_image);
      // Create an ImageLabeler from FirebaseVision
      final labeler = FirebaseVision.instance.imageLabeler();
      // Process the image and get a list of labels
      final labels = await labeler.processImage(visionImage);
      // Close the labeler when done
      labeler.close();
      // Find the label with the highest confidence score
      final bestLabel = labels.reduce((a, b) => a.confidence! > b.confidence! ? a : b);
      // Set `_expression` as the text of the best label
      setState(() {
        _expression = bestLabel.text!;
      });
      // Evaluate the expression and get the result
      await _evaluateExpression();
    } catch (e) {
      // If an error occurs, log it
      print(e);
    }
  }

  Future<void> _evaluateExpression() async {
    try {
      // Create a Parser from math_expressions package
      final parser = Parser();
      // Parse `_expression` into an Expression object
      final expression = parser.parse(_expression);
      // Create a ContextModel for evaluation
      final contextModel = ContextModel();
      // Evaluate the expression and get the result as a double
      final result = expression.evaluate(EvaluationType.REAL, contextModel);
      // Set `_result` as the string representation of the result
      setState(() {
        _result = result.toString();
      });
    } catch (e) {
      // If an error occurs, log it
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Math Solver')),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: _image == null
                    ? FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the Future is complete, display the preview
                      return CameraPreview(_controller);
                    } else {
                      // Otherwise, display a loading indicator
                      return CircularProgressIndicator();
                    }
                  },
                )
                    : Image.file(_image),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: _captureImage,
                ),
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  KaTeX(laTeXCode: Text(r'\(' + _expression + r'\)')),
                  KaTeX(laTeXCode: Text(r'\(' + _result + r'\)')),
                ],
              ),
            ),
          ],
        ));
  }
}
