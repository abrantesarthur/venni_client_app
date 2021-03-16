import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/config/config.dart';

class CloudFunctionsWebService {
  String _baseURL;
  String _userIdToken;
  Map<String, String> _headers;

  CloudFunctionsWebService({
    @required String userIdToken,
  }) {
    _baseURL = AppConfig.env.values.cloudFunctionsBaseURL;
    _userIdToken = userIdToken;
    _headers = {
      "Content-Type": "application/json",
      "Authorization": _userIdToken,
    };
  }

  void renewToken({@required String newUserIdToken}) {
    _userIdToken = newUserIdToken;
  }

  @protected
  Future<http.Response> doPost({
    String path,
    dynamic body,
  }) async {
    return await http.post(
      _baseURL + path,
      headers: _headers,
      body: body,
    );
  }

  @protected
  Future<http.Response> doPut({
    String path,
    dynamic body,
  }) async {
    return await http.put(
      _baseURL + path,
      headers: _headers,
      body: body,
    );
  }
}

class CloudFunctionsResponse<T> extends CloudFunctionsResponseStatus {
  final T result;

  CloudFunctionsResponse({
    @required this.result,
    @required String status,
    @required String errorMessage,
  }) : super(
          status: status,
          errorMessage: errorMessage,
        );
}

class CloudFunctionsResponseStatus {
  static const okay = "OK";
  static const invalidRequest = "INVALID_REQUEST";
  static const requestDenied = "REQUEST_DENIED";
  static const unknownErrorStatus = "UNKNOWN_ERROR";

  final String status;
  final String errorMessage;

  CloudFunctionsResponseStatus({
    @required this.status,
    @required this.errorMessage,
  });

  bool get isOkay => status == okay;
  bool get isInvalid => status == invalidRequest;
  bool get isDenied => status == requestDenied;
  bool get unknownError => status == unknownErrorStatus;
}
