import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Profile picture provider
final profilePictureProvider = StateNotifierProvider<ProfilePictureNotifier, AsyncValue<String?>>((ref) {
  return ProfilePictureNotifier();
});

class ProfilePictureNotifier extends StateNotifier<AsyncValue<String?>> {
  ProfilePictureNotifier() : super(const AsyncValue.data(null)) {
    _loadProfilePicture();
  }

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _loadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.photoURL != null) {
      state = AsyncValue.data(user!.photoURL);
    }
  }

Future<void> pickAndUploadImage() async {
  try {
    state = const AsyncValue.loading();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = _storage.ref().child('profile_pictures/${user.uid}');
        final snapshot = await ref.putFile(File(image.path));
        final downloadUrl = await snapshot.ref.getDownloadURL();

        await user.updatePhotoURL(downloadUrl);
        await user.reload();

        final refreshedUser = FirebaseAuth.instance.currentUser;
        state = AsyncValue.data(refreshedUser?.photoURL);
      }
    } else {
      _loadProfilePicture();
    }
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}


  Future<void> removeProfilePicture() async {
    try {
      state = const AsyncValue.loading();
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePhotoURL(null);
        await user.reload();
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// User stats provider (for demonstration)
