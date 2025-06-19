
import 'package:geolocator/geolocator.dart';

Future<bool> verificarGpsHabilitado() async {
  bool serviciosHabilitados =  await Geolocator.isLocationServiceEnabled();
  if(!serviciosHabilitados) return false;
  LocationPermission permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    permiso = await Geolocator.requestPermission();
    if (permiso == LocationPermission.denied) return false;
  }
  if (permiso == LocationPermission.deniedForever) return false;
  return true;
}
//
// Stream<Position> positionStream = Geolocator.getPositionStream(
//     locationSettings: LocationSettings(
//       accuracy: LocationAccuracy.high,
//       // distanceFilter: 10
//     )
// );
//
// void iniciarSeguimiento() async {
//   await verificarGpsHabilitado();
//   positionStream.listen((Position position){
//     print('Ubicación actual: ${position.latitude}, ${position.longitude}');
//   });
// }