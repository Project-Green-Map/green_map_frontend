import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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

  Future<List<String>> getMultipleEncodedRoutesFromPlaceId(
      startPlaceId, destinationPlaceId, travelMode, val) async {
    print("getMultipleRouteFromPlaceId() called");

    String? travelModeString = travelModeToString[travelMode];

    Uri uri =
        Uri.parse("https://us-central1-gifted-pillar-339221.cloudfunctions.net/api-channel-dev?"
            "origin=place_id:$startPlaceId"
            "&destination=place_id:$destinationPlaceId"
            "&mode=$travelModeString");

    http.Response encodedString = await http.get(uri);
    String response = encodedString.body;
    var json = convert.jsonDecode(response);

    List<String> encodedRoutes = [];
    int totalRouteNum = json['routes'].length;
    for (int i = 0; i < val; i++) {
      if (i == totalRouteNum) {
        print("All routes have been retrieved");
        break;
      }
      String encodedRoute = json['routes'][i]['overview_polyline']['points'];
      encodedRoutes.add(encodedRoute);
    }
    return encodedRoutes;
  }
}
