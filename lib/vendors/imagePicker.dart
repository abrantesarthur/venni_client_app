import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

Future<void> _askPermission(
  BuildContext context,
  String description,
) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return YesNoDialog(
          title: description,
          onPressedYes: () async {
            await openAppSettings();
            Navigator.pop(context);
          });
    },
  );
}

Future<PickedFile> _pickImageFrom(
  BuildContext context,
  ImageSource source,
) async {
  // try to get image
  try {
    PickedFile pickedFile = await ImagePicker().getImage(source: source);
    return pickedFile;
  } catch (e) {
    // ask user to update permission in app settings
    await _askPermission(
      context,
      "Permitir Acesso às Fotos",
    );
  }
  return null;
}

Future<PickedFile> pickImageFromGallery(BuildContext context) async {
  return _pickImageFrom(context, ImageSource.gallery);
}

Future<PickedFile> pickImageFromCamera(BuildContext context) async {
  return _pickImageFrom(context, ImageSource.camera);
}

Future<PickedFile> pickImage(BuildContext context) {
  return showDialog<PickedFile>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Escolher Foto"),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Divider(color: Colors.black, thickness: 0.1),
              ListTile(
                onTap: () async {
                  // get image from gallery
                  PickedFile img = await pickImageFromGallery(context);
                  Navigator.pop(context, img);
                },
                title: Text("Galeria"),
                leading: Icon(
                  Icons.photo_album,
                  color: AppColor.primaryPink,
                ),
              ),
              Divider(color: Colors.black, thickness: 0.1),
              ListTile(
                onTap: () async {
                  // get image from camera
                  PickedFile img = await pickImageFromCamera(context);
                  Navigator.pop(context, img);
                },
                title: Text("Câmera"),
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColor.primaryPink,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
