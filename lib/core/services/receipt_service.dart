import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles receipt photo compression, local storage and Supabase upload.
class ReceiptService {
  ReceiptService._();
  static final ReceiptService shared = ReceiptService._();

  static const int _maxBytes = 1024 * 1024; // 1 MB
  static const int _jpegQuality = 80;

  /// Compresses an image file to max 1 MB JPEG at quality 80.
  /// Returns the compressed [File].
  Future<File> compressReceipt(File source) async {
    final tmpDir = await getTemporaryDirectory();
    final target = '${tmpDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';

    XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      target,
      quality: _jpegQuality,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) {
      // Fallback: return original if compression fails
      return source;
    }

    // If still too large, try lower quality
    final compressedFile = File(compressed.path);
    if (await compressedFile.length() > _maxBytes) {
      final target2 = '${tmpDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}_sm.jpg';
      final XFile? compressed2 = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        target2,
        quality: 60,
        format: CompressFormat.jpeg,
      );
      if (compressed2 != null) return File(compressed2.path);
    }

    return compressedFile;
  }

  /// Saves the receipt locally in the app's documents directory.
  /// Returns the local [File] path.
  Future<File> saveLocally(File compressed, {required String expenseId}) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    final dest = File('${receiptsDir.path}/$expenseId.jpg');
    return compressed.copy(dest.path);
  }

  /// Uploads the receipt to Supabase Storage.
  /// Returns the public URL or null on failure.
  Future<String?> uploadToSupabase(
    File file, {
    required String groupId,
    required String expenseId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final storagePath = 'receipts/$groupId/$expenseId.jpg';
      final bytes = await file.readAsBytes();

      await supabase.storage.from('receipts').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final url = supabase.storage.from('receipts').getPublicUrl(storagePath);
      return url;
    } catch (e) {
      debugPrint('[ReceiptService] Upload failed: $e');
      return null;
    }
  }

  /// Full pipeline: compress → save locally → upload.
  /// Returns the remote URL (or null if offline/upload failed).
  Future<String?> processAndUpload(
    File source, {
    required String groupId,
    required String expenseId,
  }) async {
    final compressed = await compressReceipt(source);
    await saveLocally(compressed, expenseId: expenseId);
    return uploadToSupabase(compressed, groupId: groupId, expenseId: expenseId);
  }
}
