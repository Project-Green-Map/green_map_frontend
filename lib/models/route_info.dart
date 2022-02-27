class RouteInfo{
  final String distanceText;
  final String timeText;
  // int distance;
  // int time;
  late String carbonText;
  final dynamic carbon;

  RouteInfo({
    required this.distanceText,
    required this.timeText,
    // required this.distance,
    // required this.time,
    required this.carbon,
  }){
    carbonText = carbon.toStringAsFixed(1) + " CO2e";
  }

  factory RouteInfo.fromJson(Map<dynamic, dynamic> routesJson, dynamic _carbon){
    String _distanceText = routesJson["legs"][0]["distance"]["text"];
    String _timeText = routesJson["legs"][0]["duration"]["text"];

    // int _distance = routesJson["legs"][0]["distance"]["value"]; // unit: kilometer
    // int _time = routesJson["legs"][0]["duration"]["value"]; // unit: second

    return RouteInfo(distanceText: _distanceText, timeText: _timeText, carbon: _carbon);
  }
}