import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_lms/utils/api_exception.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class UploadHelper {
  const UploadHelper._();

  static const imageTypes = ['image/jpeg', 'image/png', 'image/webp'];
  static const maxImageBytes = 5 * 1024 * 1024;

  /// Builds a multipart part after checking the size and type locally.
  /// The backend validates again, so its message is shown if it still refuses.
  static Future<MultipartFile> filePart({
    required String path,
    required String name,
    required List<String> allowedTypes,
    required int maxBytes,
    required String typeLabel,
  }) async {
    final size = await File(path).length();
    if (size > maxBytes) {
      throw ApiException(
        message: 'The file must be ${maxBytes ~/ (1024 * 1024)} MB or smaller.',
      );
    }

    final mimeType = lookupMimeType(path) ?? '';
    if (!allowedTypes.contains(mimeType)) {
      throw ApiException(message: 'Only $typeLabel files are allowed.');
    }

    final parts = mimeType.split('/');
    return MultipartFile.fromFile(
      path,
      filename: name,
      contentType: MediaType(parts[0], parts[1]),
    );
  }

  static Future<MultipartFile> imagePart(XFile file) {
    return filePart(
      path: file.path,
      name: file.name,
      allowedTypes: imageTypes,
      maxBytes: maxImageBytes,
      typeLabel: 'JPEG, PNG or WebP',
    );
  }
}