import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/services/api_manager.dart';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;

class RoutingService {
  final polylinePoints = PolylinePoints();
  APIManager apiManager = APIManager();

  Map<TravelMode, String> travelModeToString = {
    TravelMode.driving: "driving",
    TravelMode.bicycling: "bicycling",
    TravelMode.transit: "transit",
    TravelMode.walking: "walking",
  };

  Future<PolylineResult> getRouteFromCoordinates_debug(
      startLatitude,
      startLongitude,
      destinationLatitude,
      destinationLongitude,
      travelMode) async {
    print("getRouteFromCoordinates_debug() called");

    String? travelModeString = travelModeToString[travelMode];
    travelModeString ??= "walking"; // set if null

    Uri uri = Uri.parse(
        "https://us-central1-gifted-pillar-339221.cloudfunctions.net/api-channel-dev?"
        "origin=$startLatitude,$startLongitude"
        "&destination=$destinationLatitude,$destinationLongitude"
        "&mode=$travelModeString");

    return decodeRouteURI(uri);
  }

  Future<PolylineResult> getRouteFromPlaceId_debug(
      startPlaceId, destinationPlaceId, travelMode) async {
    print("getRouteFromPlaceId_debug() called");

    String? travelModeString = travelModeToString[travelMode];
    travelModeString ??= "walking"; // set if null

    Uri uri = Uri.parse(
        "https://us-central1-gifted-pillar-339221.cloudfunctions.net/api-channel-dev?"
        "origin=place_id:$startPlaceId"
        "&destination=place_id:$destinationPlaceId"
        "&mode=$travelModeString");

    print(uri);
    return decodeRouteURI(uri);
  }


  Polyline createPolyline(result, id){
    List<LatLng> polylineCoordinates = [];
    if (result.status == 'OK') {
      // if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    else{
      print("Failed to create polyline from polylineResult");
    }
    Color routeColor = id == 0 ? Colors.red : Colors.orange;
    return Polyline(
      width: 5,
      polylineId: PolylineId('route_$id'),
      color: routeColor,
      points: polylineCoordinates,
    );
  }

  Future<Map<PolylineId, Polyline>> getMultipleRouteFromPlaceId(
      startPlaceId, destinationPlaceId, travelMode, num) async {
    print("getMultipleRouteFromPlaceId() called");

    String? travelModeString = travelModeToString[travelMode];

    Uri uri = Uri.parse(
        "https://us-central1-gifted-pillar-339221.cloudfunctions.net/api-channel-dev?"
        "origin=place_id:$startPlaceId"
        "&destination=place_id:$destinationPlaceId"
        "&mode=$travelModeString");

    http.Response encodedString = await http.get(uri);
    String response = encodedString.body;
    var json = convert.jsonDecode(response);

    Map<PolylineId, Polyline> routes = <PolylineId, Polyline>{};
    int totalRouteNum = json['routes'].length;
    for(int i = 0; i < num; i ++){
      if(i == totalRouteNum){
        print("All routes have been retrieved");
        break;
      }
      String encodedRoutes = json['routes'][i]['overview_polyline']['points'];
      List<PointLatLng> _points = polylinePoints.decodePolyline(encodedRoutes);
      PolylineResult result = PolylineResult(
        errorMessage: '',
        status: 'OK',
        points: _points,
      );
      Polyline polyline = createPolyline(result, i);
      print(polyline.mapsId.value);
      routes[polyline.mapsId] = polyline;
    }
    return routes;
  }

  Future<PolylineResult> decodeRouteURI(Uri uri) async {
    // print("http get");
    http.Response encodedString = await http.get(uri);
    String response = encodedString.body;
    // print("uri converted to string");

    // print(response);

    var json = convert.jsonDecode(response);

    // print("json data parsed");
    String encodedRoutes = json['routes'][0]['overview_polyline']['points'];

    List<PointLatLng> _points = polylinePoints.decodePolyline(encodedRoutes);
    PolylineResult result = PolylineResult(
      errorMessage: '',
      status: 'OK',
      points: _points,
    );
    return result;
  }

  Future<PolylineResult> getRouteFromCoordinates(startLatitude, startLongitude,
      destinationLatitude, destinationLongitude, travelMode) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      apiManager.getKey(),
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
      travelMode: travelMode,
    );

    /*
    not-quite-finished method for storing the .json of a request into /dummy_data/polyline/
    
    List<List<double>> points =
        result.points.map((latlong) => [latlong.latitude, latlong.longitude]).toList();

    Map<String, dynamic> resultContent = <String, dynamic>{
      "errorMessage": result.errorMessage,
      "status": result.status,
      "points": points,
    };

    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('lib/dummy_data/polyline/polyline.json');
    await file.writeAsString(convert.jsonEncode(resultContent));*/

    return result;
  }
}
