import 'dart:developer';

class Car {
  String brand = "", model = "", fuel = "", size = "";

  Car(this.brand, this.model, this.fuel);
  Car.fromSize(this.size);

  factory Car.fromJson(dynamic parsedJson) {
    return Car(
        parsedJson['brand'] as String, parsedJson['model'] as String, parsedJson['fuel'] as String);
  }

  @override
  String toString() {
    if (this.brand != "")
      return this.brand + " " + this.model + ", " + this.fuel;
    else
      return "Default (" + this.size + ")";
  }
}
