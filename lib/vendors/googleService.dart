import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/config/config.dart';

class GoogleWebService {
  String _baseUrl;
  String _googleApiKey;

  GoogleWebService({@required String baseUrl})
      : assert(baseUrl != null && baseUrl.length > 0) {
    _baseUrl = baseUrl;
    _googleApiKey = AppConfig.env.values.googleMapsApiKey;
  }

  @protected
  Future<http.Response> doGet(String params) async {
    http.Response response;
    try {
      response = await http.get(_buildUrl(params));
    } catch (_) {}
    return response;
  }

  String _buildUrl(String params) {
    return _baseUrl +
        "/json?key=$_googleApiKey&language=pt-BR" +
        (params.length > 0 ? "&" + params : "");
  }
}

class GoogleResponseStatus {
  static const okay = "OK";
  static const notFound = "NOT_FOUND";
  static const zeroResults = "ZERO_RESULTS";
  static const maxWaypointsExceeded = "MAX_WAYPOINTS_EXCEEDED";
  static const maxRouteLengthExceeded = "MAX_ROUTE_LENGTH_EXCEEDED";
  static const invalidRequest = "INVALID_REQUEST";
  static const overQueryLimit = "OVER_QUERY_LIMIT";
  static const requestDenied = "REQUEST_DENIED";
  static const unknownErrorStatus = "UNKNOWN_ERROR";

  final String status;
  final String errorMessage;

  bool get isOkay => status == okay;
  bool get isNotFound => status == notFound;
  bool get hasNoResults => status == zeroResults;
  bool get maxWaypointsIsExceeded => status == maxWaypointsExceeded;
  bool get maxRouteLengthIsExceeded => status == maxRouteLengthExceeded;
  bool get isInvalid => status == invalidRequest;
  bool get isOverQueryLimit => status == overQueryLimit;
  bool get isDenied => status == requestDenied;
  bool get unknownError => status == unknownErrorStatus;

  GoogleResponseStatus({
    @required this.status,
    @required this.errorMessage,
  });
}

class GoogleResponseList<T> extends GoogleResponseStatus {
  List<T> results;

  GoogleResponseList({
    @required String status,
    @required String errorMessage,
    @required this.results,
  }) : super(
          status: status,
          errorMessage: errorMessage,
        );
}

class GoogleResponse<T> extends GoogleResponseStatus {
  T result;

  GoogleResponse({
    @required String status,
    @required String errorMessage,
    @required this.result,
  }) : super(
          status: status,
          errorMessage: errorMessage,
        );
}
