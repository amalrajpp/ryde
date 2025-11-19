// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_car_notitfier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PopularCars)
const popularCarsProvider = PopularCarsProvider._();

final class PopularCarsProvider
    extends $NotifierProvider<PopularCars, List<CarModel>> {
  const PopularCarsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'popularCarsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$popularCarsHash();

  @$internal
  @override
  PopularCars create() => PopularCars();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<CarModel> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<CarModel>>(value),
    );
  }
}

String _$popularCarsHash() => r'821ac3808493a9e14170718d24824f8ad37c57a3';

abstract class _$PopularCars extends $Notifier<List<CarModel>> {
  List<CarModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<CarModel>, List<CarModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<CarModel>, List<CarModel>>,
              List<CarModel>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
