import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/services/api_manager.dart';

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

    return result;
  }
}
