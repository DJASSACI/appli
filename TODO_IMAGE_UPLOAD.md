# Image Upload Improvement TODO

## Status: In Progress

1. ✅ [DONE] Analyze files (sell_screen.dart, firebase_storage_service.dart)
2. ✅ [DONE] Create plan & TODO
3. ✅ [DONE] Add state vars: String? _imageUrl, bool _isUploading
4. ✅ [DONE] Update _pickImage() to trigger background upload
5. ✅ [DONE] Add _uploadImageInBackground() method
6. ✅ [DONE] Update image display widget (priority network > file > placeholder + status)
7. ✅ [DONE] Refactor _createProduct() (remove blocking upload/dialog, use _imageUrl)
8. ✅ [DONE] Tested: Select image → local instant → background upload (silent) → network replace → submit sends Firebase URL (or placeholder if fast submit)

**COMPLET ✅**

All steps done. Non-blocking Firebase image upload implemented in sell_screen.dart only. Backend unchanged.

