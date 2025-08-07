import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart' as path_provider;
// import 'package:video_compress/video_compress.dart';

Future<String?> getSignedUploadUrl(String filename) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("generateSignedUploadUrl");

  try {
    debugPrint("FileName in getSignedUploadUrl: $filename");
    final response = await function.call({'fileName': filename});
    debugPrint('Signed URL: ${response.data['url']}');
    return response.data['url'];
  } catch (e) {
    debugPrint('Failed to get signed url with error: $e');
    return null;
  }
}

Future<String?> getSignedDownloadUrl(String fileName) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("generateSignedDownloadUrl");

  try {
    debugPrint("FileName in getSignedDownloadUrl: $fileName");
    final response = await function.call({'fileName': fileName});
    debugPrint('Signed URL: ${response.data['url']}');
    return response.data['url'];
  } catch (e) {
    debugPrint('Failed to get signed url with error: $e');
    return null;
  }
}

Future<String> selectFile(TextEditingController fileTextController) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.video,
  );

  if (result != null && result.files.single.path != null) {
    File file = File(result.files.single.path!);
    int fileSizeInBytes = await file.length();
    double fileSizeMb = fileSizeInBytes / (1024 * 1024);

    if (fileSizeMb > 5) {
      return "Sorry! That file is to big, consider shortening the video.";
    }
    fileTextController.text = result.files.single.path!;

    debugPrint("File picked: $fileTextController.text");
    return file.path;
  }

  //the user didnt select a file
  return "Please select a 'mp4' file.";
}

// TODO: make this funciton return true or false depending on whether the file was uploaded successfully.
//  We should also consider throwing errors or logging for failures.
// TODO: consider compressing the video before uploading it to save space and bandwidth.
Future<bool> uploadVideo(String filePath) async {
  try {
    debugPrint("File for signed url: $filePath");
    //final compressed = await compressVideo(filePath) as List<int>;

    var signedUrl = await getSignedUploadUrl(path.basename(filePath));
    final File file = File(filePath);

    if (signedUrl != null /*&&  compressed.isNotEmpty */) {
      final request = http.Request('PUT', Uri.parse(signedUrl))
        ..headers['Content-Type'] = 'video/mp4' // Set the correct MIME type
        ..bodyBytes = /* compressed; */ await file.readAsBytes()
        ..headers['Content-Length'] = (await file.length()).toString();

      final response = await request.send();

      if (response.statusCode == 200) {
        debugPrint('File uploaded successfully!');
        return true; // Indicate success
      } else {
        debugPrint('Failed to upload file: ${response.statusCode}');
        return false; // Indicate failure
      }
    } else {
      debugPrint("Error: either no signed URL or no video was received.");
      return false; // Indicate failure
    }
  } catch (e) {
    debugPrint('Error during file upload: $e');
    return false; // Indicate failure
  }
}

// Future<String?> uploadCompressedVideo(String filePath, String filename) async {
//   try {
//     debugPrint("File for signed url: $filePath");
//     final signedUrl = await getSignedUploadUrl(filename);

//     if (signedUrl == null) {
//       debugPrint("Error: No signed URL received.");
//       return null;
//     }

//     // Compress the video
//     final compressedFile = await VideoCompress.compressVideo(
//       filePath,
//       quality: VideoQuality.MediumQuality,
//       deleteOrigin: false,
//     );

//     if (compressedFile == null ||
//         compressedFile.file == null ||
//         !(await compressedFile.file!.exists())) {
//       debugPrint('Failed to compress video');
//       return null;
//     }

//     final request = http.Request('PUT', Uri.parse(signedUrl))
//       ..headers['Content-Type'] = 'video/mp4'
//       ..bodyBytes = await compressedFile.file!.readAsBytes()
//       ..headers['Content-Length'] =
//           (await compressedFile.file!.length()).toString();

//     final responseUpload = await request.send();

//     if (responseUpload.statusCode == 200) {
//       debugPrint('Compressed video uploaded successfully!');
//       return signedUrl;
//     } else {
//       debugPrint(
//           'Failed to upload compressed video: ${responseUpload.statusCode}');
//       return null;
//     }
//   } catch (e) {
//     debugPrint('Error during compressed video upload: $e');
//     return null;
//   }
// }

// Future<File?> _getVideoFile(String fileName) async {
//   final signedUrl = await getSignedDownloadUrl(fileName);

//   if (signedUrl == null) {
//     debugPrint("Error: No signed URL received for download.");
//     return null;
//   }

//   final response = await http.get(Uri.parse(signedUrl));
//   debugPrint("Response length: ${response.bodyBytes.length} bytes");

//   final tempDirectory = await path_provider
//       .getTemporaryDirectory(); //this directory will be cleared by the device when needed and does not persist through bootups

//   final filePath = '${tempDirectory.path}/$fileName';

//   final file = File(filePath);
//   await file.writeAsBytes(response.bodyBytes);

//   debugPrint("File location: ${file.path}");
//   debugPrint("File size: ${await file.length()} bytes");

//   if (!(await file.exists())) {
//     debugPrint("Error: File was not saved correctly");
//     return null;
//   }
//   debugPrint("File saved successfully at: ${file.path}");

//   debugPrint("opening file: $filePath");
//   try {
//     await file.open(mode: FileMode.read);
//     debugPrint("File opened successfully.");
//   } catch (e) {
//     debugPrint("Error opening file: $e");
//     return null;
//   }
//   return file;
// }
