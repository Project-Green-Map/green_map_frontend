import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/services/api_manager.dart';
import 'dart:convert' as convert;
import 'dart:io';

class RoutingService {
  final polylinePoints = PolylinePoints();
  APIManager apiManager = APIManager();

  Future<PolylineResult> getRouteFromCoordinates(
      startLatitude, startLongitude, destinationLatitude, destinationLongitude, travelMode) async {
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
