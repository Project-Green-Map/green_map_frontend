import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart'; //only use for Position objects. add functionality via geolocator_service.dart
import 'package:map/models/place.dart';
import 'package:map/models/place_search.dart';
import 'package:map/services/places_service.dart';
import 'package:map/services/routing_service.dart';
import 'package:map/settings.dart';

import 'dart:math' show cos, sqrt, asin, min;

import './services/geolocator_service.dart';
import './services/geocoding_service.dart';

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
  late GoogleMapController mapController;

  late Position _currentPosition;
  String _currentAddress = '';

  String _startAddress = '';
  String _destinationAddress = '';
  LatLng _startPosition = LatLng(0, 0);
  LatLng _destinationPosition = LatLng(0, 0);
  String _startPlaceId = '';
  String _destinationPlaceId = '';

  final CameraPosition cambridgePosition = const CameraPosition(
    target: LatLng(52.2053, 0.1218),
    zoom: 14,
  );

  final int _routeNum = 3;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  String? activeAddressController;

  final startAddressFocusNode = FocusNode();
  final destinationAddressFocusNode = FocusNode();

  final _geolocatorService = GeolocatorService();
  final _geocodingService = GeocodingService();
  final _routingService = RoutingService();
  final _placesService = PlacesService();

  late TravelMode _travelMode = TravelMode.walking; // default to be walking

  List<PlaceSearch> searchResults = [];
  final polylinePoints = PolylinePoints();

  // Set<Marker> _markers = {};
  Map<MarkerId, Marker> _markers = {};

  // late PolylinePoints polylinePoints;
  // List<LatLng> polylineCoordinates = [];
  // Set<Polyline> _polylines = Set<Polyline>();

  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};

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
  }

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required double width,
    required Icon prefixIcon,
    Widget? suffixIcon,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: width * 0.8,
      child: TextField(
        onChanged: onChanged,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: prefixIcon,
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
    // _destinationPosition = LatLng(52.207099555585565, 0.1130482077789624);
    print("initState() called");
  }

  void startupLogic() async {
    //called when the map is finished loading
    print("startupLogic() called");

    await updateCurrentLocation();
    String _placeIdTmp = await _geocodingService.getPlaceIdFromCoordinates(
        _currentPosition.latitude, _currentPosition.longitude);

    setState(() {
      _startPosition =
          LatLng(_currentPosition.latitude, _currentPosition.longitude);
      _startPlaceId = _placeIdTmp;
      print("start up placeId: $_startPlaceId");
    });

    await _geocodingService.getPlaceIdFromCoordinates(
        _startPosition.latitude, _startPosition.longitude);

    moveCameraToCurrentLocation();
    // await _createPolyline_debug();
    // print("_createPolyline_debug() called");
    // Marker marker = Marker(
    //     markerId: MarkerId('Byron Burger'),
    //     position: _destinationPosition,
    //     infoWindow: InfoWindow(
    //       title: 'Byron Burger',
    //       snippet: '12 Bridge St, Cambridge CB2 1UF',
    //     ));
    // setState(() {
    //   _markers.add(marker);
    // });
    // await _createPolylines(
    //     _startPosition?.latitude ?? -1,
    //     _startPosition?.latitude ?? -1,
    //     _destinationPosition.latitude,
    //     _destinationPosition.longitude,
    //     _travelMode);
  }

  //in an effort to save API requests, only call when necessary
  updateCurrentLocation() async {
    await _geolocatorService.getCurrentLocation().then((position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
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
          List<String?> placeTags = [
            place.name,
            place.locality,
            place.postalCode,
            place.country
          ];
          for (int i = 0; i < placeTags.length; i++) {
            if (placeTags.elementAt(i)?.isNotEmpty ?? false) {
              _currentAddress += "${placeTags.elementAt(i)}";
            }

            if (isFirst) {
              isFirst = false;
            } else {
              _currentAddress += ", ";
            }
          }

          print("Current address: $_currentAddress");
          startAddressController.text = _currentAddress;
          _startAddress = _currentAddress;
        }
      });
    });
  }

  void moveCameraToPosition(double lat, double long, double zoom) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, long),
          zoom: zoom,
        ),
      ),
    );
  }

  _updateTravelModeAndRoutes(travelMode) async {
    setState(() {
      _travelMode = travelMode;
      _polylines.clear();
      // polylineCoordinates.clear();
    });
    await _createMultiplePolylines(
        _startPlaceId, _destinationPlaceId, travelMode, _routeNum);
    // await _createPolylines_debug(_startPosition.latitude, _startPosition.longitude,
    //     _destinationPosition.latitude, _destinationPosition.longitude, travelMode);
  }

  void moveCameraToCurrentLocation() async {
    moveCameraToPosition(
        _currentPosition.latitude, _currentPosition.longitude, 14);
  }

  // LatLng middlePoint;

  _createMultiplePolylines(
      startPlaceId, destinationPlaceId, travelMode, num) async {
    print("_createMultiplePolylines() called");
    List<String> encodedRoutes =
        await _routingService.getMultipleEncodedRoutesFromPlaceId(
            startPlaceId, destinationPlaceId, travelMode, num);
    // Map<PolylineId, Polyline> polylines = await _routingService.getMultipleRouteFromPlaceId(
    //     startPlaceId, destinationPlaceId, travelMode, num);

    Map<PolylineId, Polyline> polylines = decodePolylines(encodedRoutes);
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
    Color routeColor = id == 0 ? Colors.red : Colors.orange;
    PolylineId polylineId = PolylineId('route_$id');
    return Polyline(
      width: 5,
      polylineId: polylineId,
      consumeTapEvents: true,
      color: Colors.grey,
      points: polylineCoordinates,
      jointType: JointType.round,
      zIndex: 0,
      onTap: () => _handlePolylineTap(polylineId),
      // patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    );
  }

  Map<PolylineId, Polyline> decodePolylines(List<String> encodedRoutes) {
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
      for(PolylineId id in _polylines.keys){
        if(polylineId == id){
          _polylines[id] = (_polylines[id]?.copyWith(colorParam:Colors.red, zIndexParam: 1))!;
        }
        else{
          _polylines[id] = (_polylines[id]?.copyWith(colorParam:Colors.grey, zIndexParam: 0))!;
        }
      }
    });
  }

  // _createPolylines_debug(double startLatitude, double startLongitude, double destinationLatitude,
  //     double destinationLongitude, TravelMode travelMode) async {
  //
  //
  //
  //   PolylineResult result;
  //   if (_startPlaceId == '' || _destinationPlaceId == '') {
  //     print("(WARN) Sending coordinates to API, not placeID...");
  //     result = await _routingService.getRouteFromCoordinates_debug(
  //         startLatitude, startLongitude, destinationLatitude, destinationLongitude, travelMode);
  //   } else {
  //     result = await _routingService.getRouteFromPlaceId_debug(
  //         _startPlaceId, _destinationPlaceId, travelMode);
  //   }
  //
  //   if (result.status == 'OK') {
  //     // if (result.points.isNotEmpty) {
  //     // int len = result.points.length;
  //     // int cnt = 0;
  //     for (var point in result.points) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //       // cnt ++;
  //       // if (cnt == len / 2){
  //       //
  //       // }
  //     }
  //   }
  //
  //   setState(() {
  //     _polylines.add(Polyline(
  //       width: 5,
  //       polylineId: PolylineId('route_1'),
  //       color: Colors.red,
  //       points: polylineCoordinates,
  //     ));
  //   });
  //
  //   print("Polylines (debug) computed");
  // }

  // // Create the polylines for showing the route between two places
  // _createPolylines(double startLatitude, double startLongitude, double destinationLatitude,
  //     double destinationLongitude, TravelMode travelMode) async {
  //   print("_createPolylines() called");
  //
  //   PolylineResult result = await _routingService.getRouteFromCoordinates(
  //       startLatitude, startLongitude, destinationLatitude, destinationLongitude, travelMode);
  //
  //   if (result.status == 'OK') {
  //     // if (result.points.isNotEmpty) {
  //     for (var point in result.points) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     }
  //   }
  //
  //   setState(() {
  //     _polylines.add(Polyline(
  //       width: 5,
  //       polylineId: PolylineId('route_1'),
  //       color: Colors.red,
  //       points: polylineCoordinates,
  //     ));
  //   });
  //
  //   print("Polylines computed");
  // }

  searchPlaces(String searchTerm) async {
    searchResults = (searchTerm.isEmpty)
        ? []
        : await _placesService.getAutocomplete(searchTerm);
  }

  setSelectedLocation(String placeId, bool moveCamera) async {
    Place place = await _placesService.getPlace(placeId);

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
        Marker marker = Marker(
          markerId: MarkerId('start'),
          position: _startPosition,
        );
        _markers.remove(marker.markerId);
        _markers[marker.markerId] = marker;
      });
    } else if (activeAddressController == "dest") {
      destinationAddressController.text = place.name;
      destinationAddressFocusNode.unfocus();
      setState(() {
        _destinationAddress = place.name;
        _destinationPosition = place.geometry.latLng;
        _destinationPlaceId = placeId;
        Marker marker = Marker(
          markerId: MarkerId('dest'),
          position: _destinationPosition,
        );
        _markers.remove(marker.markerId);
        _markers[marker.markerId] = marker;
      });
    }

    activeAddressController = null;

    if (moveCamera) {
      moveCameraToPosition(
          place.geometry.latLng.latitude, place.geometry.latLng.longitude, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: cambridgePosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              startupLogic(); // This logic ensures the map always loads before trying to move the camera, which itself has a currentPosition
            },
            polylines: Set<Polyline>.of(_polylines.values),
            markers: Set.from(_markers.values),
          ),

          //suggestions box background (only show if there is a search):
          if (startAddressFocusNode.hasFocus ||
              destinationAddressFocusNode.hasFocus)
            Container(
              height: height / 1.3,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                backgroundBlendMode: BlendMode.darken,
              ),
            ),

          //search area
          SafeArea(
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
                            const SizedBox(height: 10),
                            _textField(
                                label: 'Start',
                                hint: 'Choose starting point',
                                prefixIcon: const Icon(Icons.looks_one),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.my_location),
                                  onPressed: () {
                                    startAddressController.text =
                                        _currentAddress;
                                    _startAddress = _currentAddress;
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
                                prefixIcon: const Icon(Icons.looks_two),
                                controller: destinationAddressController,
                                focusNode: destinationAddressFocusNode,
                                width: width,
                                onChanged: (String value) {
                                  setState(() {
                                    _destinationAddress = value;
                                    searchPlaces(value);
                                  });
                                }),

                            //spacer
                            const SizedBox(height: 10),

                            if (_startAddress != "" &&
                                _destinationAddress != "" &&
                                !startAddressFocusNode.hasFocus &&
                                !destinationAddressFocusNode.hasFocus)
                              //row containing transit options
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton(
                                      child: const Text(
                                        "Walk",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ))),
                                      onPressed: () => {
                                        _updateTravelModeAndRoutes(
                                            TravelMode.walking)
                                      },
                                    ),
                                    TextButton(
                                      child: const Text(
                                        "Transit",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ))),
                                      onPressed: () => {
                                        _updateTravelModeAndRoutes(
                                            TravelMode.transit)
                                      },
                                    ),
                                    TextButton(
                                      child: const Text(
                                        "Drive",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      style: ButtonStyle(
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ))),
                                      onPressed: () => {
                                        _updateTravelModeAndRoutes(
                                            TravelMode.driving)
                                      },
                                    ),
                                    TextButton(
                                      child: const Text(
                                        "Cycle",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      style: ButtonStyle(
                                        shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18.0),
                                            side: const BorderSide(
                                              color: Colors.blueAccent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      onPressed: () => {
                                        _updateTravelModeAndRoutes(
                                            TravelMode.bicycling)
                                      },
                                    ),
                                  ]),
                          ],
                        ),
                      ),
                    ),

                    //adds spacing between the search bars and results
                    SizedBox(height: 10),

                    //suggestions list (only show if there is a search):
                    if (startAddressFocusNode.hasFocus ||
                        destinationAddressFocusNode.hasFocus)
                      ListView.builder(
                        shrinkWrap: true,
                        itemBuilder: ((context, index) {
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 10),
                            color: Colors.black.withOpacity(0.7),
                            child: ListTile(
                              title: Text(searchResults[index].description,
                                  style: TextStyle(color: Colors.white)),
                              onTap: () async {
                                await setSelectedLocation(
                                    searchResults[index].placeId, true);
                                activeAddressController = null;
                              },
                            ),
                          );
                        }),
                        itemCount: min(3, searchResults.length),
                        //TODO: do we need more than 3?
                      ),
                  ],
                ),
              ),
            ),
          ),

          //centre button
          SafeArea(
            child: Align(
              alignment: FractionalOffset.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: FloatingActionButton(
                  heroTag: "centreBtn",
                  onPressed: () => {moveCameraToCurrentLocation()},
                  child: const Icon(Icons.my_location),
                  ////DONE: centre (UK) or center (US)? (or shall we just use an icon :P)
                ),
              ),
            ),
          ),

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
                      MaterialPageRoute(builder: (context) => const Settings()),
                    ),
                  },
                  child: const Icon(Icons.settings),
                  ////DONE: centre (UK) or center (US)? (or shall we just use an icon :P)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//TODO: check how much money the Places API is getting through ;)
