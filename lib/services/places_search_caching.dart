import 'package:map/models/place_search.dart';

//*uses a least-recently-used replacement-policy cache to store the 50 most-recently searched terms.
const cacheSize = 50;

class CacheManager {
  Map<String, List<PlaceSearch>> cache = {};
  List<String> mostRecent = [];

  List<PlaceSearch> getFromCache(String search) {
    List<PlaceSearch> result = [];

    if (cache.containsKey(search)) {
      result = cache[search] ?? [];
      _pushToFront(search);
    }
    return result;
  }

  void addToCache(String search, List<PlaceSearch> places) {
    _pushToFront(search);
    if (!cache.containsKey(search)) {
      cache[search] = places;
      while (cache.length > cacheSize) {
        //can realistically only happen once, but for initialisation errors it's safer to use while over if
        cache.remove(mostRecent.last);
        mostRecent.remove(mostRecent.last);
      }
    }
  }

  void _pushToFront(String search) {
    mostRecent.remove(search); //safe if it doesn't exist
    mostRecent.insert(0, search);
  }

  void flushCache() {
    cache = {};
  }
}
