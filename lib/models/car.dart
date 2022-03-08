class Car {
  String brand = "", model = "", fuel = "", size = "";

  Car(this.brand, this.model, this.fuel);
  Car.fromSize(this.size);

  factory Car.fromJson(dynamic parsedJson) {
    return Car(
        parsedJson['brand'] as String, parsedJson['model'] as String, parsedJson['fuel'] as String);
  }

  Map<String, dynamic> toJson() {
    return {"brand": brand, "model": model, "fuel": fuel, "size": size};
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
