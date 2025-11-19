// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CarModel {
  final String pickupLocation;
  final String dropLocation;
  final String dateTime;
  final String driver;
  final int seats;
  final bool isPaid;

  CarModel({
    required this.pickupLocation,
    required this.dropLocation,
    required this.dateTime,
    required this.driver,
    required this.seats,
    required this.isPaid,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'dateTime': dateTime,
      'driver': driver,
      'seats': seats,
      'isPaid': isPaid,
    };
  }

  factory CarModel.fromMap(Map<String, dynamic> map) {
    return CarModel(
      pickupLocation: map['pickupLocation'] as String,
      dropLocation: map['dropLocation'] as String,
      dateTime: map['dateTime'] as String,
      driver: map['driver'] as String,
      seats: map['seats'] as int,
      isPaid: map['isPaid'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory CarModel.fromJson(String source) => CarModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
