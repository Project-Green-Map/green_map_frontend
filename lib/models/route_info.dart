class RouteInfo{
  final String timeText;
  double distance;
  // int distance;
  // int time;
  late String carbonText;
  late String distanceText;
  late dynamic carbon;

  RouteInfo({
    // required this.distanceText,
    required this.distance,
    required this.timeText,
    // required this.time,
    required this.carbon,
  }){
    if(carbon < 1000){
      carbonText = carbon.toStringAsFixed(1) + " g CO2e";
    }
    else {
      double carbonToDisplay = carbon / 1000;
      // carbon = carbon / 1000;
      carbonText = carbonToDisplay.toStringAsFixed(1) + " kg CO2e";
    }
    // carbonText = carbon.toStringAsFixed(1) + " CO2e";

    distance = distance / 1000; // from meter to km
    distanceText = distance.toStringAsFixed(1) + " km";
  }

  factory RouteInfo.fromJson(Map<dynamic, dynamic> routesJson, dynamic _carbon){
    double _distance = routesJson["legs"][0]["distance"]["value"].toDouble();
    // String _distanceText = routesJson["legs"][0]["distance"]["text"];
    String _timeText = routesJson["legs"][0]["duration"]["text"];

    // int _distance = routesJson["legs"][0]["distance"]["value"]; // unit: kilometer
    // int _time = routesJson["legs"][0]["duration"]["value"]; // unit: second

    return RouteInfo(distance: _distance, timeText: _timeText, carbon: _carbon);
  }
}