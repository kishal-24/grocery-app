import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/location_repository.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository locationRepository;

  LocationBloc({
    required this.locationRepository,
  }) : super(const LocationState()) {

    on<SearchLocationEvent>((event, emit) async {
      if (event.query.trim().isEmpty) {
        emit(
          state.copyWith(
            status: LocationStatus.initial,
            locations: [],
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: LocationStatus.loading,
          errorMessage: null,
        ),
      );

      try {
        final locations =
        await locationRepository.searchLocations(event.query);

        emit(
          state.copyWith(
            status: LocationStatus.success,
            locations: locations,
            errorMessage: null,
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: LocationStatus.failure,
            errorMessage: 'Unable to search location.',
          ),
        );
      }
    });

    on<SelectLocationEvent>((event, emit) {
      emit(
        state.copyWith(
          status: LocationStatus.selected,
          selectedLocation: event.location,
          errorMessage: null,
          locations: [],
        ),
      );
    });


    on<SubmitLocationEvent>((event, emit) {
      if (state.selectedLocation == null ||
          state.selectedLocation!.isEmpty) {
        emit(
          state.copyWith(
            status: LocationStatus.failure,
            errorMessage: 'Please select your location.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: LocationStatus.submitted,
          errorMessage: null,
        ),
      );
    });

    on<ClearLocationSearchEvent>((event, emit) {
      emit(
        state.copyWith(
          status: LocationStatus.initial,
          locations: [],
          selectedLocation: null,
          errorMessage: null,
        ),
      );
    });
  }
}