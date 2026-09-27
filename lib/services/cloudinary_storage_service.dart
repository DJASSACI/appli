import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryStorageService {
  static const String cloudName = "drnoh6zfx";
  static const String uploadPreset = "djassa_preset";

  Future<String> uploadProductImage(File imageFile, String productName) async {
    print("🔄 Upload Cloudinary: $productName");

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = "products";

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(res.body);
      final url = data["secure_url"];

      if (url == null) {
        throw Exception("Cloudinary returned null URL");
      }

      print("✅ Image uploadée: $url");

      return url;
    } else {
      print("❌ Erreur Cloudinary: ${res.body}");
      throw Exception("Upload failed: ${response.statusCode}");
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    print("🔄 Upload Avatar Cloudinary");

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = "avatars";

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(res.body);
      final url = data["secure_url"];

      if (url == null) {
        throw Exception("Cloudinary returned null URL");
      }

      print("✅ Avatar uploadé: $url");

      return url;
    } else {
      print("❌ Erreur Cloudinary Avatar: ${res.body}");
      throw Exception("Upload failed: ${response.statusCode}");
    }
  }

  Future<String> uploadCertificationImage(File imageFile) async {
    print("🔄 Upload Certification Image Cloudinary");

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = "certification";

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(res.body);
      final url = data["secure_url"];

      if (url == null) {
        throw Exception("Cloudinary returned null URL");
      }

      print("✅ Certification image uploadée: $url");

      return url;
    } else {
      print("❌ Erreur Cloudinary Certification: ${res.body}");
      throw Exception("Upload failed: ${response.statusCode}");
    }
  }

  Future<String> uploadProductVideo(File videoFile, String productName) async {
    print("🔄 Upload Product Video Cloudinary: $productName");

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/video/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = "product_videos";

    request.files.add(
      await http.MultipartFile.fromPath('file', videoFile.path),
    );

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(res.body);
      final url = data["secure_url"];

      if (url == null) {
        throw Exception("Cloudinary returned null URL");
      }

      print("✅ Product video uploadée: $url");

      return url;
    } else {
      print("❌ Erreur Cloudinary Video: ${res.body}");
      throw Exception("Upload failed: ${response.statusCode}");
    }
  }
}