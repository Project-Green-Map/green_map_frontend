import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:map/services/api_manager.dart';
import 'dart:convert' as convert;
import 'dart:io';
import 'package:http/http.dart' as http;

class RoutingService {
  final polylinePoints = PolylinePoints();
  APIManager apiManager = APIManager();

  Map<TravelMode, String> travelModeToString = {
    TravelMode.driving: "DRIVING",
    TravelMode.bicycling: "BICYCLING",
    TravelMode.transit: "TRANSIT",
    TravelMode.walking: "WALKING",
  };

  Future<PolylineResult> getRouteFromCoordinates_debug(
      startLatitude, startLongitude, destinationLatitude, destinationLongitude, travelMode) async {
    print("getRouteFromCoordinates_debug() called");

    String? travelModeString = travelModeToString[travelMode];
    travelModeString ??= "DRIVING"; // set if null

    Uri uri =
        Uri.parse("https://us-central1-gifted-pillar-339221.cloudfunctions.net/api-channel-dev?"
            "origin=$startLatitude,$startLongitude"
            "&destination=$destinationLatitude,$destinationLongitude"
            "&mode=$travelModeString");

    return decodeRouteURI(uri);
  }

  Future<PolylineResult> getRouteFromPlaceId_debug(
      startPlaceId, destinationPlaceId, travelMode) async {
    print("getRouteFromCoordinates_debug() called");

    String? travelModeString = travelModeToString[travelMode];
    travelModeString ??= "DRIVING"; // set if null

    Uri uri =
        Uri.parse("https://us-central1-gifted-pillar-339221.cloudfunctions.net/api-channel-dev?"
            "origin=place_id:$startPlaceId"
            "&destination=place_id:$destinationPlaceId"
            "&mode=$travelModeString");

    return decodeRouteURI(uri);
  }

  Future<PolylineResult> decodeRouteURI(Uri uri) async {
    print("http get");
    http.Response encodedString = await http.get(uri);
    String response = encodedString.body;
    print("uri converted to string");

    print(response);

    var json = convert.jsonDecode(response);

    print("json data parsed");
    String encodedRoutes = json['routes'][0]['overview_polyline']['points'];

    List<PointLatLng> _points = polylinePoints.decodePolyline(encodedRoutes);
    PolylineResult result = PolylineResult(
      errorMessage: '',
      status: 'OK',
      points: _points,
    );
    return result;
  }

  Future<PolylineResult> getRouteFromCoordinates(
      startLatitude, startLongitude, destinationLatitude, destinationLongitude, travelMode) async {
    // List<PointLatLng> _points = polylinePoints.decodePolyline(
    //     "ids}Hk~UhK]jD}BhGuIlDgFnFeCRS@EFAzASRBEZRbOqBl\\u@~KpI|LaAld@mFpg@oB`UZhKjDlSpF|ShTxa@|FpHbAItA^VhAb@jDnD`FtFjDtGNdRaFnQmHj`@iWfWgWvOmSx\\yk@tQg`@fLsThL}MbS}L`IuBlMgAld@rCrKa@pMaCtMiF~O}KvNsL|t@om@tIuGvRiJ|NsCp`@_FbW_MxM{Kp\\kYtj@ue@lToUrb@kg@j]k[jf@k^dNqLlLkPxLk_@jGef@~B}L~GsSpI{NjG_HbSkLjQ{ElI}@rLOvYlD~`@zJpYl@nQkBhNsDlb@oUtXeM~RgD~J]hUnAnXpFrZtDhRt@d`@c@rWkCx`@}IhSoJbIoHhJsMjPa^jOuSdPsKdRaEfORhNjChLhA|GUtOwD`Z}GdVk@nUmA|RqJrXqYjQ{I~M{A~P|AtOlHvGlE`OnHrJdCpTjAxUyC`McF|HqDpLyCrJg@lIf@jOnE~I`G~NhQtXhb@tTnShNhIbP~F~c@zNfQvHb_@rSbTfO~ZxWfVrVvMxJtMfElHn@nJSdLaCdSeMnLkNxJqI`NaGpImAxQj@bLpDpLdIvNtOlNvJ`O`EpSbAtOlDxRlNzN~OxIbGdNvEzGv@`e@|Dl[tIhr@fXzi@bVv[zT|VvUj`@vc@jMvKrVxNtn@nUtRpNxLjLlH`GbM~FvN`CvIDzJiAhRiGn]qJfWoEnTcDd{@gUnQqAxMdA~JrCfMjHzUhOpUxH`YdN|ZhWzUbYfSvYbIfIpYbQ`d@xXbe@da@`ZpYlg@pi@r\\|f@rg@zbAnVhb@r`@nl@xJ~LzQpLzQxD`RhDlKnHtJbNbPte@|InTzCvCdF`BvGWtHwCdG{@lEl@~TnIzFzD|CnFjMvU~FzM`ApNgAnO_FrSkD|XB~QpEvl@S`UeB`PiVd{@{CjXOri@IxW}BjOwV~j@qMj\\sHdIeIdBgErCiEpJwBrPb@~DpA~@xApBBv@cAF}A~@z@xLfEvQvBfKVZzA`A~DI`@MR@c@`H]~HEv@xD]`@Ox@Gt@SdEs@|ATtJtDnCI|QoAtGvDpJlUhCnExChBfHfC|CtHbDrDlRtG~BnCJvFcApFi@hE~@tHjBxKG`Ga@lFnCr@nIlCzKrBfG~@nIhVlMn_@nLpNnNdN~E~JfOhn@rOlVtTr_@dG~O|ArAfEdBrE|DxGfJtDb@vD`LrHtXzA`B`CFnHFxO@vJHzQSvRmBt_@oDfM~A~ClClEzFvH|JlD`@lAGBt@UtFlAvERbCk@`@UL");
    // PolylineResult result = PolylineResult(
    //   errorMessage: "",
    //   status: "",
    //   points: _points,
    // );

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
