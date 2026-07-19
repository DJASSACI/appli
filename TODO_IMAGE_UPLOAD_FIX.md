# TODO - SellScreen: upload image on publish only

- [ ] Étudier sell_screen.dart (flux _pickImage / _uploadImageInBackground / _createProduct)
- [ ] Supprimer l’appel _uploadImageInBackground() de _pickImage()
- [ ] Supprimer complètement _uploadImageInBackground() (ou le rendre inutilisé)
- [ ] Dans _createProduct(): uploader l’image Firebase Storage avant le POST /api/products
- [ ] Utiliser le downloadUrl comme valeur du champ 'image' dans le body
- [ ] Retirer la logique dépendante de _imageUrl si nécessaire
- [ ] Mettre à jour l’état du bouton 'Publier produit' (disabled si upload en cours ou image manquante)
- [ ] Vérifier compilation / run (flutter analyze)

