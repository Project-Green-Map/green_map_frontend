class RouteInfo{
  final String distanceText;
  final String timeText;
  int distance;
  int time;

  RouteInfo({required this.distanceText, required this.timeText, required this.distance, required this.time});

  factory RouteInfo.fromJson(Map<dynamic, dynamic> json){
    String _distanceText = json["legs"][0]["distance"]["text"];
    String _timeText = json["legs"][0]["duration"]["text"];

    int _distance = json["legs"][0]["distance"]["value"]; // unit: kilometer
    int _time = json["legs"][0]["duration"]["value"]; // unit: second

    return RouteInfo(distanceText: _distanceText, timeText: _timeText, distance: _distance, time: _time);
  }
}