import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/car_model.dart';

part 'popular_car_notitfier.g.dart';

@riverpod
class PopularCars extends _$PopularCars {
  bool _ascending = true;

  @override
  List<CarModel> build() {
    return [
      CarModel(
        pickupLocation: "1901 Thornridge Cir. Shiloh",
        dropLocation: "4140 Parker Rd. Allentown",
        dateTime: "16 July 2025, 10:30 PM",
        driver: "Jane Cooper",
        seats: 4,
        isPaid: true,
      ),
      CarModel(
        pickupLocation: "1901 Thornridge Cir. Shiloh",
        dropLocation: "4140 Parker Rd. Allentown",
        dateTime: "16 July 2025, 10:30 PM",
        driver: "Jane Cooper",
        seats: 4,
        isPaid: false,
      ),
    ];
  }

  bool get isAscending => _ascending;

  void toggleSort() {
    _ascending = !_ascending;
    state = state.reversed.toList();
  }
}
