import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class PlaceService {
  final String apiKey;

  PlaceService(this.apiKey);

  Future<List<PlacePrediction>> getSuggestions(
    String input,
    String sessionToken,
  ) async {
    if (input.isEmpty) return [];

    final String request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&sessiontoken=$sessionToken';

    final response = await http.get(Uri.parse(request));

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        return (result['predictions'] as List)
            .map((p) => PlacePrediction.fromJson(p))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') return [];
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestions');
    }
  }
}
