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
  static const maxLessonVideoBytes = 100 * 1024 * 1024;
  static const maxLessonDocumentBytes = 20 * 1024 * 1024;

  static const lessonVideoExtensions = ['mp4', 'webm', 'mov'];
  static const lessonDocumentExtensions = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'txt',
  ];

  static String? validateLessonFile({
    required String fileName,
    required int sizeBytes,
    required bool isVideo,
  }) {
    final extension = fileName.split('.').last.toLowerCase();
    final allowedExtensions = isVideo
        ? lessonVideoExtensions
        : lessonDocumentExtensions;
    if (!allowedExtensions.contains(extension)) {
      return isVideo
          ? 'Choose an MP4, WebM or MOV video.'
          : 'Choose a PDF, Word, PowerPoint or text document.';
    }

    final maxBytes = isVideo ? maxLessonVideoBytes : maxLessonDocumentBytes;
    if (sizeBytes > maxBytes) {
      return isVideo
          ? 'The video must be 100 MB or smaller.'
          : 'The document must be 20 MB or smaller.';
    }
    return null;
  }

  static Future<MultipartFile> lessonPart({
    required String path,
    required String name,
    required bool isVideo,
  }) async {
    late final int size;
    try {
      size = await File(path).length();
    } on FileSystemException {
      throw const ApiException(
        message: 'Unable to read the selected file. Please choose it again.',
      );
    }
    final validationError = validateLessonFile(
      fileName: name,
      sizeBytes: size,
      isVideo: isVideo,
    );
    if (validationError != null) {
      throw ApiException(message: validationError);
    }

    final extension = name.split('.').last.toLowerCase();
    final expectedMimeType = _lessonMimeTypes[extension];
    final mimeType = lookupMimeType(path) ?? expectedMimeType ?? '';
    if (expectedMimeType == null || mimeType != expectedMimeType) {
      throw const ApiException(
        message: 'The selected file type is not supported.',
      );
    }
    final parts = mimeType.split('/');
    if (parts.length != 2) {
      throw const ApiException(
        message: 'The selected file type is not supported.',
      );
    }
    try {
      return await MultipartFile.fromFile(
        path,
        filename: name,
        contentType: MediaType(parts[0], parts[1]),
      );
    } on FileSystemException {
      throw const ApiException(
        message: 'Unable to read the selected file. Please choose it again.',
      );
    }
  }

  static const _lessonMimeTypes = {
    'mp4': 'video/mp4',
    'webm': 'video/webm',
    'mov': 'video/quicktime',
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'txt': 'text/plain',
  };

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

  static Future<String?> validateImageFile(XFile file) async {
    late final int size;
    try {
      size = await File(file.path).length();
    } on FileSystemException {
      return 'Unable to read the selected image. Please choose it again.';
    }
    if (size > maxImageBytes) {
      return 'The file must be 5 MB or smaller.';
    }
    final mimeType = lookupMimeType(file.path) ?? '';
    if (!imageTypes.contains(mimeType)) {
      return 'Only JPEG, PNG or WebP files are allowed.';
    }
    return null;
  }
}
