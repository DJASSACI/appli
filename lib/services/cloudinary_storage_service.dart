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
}

