// html_stub.dart — used on non-web platforms instead of dart:html
// Provides minimal stubs so dart:html-referencing code compiles on mobile.

class MediaRecorder {
  MediaRecorder(dynamic stream, [dynamic options]);
  void start() {}
  void stop() {}
  void addEventListener(String type, dynamic listener) {}
}

class MediaStream {
  List<MediaStreamTrack> getTracks() => [];
}

class MediaStreamTrack {
  void stop() {}
}

class BlobEvent {
  Blob? get data => null;
}

class Blob {
  int get size => 0;
  Blob(List<dynamic> parts, [String? type]);
}
