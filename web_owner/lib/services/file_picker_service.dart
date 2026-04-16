import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';

/// Ergebnis einer Dateiauswahl
class FilePickerResult {
  final Uint8List bytes;
  final String name;

  const FilePickerResult({required this.bytes, required this.name});
}

/// Service für Dateiauswahl im Browser
class FilePickerService {
  /// Bild-Datei auswählen (Web-Implementierung)
  static Future<FilePickerResult?> pickImage() async {
    final completer = Completer<FilePickerResult?>();

    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp,image/gif'
      ..click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(FilePickerResult(
            bytes: result,
            name: file.name,
          ));
        } else {
          completer.complete(null);
        }
      });

      reader.onError.listen((_) => completer.complete(null));
      reader.readAsArrayBuffer(file);
    });

    // Falls der Dialog abgebrochen wird
    // Timeout als Fallback
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => null,
    );
  }
}
