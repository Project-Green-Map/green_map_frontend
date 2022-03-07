import 'dart:typed_data';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart'; //only use for Position objects. add functionality via geolocator_service.dart
import 'package:map/carbonStats.dart';
import 'package:map/models/place.dart';
import 'package:map/models/place_search.dart';
import 'package:map/services/places_service.dart';
import 'package:map/services/routing_service.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:map/services/settings_prefs.dart';

import 'dart:math' show max, min;

import './services/geolocator_service.dart';
import './services/geocoding_service.dart';
import 'models/route_info.dart';
import 'settings.dart';

import 'carbonStats.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Green Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late SharedPreferences prefs;
  late double savedCarbon;
  // late double currentRouteCarbon;
  late RouteInfo currentRouteInfo;
  late bool canClickStart = true;

  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  String _startAddress = '';
  String _destinationAddress = '';
  LatLng _startPosition = const LatLng(0, 0);
  LatLng _destinationPosition = const LatLng(0, 0);
  String _startPlaceId = '';
  String _destinationPlaceId = '';

  final CameraPosition cambridgePosition = const CameraPosition(
    target: LatLng(52.2053, 0.1218),
    zoom: 14,
  );

  final int _routeNum = 5;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  String? activeAddressController;

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  final _geolocatorService = GeolocatorService();
  final _geocodingService = GeocodingService();
  final _routingService = RoutingService();
  final _placesService = PlacesService();

  late TravelMode _travelMode;
  bool _travelModeSet = false;

  List<PlaceSearch> searchResults = [];
  final polylinePoints = PolylinePoints();

  // Set<Marker> _markers = {};
  Map<MarkerId, Marker> _markers = {};

  late BitmapDescriptor customIcon;
  late List<Widget> selectedTransports;

  final SettingsPrefs settings = SettingsPrefs();

  // late PolylinePoints polylinePoints;
  // List<LatLng> polylineCoordinates = [];
  // Set<Polyline> _polylines = Set<Polyline>();

  Map<PolylineId, Polyline> _polylines = {};
  Map<PolylineId, RouteInfo> _routeInfo = {};

  String _distanceUnits = 'km';

  final Map<TravelMode, String> travelModeToStringPretty = {
    //do not merge this with the one in routing_service. this is the prettified version, and
    //is not compatible with the names used in the google maps api query.
    TravelMode.driving: "Driving",
    TravelMode.walking: "Walking",
    TravelMode.bicycling: "Cycling",
    TravelMode.transit: "Transit"
  };

  _MapViewState() {
    startAddressFocusNode.addListener(() {
      if (startAddressFocusNode.hasFocus) {
        activeAddressController = "start";
        searchPlaces(startAddressController.text);
        print("START ADDRESS CLICKED");
      }
    });
    destinationAddressFocusNode.addListener(() {
      if (destinationAddressFocusNode.hasFocus) {
        activeAddressController = "dest";
        searchPlaces(destinationAddressController.text);
        print("DESTINATION ADDRESS CLICKED");
      }
    });
    initSettings();
  }

  void initSettings() async {
    await settings.onStart();
    setState(() {
      selectedTransports = settings.getTravelModes().map(((e) => makeTravelModeButton(e))).toList();
    });
  }

  void updateSelectedTransports() {
    setState(() {
      selectedTransports = settings.getTravelModes().map(((e) => makeTravelModeButton(e))).toList();
    });
  }

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    // required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      // width: width * 0.8,
      child: TextField(
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          // prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.grey.shade400,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
            borderSide: BorderSide(
              color: Colors.blue.shade300,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.all(15),
          hintText: hint,
        ),
      ),
    );
  }

  @override
  void initState() {
    // called as soon as the app launches
    super.initState();

    // make sure to initialize before map loading
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(4, 4)), 'assets/images/car.png')
        .then((d) {
      customIcon = d;
    });

    // _destinationPosition = LatLng(52.207099555585565, 0.1130482077789624);
    print("initState() called");
  }

  void startupLogic() async {
    //called when the map is finished loading
    print("startupLogic() called");

    prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("savedCarbon")) {
      prefs.setDouble("savedCarbon", 0.0);
      savedCarbon = 0;
    } else {
      savedCarbon = prefs.getDouble("savedCarbon")!;
    }
    print("savedCarbon: $savedCarbon");

    await updateCurrentLocation();
    String? _placeIdTmp = await _geocodingService.getPlaceIdFromCoordinates(
        _currentPosition.latitude, _currentPosition.longitude);

    setState(() {
      _startPosition = LatLng(_currentPosition.latitude, _currentPosition.longitude);
      _startPlaceId = _placeIdTmp ?? "";
      print("start up placeId: $_startPlaceId");
    });

    await _geocodingService.getPlaceIdFromCoordinates(
        _startPosition.latitude, _startPosition.longitude);

    await moveCameraToCurrentLocation();
  }

  //in an effort to save API requests, only call when necessary
  updateCurrentLocation() async {
    await _geolocatorService.getCurrentLocation().then((position) async {
      setState(() {
        _currentPosition = position;
        debugPrint('CURRENT POS: $_currentPosition');
      });
      await _updateCurrentAddress();
    });
  }

  //do not call directly. use the above function
  _updateCurrentAddress() async {
    await _geocodingService.getCurrentPlacemark(_currentPosition).then((place) {
      setState(() {
        if (place != null) {
          //// _currentAddress = "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
          ////Done: This doesn't work for street names, e.g. "17, , CB2 3NE, UK". Could we see which ones are non-null and use those?

          bool isFirst = true;
          List<String?> placeTags = [place.name, place.locality, place.postalCode, place.country];
          for (int i = 0; i < placeTags.length; i++) {
            if (placeTags.elementAt(i)?.isNotEmpty ?? false) {
              if (isFirst) {
                isFirst = false;
              } else {
                _currentAddress += ", ";
              }
              _currentAddress += "${placeTags.elementAt(i)}";
            }
          }

          print("Current address: $_currentAddress");
          startAddressController.text = _currentAddress;
          _startAddress = _currentAddress;
        }
      });
    });
  }

  moveCameraToPosition(double lat, double long, double zoom) async {
    await mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, long),
          zoom: zoom,
        ),
      ),
    );
  }

  resetCameraVisibleRegion() async {
    // only called after startPlaceId and destinationPlaceId are set
    if (_startPlaceId == "" || _destinationPlaceId == "") {
      return;
    }
    LatLng southwest = LatLng(min(_startPosition.latitude, _destinationPosition.latitude),
        min(_startPosition.longitude, _destinationPosition.longitude));
    double diff = _startPosition.latitude - _destinationPosition.latitude;
    if (diff < 0) {
      diff *= -1;
    }
    LatLng northeast = LatLng(
        max(_startPosition.latitude, _destinationPosition.latitude) + diff * 0.5,
        max(_startPosition.longitude, _destinationPosition.longitude));
    LatLngBounds bound = LatLngBounds(southwest: southwest, northeast: northeast);
    CameraUpdate update = CameraUpdate.newLatLngBounds(bound, 100);
    mapController.animateCamera(update);
    setState(() {
      canClickStart = true;
    });
  }

  _updateTravelModeAndRoutes(travelMode) async {
    setState(() {
      _travelModeSet = true;
      _travelMode = travelMode;
      _polylines.clear();
      _routeInfo.clear();
      updateSelectedTransports();
      for (int i = 0; i < _routeNum; i++) {
        MarkerId tmpId = MarkerId("route_$i");
        if (_markers.containsKey(tmpId)) {
          _markers.remove(tmpId);
        }
      }
    });
    Marker marker = Marker(
      markerId: const MarkerId('dest'),
      position: _destinationPosition,
    );
    _markers[marker.markerId] = marker;
    await resetCameraVisibleRegion();
    await _createMultiplePolylines(_startPlaceId, _destinationPlaceId, travelMode, _routeNum);
    // await _createPolylines_debug(_startPosition.latitude, _startPosition.longitude,
    //     _destinationPosition.latitude, _destinationPosition.longitude, travelMode);
  }

  moveCameraToCurrentLocation() async {
    await moveCameraToPosition(_currentPosition.latitude, _currentPosition.longitude, 14);
  }

  // LatLng middlePoint;

  _createMultiplePolylines(startPlaceId, destinationPlaceId, travelMode, val) async {
    print("_createMultiplePolylines() called");

    var vehicleInfoSample = await rootBundle
        .loadString('lib/dummy_data/vehicle_information/diesel_small_all_info.json');
    print(vehicleInfoSample);

    Map<String, RouteInfo> encodedRoutes = await _routingService
        .getMultipleEncodedRoutesFromPlaceId(startPlaceId, destinationPlaceId, travelMode, val,
            vehicleInfo: vehicleInfoSample);
    // List<String> encodedRoutes =
    //     await _routingService.getMultipleEncodedRoutesFromPlaceId(
    //         startPlaceId, destinationPlaceId, travelMode, val);

    // Map<PolylineId, Polyline> polylines = await _routingService.getMultipleRouteFromPlaceId(
    //     startPlaceId, destinationPlaceId, travelMode, num);

    Map<PolylineId, Polyline> polylines = await decodePolylines(List.from(encodedRoutes.keys));
    await createMarkersForEachRoute(polylines, List.from(encodedRoutes.values));
    setState(() {
      _polylines = polylines;
    });
  }

  Polyline createPolyline(result, id) {
    List<LatLng> polylineCoordinates = [];
    if (result.status == 'OK') {
      // if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print("Failed to create polyline from polylineResult");
    }
    PolylineId polylineId = PolylineId('route_$id');
    return Polyline(
      width: 5,
      polylineId: polylineId,
      consumeTapEvents: true,
      color: id == 0 ? Colors.red : Colors.grey,
      points: polylineCoordinates,
      jointType: JointType.round,
      zIndex: id == 0 ? 1 : 0,
      onTap: () => _handlePolylineTap(polylineId),
      // patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    );
  }

  Future<BitmapDescriptor> createCustomMarkerBitmap(String title) async {
    TextSpan span = TextSpan(
      text: title,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 35.0,
        fontWeight: FontWeight.bold,
        // background: Paint()
        //   ..color = Colors.blue.shade300
        //   ..strokeWidth = 100
        //   ..strokeJoin = StrokeJoin.round
        //   ..style = PaintingStyle.stroke,
      ),
    );

    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    PictureRecorder recorder = PictureRecorder();
    Canvas c = Canvas(recorder);

    Paint backgroundPaint = Paint()
      ..color = Colors.blue.shade300
      ..strokeWidth = 100
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.fill;

    tp.layout();
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, tp.width.toInt() + 40, tp.height.toInt() + 20),
            const Radius.circular(15.0)),
        backgroundPaint);
    tp.paint(c, const Offset(20.0, 10.0));

    Picture p = recorder.endRecording();
    ByteData? pngBytes = await (await p.toImage(tp.width.toInt() + 40, tp.height.toInt() + 20))
        .toByteData(format: ImageByteFormat.png);

    Uint8List data = Uint8List.view((pngBytes?.buffer)!);

    return BitmapDescriptor.fromBytes(data);
  }

  String mapToSelectedDistanceUnit(String str) {
    //input string: "xxxx.x km"
    String requiredDistance = settings.getDistanceUnit();
    if (requiredDistance == 'km') return str;
    List<String> parts = str.split(' ');
    double val = double.parse(parts[0]);
    return (val * 0.621371).toStringAsFixed(2) + ' miles';
  }

  Future<void> createMarkersForEachRoute(
      Map<PolylineId, Polyline> polylineMap, List<RouteInfo> routeInfo) async {
    debugPrint("createMarkersForEachRoute() called");

    // Map<PolylineId, Marker> markersMap = {};
    for (int i = 0; i < routeInfo.length; i++) {
      PolylineId polylineId = PolylineId("route_$i");
      //
      // }
      // for (PolylineId polylineId in polylineMap.keys) {
      int? length = polylineMap[polylineId]?.points.length;
      LatLng? middlePoint = polylineMap[polylineId]?.points[(length! / 3).floor()];
      middlePoint ??= _startPosition;

      BitmapDescriptor bitmapDescriptor = await createCustomMarkerBitmap(
          mapToSelectedDistanceUnit(routeInfo[i].distanceText) +
              "\n" +
              routeInfo[i].timeText +
              "\n" +
              routeInfo[i].carbonText);
      MarkerId markerId = MarkerId(polylineId.value);
      Marker marker = Marker(
        markerId: markerId,
        position: middlePoint,
        icon: bitmapDescriptor,
        visible: i == 0 ? true : false,
        // icon: customIcon,
      );

      setState(() {
        _markers[markerId] = marker;
        _routeInfo[polylineId] = routeInfo[i];
        if (i == 0) {
          currentRouteInfo = routeInfo[i];
        }
      });
    }
    print("markers created");
  }

  Future<Map<PolylineId, Polyline>> decodePolylines(List<String> encodedRoutes) async {
    print("decodePolylines() called");

    Map<PolylineId, Polyline> routes = <PolylineId, Polyline>{};
    for (int i = 0; i < encodedRoutes.length; i++) {
      String route = encodedRoutes[i];
      List<PointLatLng> _points = polylinePoints.decodePolyline(route);
      PolylineResult result = PolylineResult(
        errorMessage: '',
        status: 'OK',
        points: _points,
      );
      Polyline polyline = createPolyline(result, i);
      routes[polyline.mapsId] = polyline;
    }
    return routes;
  }

  _handlePolylineTap(PolylineId polylineId) {
    print("_handlePolylineTap() called");
    setState(() {
      for (PolylineId id in _polylines.keys) {
        MarkerId markerId = MarkerId(id.value);
        if (polylineId == id) {
          _polylines[id] = (_polylines[id]?.copyWith(colorParam: Colors.red, zIndexParam: 1))!;
          _markers[markerId] = (_markers[markerId]?.copyWith(
            visibleParam: true,
          ))!;
          currentRouteInfo = (_routeInfo[id])!;
          // currentRouteCarbon = _routeInfo[id]?.carbon;
          print("currentRouteCarbon: $currentRouteInfo.carbon");
        } else {
          _polylines[id] = (_polylines[id]?.copyWith(colorParam: Colors.grey, zIndexParam: 0))!;
          _markers[markerId] = (_markers[markerId]?.copyWith(
            visibleParam: false,
          ))!;
        }
      }
    });
  }

  searchPlaces(String searchTerm) async {
    searchResults = (searchTerm.isEmpty)
        ? _placesService.getRecentSearches()
        : await _placesService.getAutocomplete(searchTerm);
  }

  setSelectedLocation(String placeId, String description, bool moveCamera) async {
    Place place = await _placesService.getPlace(placeId);
    PlaceSearch placeSearch = PlaceSearch(description: description, placeId: placeId);

    if (activeAddressController == null) {
      print("(WARN) activeAddressController null...");
    }

    if (activeAddressController == "start") {
      startAddressController.text = place.name;
      startAddressFocusNode.unfocus();
      setState(() {
        _startAddress = place.name;
        _startPosition = place.geometry.latLng;
        _startPlaceId = placeId;
      });
    } else if (activeAddressController == "dest") {
      destinationAddressController.text = place.name;
      destinationAddressFocusNode.unfocus();
      setState(() {
        _destinationAddress = place.name;
        _destinationPosition = place.geometry.latLng;
        _destinationPlaceId = placeId;
        Marker marker = Marker(
          markerId: const MarkerId('dest'),
          position: _destinationPosition,
        );
        _markers.remove(marker.markerId);
        _markers[marker.markerId] = marker;
      });
    }

    _placesService.newSearchMade(placeSearch);
    activeAddressController = null;

    if (moveCamera) {
      await moveCameraToPosition(
          place.geometry.latLng.latitude, place.geometry.latLng.longitude, 14);
    }
  }

  ElevatedButton makeTravelModeButton(TravelMode travelMode) {
    return ElevatedButton(
      child: Text(
        travelModeToStringPretty[travelMode] ?? 'unknown',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ButtonStyle(
          backgroundColor: (_travelModeSet && _travelMode == travelMode)
              ? MaterialStateProperty.all<Color>(Colors.blue)
              : MaterialStateProperty.all<Color>(Colors.blueAccent.shade100),
          overlayColor: MaterialStateProperty.resolveWith((states) {
            return states.contains(MaterialState.pressed) ? Colors.blueAccent.shade400 : null;
          }),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            // side: const BorderSide(
            //   color: Colors.blueAccent,
            //   width: 2,
            // ),
          ))),
      onPressed: () {
        if (!_travelModeSet || _travelMode != travelMode) _updateTravelModeAndRoutes(travelMode);
      },
    );
  }

  swapStartAndDestination() {
    setState(() {
      String tmpAddress = _startAddress;
      _startAddress = _destinationAddress;
      _destinationAddress = tmpAddress;

      LatLng tmpPosition = _startPosition;
      _startPosition = _destinationPosition;
      _destinationPosition = tmpPosition;

      String tmpPlaceId = _startPlaceId;
      _startPlaceId = _destinationPlaceId;
      _destinationPlaceId = tmpPlaceId;

      String tmpDisplay = startAddressController.text;
      startAddressController.text = destinationAddressController.text;
      destinationAddressController.text = tmpDisplay;

      Marker marker = Marker(
        markerId: const MarkerId('dest'),
        position: _destinationPosition,
      );
      _markers.remove(marker.markerId);
      _markers[marker.markerId] = marker;
      if (_travelModeSet) _updateTravelModeAndRoutes(_travelMode);
    });
  }

  // handleBackTap() async {
  //   setState(() {
  //     _polylines.clear();
  //     print("polylines cleared");
  //   });
  //   await moveCameraToPosition(
  //                 _destinationPosition.latitude,
  //                 _destinationPosition.longitude,
  //                 14);
  // }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        print("Detected tab.");
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: cambridgePosition,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
                startupLogic(); // This logic ensures the map always loads before trying to move the camera, which itself has a currentPosition
              },
              polylines: Set<Polyline>.of(_polylines.values),
              markers: Set.from(_markers.values),
            ),

            //centre button
            SafeArea(
              child: Align(
                alignment: FractionalOffset.bottomRight,
                child: Padding(
                  padding: Platform.isIOS ?
                  const EdgeInsets.only(bottom: 10.0,right: 9.0):
                  const EdgeInsets.only(bottom: 105.0, right: 9.0),
                  child: Container(
                    width: 43,
                    height: 43,
                    decoration:
                        const ShapeDecoration(color: Colors.blue, shape: CircleBorder(), shadows: [
                      BoxShadow(offset: Offset(0, 4), color: Colors.black26, blurRadius: 4.0),
                    ]),
                    child: IconButton(
                      onPressed: () => {moveCameraToCurrentLocation()},
                      icon: const Icon(Icons.my_location),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            //suggestions box background (only show if there is a search):
            if (startAddressFocusNode.hasFocus || destinationAddressFocusNode.hasFocus)
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  backgroundBlendMode: BlendMode.darken,
                ),
              ),

            //search area
            WillPopScope(
              onWillPop: () async {
                print("onWillPop - search area");
                // Intercepts "back" action by user and
                // "add" an extra layer if the user is typing in the search bars
                if (startAddressFocusNode.hasFocus | destinationAddressFocusNode.hasFocus) {
                  FocusScope.of(context).unfocus();
                  return false;
                }
                return true;
              },
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    //column below is for (1) container for search bars and (2) container for prediction results
                    child: Column(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                          ),
                          width: width * 0.9,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                            //column below is for the two search bars + transit options
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                // const Text(
                                //   'Places', ////Done: im not convinced we need this, it uses up a lot of real estate
                                //   style: TextStyle(fontSize: 20.0),
                                // ),
                                // const SizedBox(height: 10),
                                Row(children: <Widget>[
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        child: FloatingActionButton(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Colors.transparent,
                                          elevation: 0,
                                          heroTag: "backBtn",
                                          mini: true,
                                          onPressed: () async {
                                            setState(() {
                                              _polylines.clear();
                                              _markers.clear();
                                              Marker marker = Marker(
                                                  markerId: const MarkerId('dest'),
                                                  position: _destinationPosition);
                                              _markers[marker.markerId] = marker;
                                              print("polylines cleared");
                                            });
                                            await moveCameraToPosition(
                                                _destinationPosition.latitude,
                                                _destinationPosition.longitude,
                                                14);
                                          },
                                          child: const Icon(Icons.keyboard_backspace),
                                        ),
                                      ),
                                      // SizedBox(
                                      //   width: 18,
                                      //   child: IconButton(
                                      //     icon: const Icon(
                                      //         Icons.keyboard_backspace),
                                      //     onPressed: handleBackTap,
                                      //   ),
                                      // ),
                                      const SizedBox(height: 60),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        _textField(
                                            label: 'Start',
                                            hint: 'Choose starting point',
                                            // prefixIcon: const Icon(Icons.looks_one),
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.my_location),
                                              onPressed: () async {
                                                startAddressController.text = _currentAddress;
                                                _startAddress = _currentAddress;
                                                await setSelectedLocation(
                                                    _startPlaceId, _startAddress, false);
                                                activeAddressController = null;
                                              },
                                            ),
                                            controller: startAddressController,
                                            focusNode: startAddressFocusNode,
                                            width: width,
                                            onChanged: (String value) {
                                              //// DONE: should probably call locationCallback something else, it does more than just deal with location
                                              setState(() {
                                                _startAddress = value;
                                                ////DONE: should we be doing the above every time the user presses a new key?
                                                searchPlaces(value);
                                              });
                                            }),
                                        const SizedBox(height: 10),
                                        _textField(
                                            label: 'Destination',
                                            hint: 'Choose destination',
                                            // prefixIcon: const Icon(Icons.looks_two),
                                            controller: destinationAddressController,
                                            focusNode: destinationAddressFocusNode,
                                            width: width,
                                            onChanged: (String value) {
                                              setState(() {
                                                _destinationAddress = value;
                                                searchPlaces(value);
                                              });
                                            }),
                                      ],
                                    ),
                                  ),
                                  FloatingActionButton(
                                    heroTag: "revertBtn",
                                    mini: true,
                                    onPressed: () => {swapStartAndDestination()},
                                    child: const Icon(Icons.change_circle),
                                    ////DONE: centre (UK) or center (US)? (or shall we just use an icon :P)
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                ]),

                                //spacer
                                // const SizedBox(height: 10),

                                if (_startAddress != "" &&
                                    _destinationAddress != "" &&
                                    !startAddressFocusNode.hasFocus &&
                                    !destinationAddressFocusNode.hasFocus)
                                  //row containing transit options
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: selectedTransports,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        //adds spacing between the search bars and results
                        const SizedBox(height: 10),

                        //suggestions list (only show if there is a search):
                        if (startAddressFocusNode.hasFocus || destinationAddressFocusNode.hasFocus)
                          ListView.builder(
                            shrinkWrap: true,
                            itemBuilder: ((context, index) {
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                                color: Colors.black.withOpacity(0.7),
                                child: ListTile(
                                  title: Text(searchResults[index].description,
                                      style: const TextStyle(color: Colors.white)),
                                  onTap: () async {
                                    await setSelectedLocation(searchResults[index].placeId,
                                        searchResults[index].description, true);
                                    activeAddressController = null;
                                  },
                                ),
                              );
                            }),
                            itemCount: min(3, searchResults.length),
                            //TODO: do we need more than 3?
                          ),
                        //TODO: how to display things based on the changes from settings
                        /*ValueChangeObserver(
                            cacheKey: 'key-distance',
                            defaultValue: 'km',
                            builder: (_, _distanceUnits, __) => Center(
                                    child: Container(
                                  margin: const EdgeInsets.all(10.0),
                                  color: Colors.amber[600],
                                  width: 48.0,
                                  height: 48.0,
                                  child: Text(Settings.getValue('key-distance', 'km')),
                                )))*/
                      ],
                    ),
                  ),
                ),
              ),
            ),

            //centre button

            //settings button
            SafeArea(
              child: Align(
                alignment: FractionalOffset.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, left: 10.0),
                  child: FloatingActionButton(
                    heroTag: "settingsBtn",
                    backgroundColor: Colors.grey,
                    mini: true,
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(
                            onClose: updateSelectedTransports,
                          ),
                        ),
                      ),
                    },
                    child: const Icon(Icons.settings),
                  ),
                ),
              ),
            ),

            //start route button
            if (_polylines.isNotEmpty && canClickStart)
              SafeArea(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.blue,
                      ),
                      width: width / 3,
                      height: height / 10,
                      child: IconButton(
                        color: Colors.white,
                        iconSize: 40.0,
                        onPressed: () {
                          setState(() {
                            double carAverage = 175.62 * currentRouteInfo.distance;
                            print("car carbon: $carAverage");
                            double currentCarbon = currentRouteInfo.carbon + 0.0;
                            print("currentRoute carbon: $currentCarbon");
                            double tmpSaved = carAverage - currentCarbon;
                            print("saved: $tmpSaved");
                            savedCarbon += tmpSaved;
                            prefs.setDouble("savedCarbon", savedCarbon);
                            print("savedCarbon: $savedCarbon");
                            moveCameraToPosition(
                                _startPosition.latitude, _startPosition.longitude, 16);
                            canClickStart = false;
                          });
                          // carbonS_CarbonStatsState.carbonSaved = 0;
                        },
                        icon: const Icon(Icons.play_arrow),
                        //child: const Text("START"),
                      ),
                    ),
                  ),
                ),
              ),

            //carbonSaved button
            SafeArea(
              child: Align(
                // alignment: FractionalOffset.bottomCenter,
                alignment: (_polylines.isNotEmpty && canClickStart)
                    ? FractionalOffset.bottomLeft
                    : FractionalOffset.bottomCenter,
                child: Padding(
                  padding: (_polylines.isNotEmpty && canClickStart)
                      ? const EdgeInsets.only(bottom: 60.0, left: 10.0)
                      : const EdgeInsets.only(bottom: 10.0),
                  child: FloatingActionButton(
                    heroTag: "carbonSavedBtn",
                    backgroundColor: Colors.lightGreen,
                    mini: (_polylines.isNotEmpty && canClickStart) ? true : false,
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CarbonStats()),
                      ),
                    },
                    child: const Icon(Icons.eco),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
