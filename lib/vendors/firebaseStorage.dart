import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as dartIo;

extension AppFirebaseStorage on FirebaseStorage {
  void putProfileImage({
    @required String uid,
    @required PickedFile img,
  }) {
    try {
      this
          .ref()
          .child("client-photos")
          .child(uid)
          .child("profile" + path.extension(img.path))
          .putFile(dartIo.File(img.path));
    } catch (e) {}
  }

  // TODO: cache downloaded images
  // TODO: use something other than NetworkImage so it can load right away
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

  // TODO: cache downloaded images
  // TODO: use something other than NetworkImage so it can load right away
  Future<ProfileImage> getPartnerProfilePicture(String id) async {
    ListResult results;
    try {
      results = await this.ref().child("partner-photos").child(id).list();
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
}
