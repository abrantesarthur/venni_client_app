import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as i;
import 'package:image_picker/image_picker.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as dartIo;

import 'package:rider_frontend/utils/utils.dart';

extension AppFirebaseStorage on FirebaseStorage {
  void putProfileImage({
    @required String uid,
    @required XFile img,
  }) {
    // resize image before uploading it to firebase
    dartIo.File imgFile = resizeImage(img.path, 500);

    try {
      this
          .ref()
          .child("client-photos")
          .child(uid)
          .child("profile" + path.extension(img.path))
          .putFile(imgFile);
    } catch (e) {}
  }

  Future<ProfileImage> getUserProfileImage({@required String uid}) async {
    ListResult results;
    try {
      results = await this.ref().child("client-photos").child(uid).list();
      if (results != null && results.items.length > 0) {
        String imageURL = await results.items[0].getDownloadURL();
        return ProfileImage(
          file: NetworkImage(imageURL),
          name: results.items[0].name,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<ProfileImage> getPartnerProfilePicture(String id) async {
    if (id == null) {
      return null;
    }
    ListResult results;
    try {
      results = await this.ref().child("partner-documents").child(id).list();
      if (results != null && results.items.length > 0) {
        Reference profilePhotoRef;
        results.items.forEach((item) {
          if (item.fullPath.contains("profilePhoto")) {
            profilePhotoRef = item;
          }
        });
        if (profilePhotoRef != null) {
          String imageURL = await profilePhotoRef.getDownloadURL();
          return ProfileImage(
            file: NetworkImage(imageURL),
            name: results.items[0].name,
          );
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
