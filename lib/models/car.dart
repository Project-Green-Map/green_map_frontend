import 'dart:developer';

class Car {
  String brand = "", model = "", fuel = "", size = "";

  Car(this.brand, this.model, this.fuel);
  Car.fromSize(this.size);

  factory Car.fromJson(dynamic parsedJson) {
    return Car(
        parsedJson['brand'] as String, parsedJson['model'] as String, parsedJson['fuel'] as String);
  }
}

class CarsList {
  final List<Car> cars;

  CarsList(this.cars);

  CarsList.fromJson(Map<String, dynamic> json) : cars = List<Car>.from(json['cars']);
}
