import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String PLACEHOLDER_URL = 'https://via.placeholder.com/400x400/gray/ffffff?text=Image';

  Future<String> uploadProductImage(File imageFile, String productName) async {
    print('🔄 [STORAGE] Starting upload for $productName');
    print('🔄 [STORAGE] File path: ${imageFile.path}');
    print('🔄 [STORAGE] File size: ${await imageFile.length()} bytes');
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = productName.replaceAll(RegExp(r'[^\w\s-]'), '').toLowerCase();
      final fileName = 'products/${timestamp}_$safeName.jpg';
      print('🔄 [STORAGE] Filename: $fileName');
      
      final ref = _storage.ref().child(fileName);
      print('🔄 [STORAGE] Storage ref created');
      
      final uploadTask = ref.putFile(imageFile);
      print('🔄 [STORAGE] putFile started');
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📈 [STORAGE] Upload progress: ${(progress).toStringAsFixed(1)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes})');
      }, onError: (error) {
        print('❌ [STORAGE] Progress error: $error');
      });
      
final snapshot = await uploadTask.timeout(const Duration(minutes: 2)).whenComplete(() => print('✅ [STORAGE] Upload complete'));
      print('✅ [STORAGE] putFile TERMINÉ AVANT getDownloadURL');
      print('🔄 [STORAGE] Getting download URL...');
final downloadUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 30));
      print("IMAGE URL = $downloadUrl");
      print('📥 [STORAGE] getDownloadURL OK: ${downloadUrl.length} chars');
      print('✅ [STORAGE] SUCCESS: $downloadUrl');
      return downloadUrl;
    } on TimeoutException catch (e) {
      print('⏰ [STORAGE] TIMEOUT - RETRY NEEDED: $e');
      throw Exception('Upload failed - retry');
    } on FirebaseException catch (e) {
      print('❌ [STORAGE] FirebaseException - RETRY: ${e.code} - ${e.message}');
      throw Exception('Upload failed - retry');
    } catch (e) {
      print('❌ [STORAGE] Error - RETRY: $e');
      throw Exception('Upload failed - retry');
    }
  }

  Future<String> uploadImageBytes(Uint8List bytes, String fileName) async {
    try {
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage error: ${e.message}');
    }
  }

  Future<void> deleteImage(String imagePath) async {
    try {
      final ref = _storage.refFromURL(imagePath);
      await ref.delete();
    } catch (e) {
      print('Delete error (non-blocking): $e');
    }
  }
}