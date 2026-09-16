import 'package:equatable/equatable.dart';

enum LocationStatus {
  initial,
  loading,
  success,
  selected,
  submitted,
  failure,
}

class LocationState extends Equatable {
  final LocationStatus status;

  final List<String> locations;

  final String? selectedLocation;

  final String? errorMessage;

  const LocationState({
    this.status = LocationStatus.initial,
    this.locations = const [],
    this.selectedLocation,
    this.errorMessage,
  });

  LocationState copyWith({
    LocationStatus? status,
    List<String>? locations,
    String? selectedLocation,
    String? errorMessage,
  }) {
    return LocationState(
      status: status ?? this.status,
      locations: locations ?? this.locations,
      selectedLocation:
      selectedLocation ?? this.selectedLocation,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    locations,
    selectedLocation,
    errorMessage,
  ];
}