class LocationRepository {
  Future<List<String>> searchLocations(
      String query,
      ) async {


    if (query.isEmpty) {
      return [];
    }


    final locations = [
      'Nagercoil, Tamil Nadu, India',
      'Chennai, Tamil Nadu, India',
      'Coimbatore, Tamil Nadu, India',
      'London, United Kingdom',
      'New York, United States',
      'Dubai, United Arab Emirates',
      'Tokyo, Japan',
      'Paris, France',
      'Singapore',
    ];

    return locations
        .where(
          (location) => location
          .toLowerCase()
          .contains(query.toLowerCase()),
    )
        .toList();
  }
}