import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}


// Search for a location
class SearchLocationEvent extends LocationEvent {
  final String query;

  const SearchLocationEvent({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}


// User selected a location
class SelectLocationEvent extends LocationEvent {
  final String location;

  const SelectLocationEvent({
    required this.location,
  });

  @override
  List<Object?> get props => [location];
}



class SubmitLocationEvent extends LocationEvent {
  const SubmitLocationEvent();
}
class ClearLocationSearchEvent extends LocationEvent {
  const ClearLocationSearchEvent();
}