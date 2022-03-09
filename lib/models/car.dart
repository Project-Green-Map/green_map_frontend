import 'dart:convert';

import 'dart:developer';

class Car {
  String brand = "", model = "", fuel = "", size = "";

  Car(this.brand, this.model, this.fuel);
  Car.fromSize(this.size);

  factory Car.fromJson(dynamic parsedJson) {
    print('1111111111111111111111111111');
    if (!parsedJson.containsKey('size') || parsedJson['size'] == "") {
      return Car(parsedJson['brand'] as String, parsedJson['model'] as String,
          parsedJson['fuel'] as String);
    } else {
      print("shitttttttttttttttttttttttttttttttttttttttttttttttttt");
      return Car.fromSize(parsedJson['size']);
    }
  }

  String toJSON() {
    dynamic data = {'brand': brand, 'model': model, 'fuel': fuel, 'size': size};
    return jsonEncode(data);
  }

  @override
  bool operator ==(covariant Car otherCar) {
    return brand == otherCar.brand &&
        model == otherCar.model &&
        fuel == otherCar.fuel &&
        size == otherCar.size;
  }

  @override
  String toString() {
    if (brand != "") {
      return brand + " " + model + " - " + fuel[0] + fuel.substring(1, fuel.length).toLowerCase();
    } else {
      return "Default (" + size + ")";
    }
  }
}
