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

  final MethodChannel _channel;

  StreamController<String> _scanStringController = StreamController<String>();
  StreamController<String> _scanResultPoints = StreamController<String>();
  StreamController<String> _previewFramingRectController = StreamController<String>();
  StreamController<String> _bitMatrixController = StreamController<String>();
  StreamController<String> _bitmapController = StreamController<String>();

  Stream<String> get scannedString => _scanStringController.stream;
  Stream<String> get scannedResultPoints => _scanResultPoints.stream;
  Stream<String> get previewFramingRectStream => _previewFramingRectController.stream;
  Stream<String> get bitMatrix => _bitMatrixController.stream;
  Stream<String> get bitmap => _bitmapController.stream;

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
          case "onRecognizeQRString":
            if (call.arguments != null)
              _scanStringController.sink.add(call.arguments.toString());
            break;

            case "onRecognizeQRResultPoints":
              if (call.arguments != null)
                _scanResultPoints.sink.add(call.arguments.toString());
              break;
            
            case "onRecognizeQRPreviewFramingRect":
              if (call.arguments != null)
                _previewFramingRectController.sink.add(call.arguments.toString());
              break;
            
            case "onRecognizeQRBitMatrix":
              if (call.arguments != null)
                _bitMatrixController.sink.add(call.arguments.toString());
              break;

            case "onRecognizeQRBitmap":
              if (call.arguments != null)
                _bitmapController.sink.add(call.arguments.toString());
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
    _scanStringController.close();
    _scanResultPoints.close();
    _previewFramingRectController.close();
    _bitMatrixController.close();
    _bitmapController.close();
  }
}
