import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef void QRViewCreatedCallback(QRViewController controller);

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,
    this.overlay,
  })  : assert(key != null),
        assert(onQRViewCreated != null),
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  final ShapeBorder overlay;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        widget.overlay != null
            ? Container(
                decoration: ShapeDecoration(
                  shape: widget.overlay,
                ),
              )
            : Container(),
      ],
    );
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'net.touchcapture.qr.flutterqr/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) {
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(QRViewController._(id, widget.key));
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  static const scanMethodCall = "onRecognizeQR";

  final MethodChannel _channel;

  StreamController<String> _scanUpdateController = StreamController<String>();
  StreamController<String> _scanUpdatePoint = StreamController<String>();
  StreamController<String> _scanUpdateTransformedPoint = StreamController<String>();
  StreamController<String> _framingRectController = StreamController<String>();
  StreamController<String> _cameraWidthUpdateController = StreamController<String>();
  StreamController<String> _cameraHeightUpdateController = StreamController<String>();
  StreamController<String> _bitMatrixController = StreamController<String>();
  StreamController<String> _bitmapController = StreamController<String>();
  StreamController<String> _bitmapWithResultPointsController = StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;
  Stream<String> get scannedResultPoints => _scanUpdatePoint.stream;
  Stream<String> get scannedTransformedResultPoints => _scanUpdateTransformedPoint.stream;
  Stream<String> get framingRectStream => _framingRectController.stream;
  Stream<String> get updatedCameraWidth => _cameraWidthUpdateController.stream;
  Stream<String> get updatedCameraHeight => _cameraHeightUpdateController.stream;
  Stream<String> get bitMatrix => _bitMatrixController.stream;
  Stream<String> get bitmap => _bitmapController.stream;
  Stream<String> get bitmapWithResultPoints => _bitmapWithResultPointsController.stream;

  QRViewController._(int id, GlobalKey qrKey)
      : _channel = MethodChannel('net.touchcapture.qr.flutterqr/qrview_$id') {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext.findRenderObject();
      _channel.invokeMethod("setDimensions",
          {"width": renderBox.size.width, "height": renderBox.size.height});
    }
    _channel.setMethodCallHandler(
      (MethodCall call) async {
        switch (call.method) {
          case scanMethodCall:
            if (call.arguments != null) {
              _scanUpdateController.sink.add(call.arguments.toString());
            }
            break;

            case "onResultPoints":
              _scanUpdatePoint.sink.add(call.arguments.toString());
              break;

            case "onTransformedResultPoints":
              _scanUpdateTransformedPoint.sink.add(call.arguments.toString());
              break;
            
            case "onFramingRect":
              _framingRectController.sink.add(call.arguments.toString());
              break;
            
            case "onCameraWidthUpdated":
              _cameraWidthUpdateController.sink.add(call.arguments.toString());
              break;
            
            case "onCameraHeightUpdated":
              _cameraHeightUpdateController.sink.add(call.arguments.toString());
              break;
            
            case "onBitMatrix":
              _bitMatrixController.sink.add(call.arguments.toString());
              break;

            case "onBitmap":
              _bitmapController.sink.add(call.arguments.toString());
              break;
              
            case "onBitmapWithResultPoints":
              _bitmapWithResultPointsController.sink.add(call.arguments.toString());
              break;
            
            case "onQRLuminanceSourceWidth":
              print('WIDTH: ${call.arguments.toString()}');
              break;
              
            case "onQRLuminanceSourceHeight":
              print('HEIGHT: ${call.arguments.toString()}');
              break;
        }
      },
    );
  }

  void flipCamera() {
    _channel.invokeMethod("flipCamera");
  }

  void toggleFlash() {
    _channel.invokeMethod("toggleFlash");
  }

  void pauseCamera() {
    _channel.invokeMethod("pauseCamera");
  }

  void resumeCamera() {
    _channel.invokeMethod("resumeCamera");
  }

  void dispose() {
    _scanUpdateController.close();
  }
}
