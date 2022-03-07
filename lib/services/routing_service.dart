import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/MyApp.dart';
import 'package:map/models/route_info.dart';
import 'package:map/services/api_manager.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

class RoutingService {
  // final polylinePoints = PolylinePoints();
  APIManager apiManager = APIManager();

  Map<TravelMode, String> travelModeToString = {
    TravelMode.driving: "driving",
    TravelMode.bicycling: "bicycling",
    TravelMode.transit: "transit",
    TravelMode.walking: "walking",
  };

  Future<Map<String, RouteInfo>> getMultipleEncodedRoutesFromPlaceId(
      startPlaceId, destinationPlaceId, travelMode, val,
      {String vehicleInfo = ""}) async {
    print("getMultipleRouteFromPlaceId() called");

    String? travelModeString = travelModeToString[travelMode];

    Uri uri =
        Uri.parse("https://europe-west2-gifted-pillar-339221.cloudfunctions.net/api?"
            "origin=place_id:$startPlaceId"
            "&destination=place_id:$destinationPlaceId"
            "&mode=$travelModeString");

    print(uri);

    http.Response encodedString = await http.post(uri,
        headers: <String, String>{"Content-Type": "application/json"}, body: vehicleInfo);
    String response = encodedString.body;
    var json = convert.jsonDecode(response);

    Map<String, RouteInfo> encodedRoutes = {};
    // List<String> encodedRoutes = [];
    int totalRouteNum = json['routes'].length;
    for (int i = 0; i < val; i++) {
      if (i == totalRouteNum) {
        print("All routes have been retrieved");
        break;
      }
      dynamic _carbon = json['carbon'][i];
      if (_carbon is int) {
        _carbon = _carbon.toDouble();
      }

      String encodedRoute = json['routes'][i]['overview_polyline']['points'];
      RouteInfo routeInfo = RouteInfo.fromJson(json['routes'][i], _carbon);
      encodedRoutes[encodedRoute] = routeInfo;
    }
    return encodedRoutes;
  }
}
