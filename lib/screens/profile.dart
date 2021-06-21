import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/editEmail.dart';
import 'package:rider_frontend/screens/editPhone.dart';
import 'package:rider_frontend/screens/insertNewPassword.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/imagePicker.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'dart:io' as dartIo;
import 'package:path/path.dart' as path;

import '../models/firebase.dart';

// TODO: write comments
// TODO: fix image overflow
// TODO: change default avatar
// TODO: save image in storage

class Profile extends StatefulWidget {
  static const String routeName = "Profile";

  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // reload firebase so we get update info about email confirmation
      FirebaseModel firebase =
          Provider.of<FirebaseModel>(context, listen: false);
      firebase.auth.currentUser.reload();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    final UserModel user = Provider.of<UserModel>(context);

    return GoBackScaffold(
      resizeToAvoidBottomInset: false,
      title: "Perfil",
      children: [
        Row(
          children: [
            Spacer(),
            GestureDetector(
              onTap: () async {
                PickedFile img = await pickImage(context);
                if (img != null) {
                  // push image to firebase
                  firebase.storage.putProfileImage(
                    uid: firebase.auth.currentUser.uid,
                    img: img,
                  );

                  // update ui
                  user.setProfileImage(
                    ProfileImage(
                        file: FileImage(dartIo.File(img.path)),
                        name: "profile" + path.basename(img.path)),
                  );
                }
              },
              child: Stack(
                children: [
                  Container(
                    width: screenHeight / 7,
                    height: screenHeight / 7,
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                        fit: BoxFit.cover,
                        image: user.profileImage == null
                            ? AssetImage("images/user_icon.png")
                            : user.profileImage.file,
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenHeight / 9.5,
                    left: screenHeight / 9.5,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: screenHeight / 30),
        BorderlessButton(
          primaryText: "Nome",
          secondaryText: firebase.auth.currentUser?.displayName,
          primaryTextSize: 16,
          secondaryTextSize: 18,
          paddingTop: screenHeight / 150,
          paddingBottom: screenHeight / 150,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        BorderlessButton(
          onTap: () {
            Navigator.pushNamed(context, EditPhone.routeName);
          },
          primaryText: "Alterar Telefone",
          secondaryText:
              firebase.auth.currentUser?.phoneNumber?.withoutCountryCode(),
          label: "Confirmado",
          labelColor: Colors.green,
          iconRight: Icons.keyboard_arrow_right,
          primaryTextSize: 16,
          secondaryTextSize: 18,
          paddingTop: screenHeight / 150,
          paddingBottom: screenHeight / 150,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        BorderlessButton(
          onTap: () {
            Navigator.pushNamed(context, EditEmail.routeName);
          },
          primaryText: "Alterar email",
          secondaryText: firebase.auth.currentUser?.email,
          label: firebase.auth.currentUser.emailVerified
              ? "Confirmado"
              : "Não confirmado",
          labelColor: firebase.auth.currentUser.emailVerified
              ? Colors.green
              : AppColor.secondaryRed,
          iconRight: Icons.keyboard_arrow_right,
          primaryTextSize: 16,
          secondaryTextSize: 18,
          paddingTop: screenHeight / 150,
          paddingBottom: screenHeight / 150,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        BorderlessButton(
          onTap: () {
            Navigator.pushNamed(context, InsertNewPassword.routeName);
          },
          primaryText: "Alterar senha",
          secondaryText: "••••••••",
          iconRight: Icons.keyboard_arrow_right,
          primaryTextSize: 16,
          secondaryTextSize: 18,
          paddingTop: screenHeight / 150,
          paddingBottom: screenHeight / 150,
        ),
      ],
    );
  }
}
