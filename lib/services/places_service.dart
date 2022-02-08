import 'package:http/http.dart' as http;
import 'dart:convert' as convert; // package for converting between file types
import 'package:flutter/services.dart' show rootBundle;

import 'package:map/models/place_search.dart';
import 'package:map/secrets.dart';

//this class should deal with all direct communication with the Places API

class PlacesService {
  final key = Secrets.API_KEY;
  Future<List<PlaceSearch>> getAutocomplete(String search) async {
    //!Uncomment for real data
    //Uri uri = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$search&key=$key');
    //var response = await http.get(uri);
    //var json = convert.jsonDecode(response.body);

    //!Comment to remove dummy data
    var response =
        await rootBundle.loadString('../dummy_data/places_request.json');
    var json = convert.jsonDecode(response);

    var jsonResults = json['predictions'] as List;
    return jsonResults.map((place) => PlaceSearch.fromJson(place)).toList();
  }
}
