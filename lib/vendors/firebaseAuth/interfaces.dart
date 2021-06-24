import 'package:flutter/material.dart';

class CreateEmailResponse {
  final bool successful;
  final String message;
  final String code;

  CreateEmailResponse({
    @required this.successful,
    this.code,
    this.message,
  });
}

class UpdateEmailResponse extends CreateEmailResponse {
  UpdateEmailResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class UpdatePasswordResponse extends CreateEmailResponse {
  UpdatePasswordResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class DeleteAccountResponse extends CreateEmailResponse {
  DeleteAccountResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class CheckPasswordResponse extends CreateEmailResponse {
  CheckPasswordResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}
