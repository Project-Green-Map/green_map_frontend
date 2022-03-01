import 'package:map/models/place_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

//*uses a least-recently-used write-through cache to store the 200 most-recently searched terms.
const int maxCacheSize = 200;

//might rewrite with CacheEntry extends MapEntry, but it works for now

class CacheEntry {
  final String place;
  final List<PlaceSearch> predictions;

  CacheEntry({required this.place, required this.predictions});

  factory CacheEntry.fromString(String str) {
    List<String> splits = str.split('\n');
    List<PlaceSearch> predicts = [];
    for (int i = 1; splits[i].isNotEmpty; i += 2) {
      predicts.add(PlaceSearch(placeId: splits[i], description: splits[i + 1]));
    }

    return CacheEntry(place: splits[0], predictions: predicts);
  }

  @override
  String toString() {
    //uses newlines as separators, as they can't be typed by user. one \n between each setting, two \ns marks the end
    String str = place + '\n';
    for (PlaceSearch ps in predictions) {
      str += ps.placeId + '\n' + ps.description + '\n';
    }
    return str + '\n';
  }
}

class CacheManager {
  Map<String, List<PlaceSearch>> cache = {};
  List<String> mostRecent = [];
  late SharedPreferences prefs;

  CacheManager() {
    _onStart();
  }

  void _onStart() async {
    //fill cache from local storage, if it exists
    prefs = await SharedPreferences.getInstance();
    //flushCache();
    bool cacheExists = prefs.getBool('searchCacheExists') ?? false;

    if (cacheExists) {
      //load locally stored cache
      List<String> cacheEntries = prefs.getStringList('searchCache') ?? [];
      for (String str in cacheEntries) {
        CacheEntry entry = CacheEntry.fromString(str);
        cache[entry.place] = entry.predictions;
      }
      mostRecent = prefs.getStringList('searchMostRecent') ?? [];
    } else {
      //first run, so generate local settings
      prefs.setBool('searchCacheExists', true);
      prefs.setInt('searchCacheLength', 0);
      prefs.setStringList('searchCache', []);
      prefs.setStringList('searchMostRecent', []);
    }
  }

  List<PlaceSearch> getFromCache(String search) {
    List<PlaceSearch> result = [];

    if (cache.containsKey(search)) {
      result = cache[search] ?? [];
      _pushToFront(search);
    }
    return result;
  }

  Future<void> addToCache(String search, List<PlaceSearch> predicts) {
    _pushToFront(search);
    if (!cache.containsKey(search)) {
      cache[search] = predicts;

      while (cache.length > maxCacheSize) {
        //can realistically only happen once, but for initialisation errors it's safer to use while over if
        String last = mostRecent.last;
        cache.remove(last);
        mostRecent.remove(last);
      }
    }
    _setLocalData();
    return Future<void>(() {});
  }

  void flushCache() {
    cache = {};
    mostRecent = [];
    prefs.setStringList('searchCache', []);
    prefs.setStringList('searchMostRecent', []);
  }

  void _pushToFront(String search) {
    //only acts on app data
    mostRecent.remove(search); //safe if it doesn't exist
    mostRecent.insert(0, search);
  }

  List<String> _cacheAsString() {
    return cache.entries
        .map((e) => CacheEntry(place: e.key, predictions: e.value).toString())
        .toList();
  }

  Future<void> _setLocalData() {
    prefs.setStringList('searchCache', _cacheAsString());
    prefs.setStringList('searchMostRecent', mostRecent);
    return Future<void>(() {});
  }

  //call only on **complete** searches, not on all searches
  Future<void> updateMostRecentSearches(PlaceSearch ps) {
    List<String> recent = prefs.getStringList('mostRecentSearches') ?? [];
    if (recent.contains(ps.description)) {
      recent.remove(ps.description);
      recent.remove(ps.placeId);
      recent.insert(0, ps.description);
      recent.insert(1, ps.placeId);
    } else {
      if (recent.length < 5) {
        recent.insert(0, ps.description);
        recent.insert(1, ps.placeId);
      } else {
        recent.removeLast();
        recent.removeLast();
        recent.insert(0, ps.description);
        recent.insert(1, ps.placeId);
      }
    }
    prefs.setStringList('mostRecentSearches', recent);

    return Future<void>(() {});
  }

  List<PlaceSearch> getMostRecentSearches() {
    List<String> recent = prefs.getStringList('mostRecentSearches') ?? [];
    List<PlaceSearch> psList = [];
    for (int i = 0; i < recent.length / 2; i++) {
      psList.add(PlaceSearch(description: recent[i * 2], placeId: recent[i * 2 + 1]));
    }
    return psList;
  }

  /*Map<String, List<PlaceSearch>> getMostRecentSearches() {
    Map<String, List<PlaceSearch>> map = {};
    List<String> recent = prefs.getStringList('mostRecentSearches') ?? [];
    for (String str in recent) {
      CacheEntry ce = CacheEntry.fromString(str);
      map[ce.place] = ce.predictions;
    }

    return map;
  }*/
}
