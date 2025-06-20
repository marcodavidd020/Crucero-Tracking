import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

// Estado del mapa del empleado
class MapState {
  final bool isServiceActive;
  final bool followMicro;
  final Position? currentPosition;
  final bool isCreatingMarker;
  final Symbol? currentLocationSymbol;
  final Line? routeLine;
  final bool mapReady;

  const MapState({
    this.isServiceActive = false,
    this.followMicro = true,
    this.currentPosition,
    this.isCreatingMarker = false,
    this.currentLocationSymbol,
    this.routeLine,
    this.mapReady = false,
  });

  MapState copyWith({
    bool? isServiceActive,
    bool? followMicro,
    Position? currentPosition,
    bool? isCreatingMarker,
    Symbol? currentLocationSymbol,
    Line? routeLine,
    bool? mapReady,
  }) {
    return MapState(
      isServiceActive: isServiceActive ?? this.isServiceActive,
      followMicro: followMicro ?? this.followMicro,
      currentPosition: currentPosition ?? this.currentPosition,
      isCreatingMarker: isCreatingMarker ?? this.isCreatingMarker,
      currentLocationSymbol: currentLocationSymbol ?? this.currentLocationSymbol,
      routeLine: routeLine ?? this.routeLine,
      mapReady: mapReady ?? this.mapReady,
    );
  }
}

// Provider del estado del mapa
class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());

  void setServiceActive(bool active) {
    state = state.copyWith(isServiceActive: active);
  }

  void setFollowMicro(bool follow) {
    state = state.copyWith(followMicro: follow);
  }

  void setCurrentPosition(Position? position) {
    state = state.copyWith(currentPosition: position);
  }

  void setCreatingMarker(bool creating) {
    state = state.copyWith(isCreatingMarker: creating);
  }

  void setCurrentLocationSymbol(Symbol? symbol) {
    state = state.copyWith(currentLocationSymbol: symbol);
  }

  void setRouteLine(Line? line) {
    state = state.copyWith(routeLine: line);
  }

  void setMapReady(bool ready) {
    state = state.copyWith(mapReady: ready);
  }

  void resetMarkerState() {
    state = state.copyWith(
      currentLocationSymbol: null,
      isCreatingMarker: false,
    );
  }
}

final mapStateProvider = StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  return MapStateNotifier();
}); 