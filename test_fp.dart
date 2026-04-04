import 'package:file_picker/file_picker.dart';

void main() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'm4a', 'wav'],
  );
  print(result);
}
