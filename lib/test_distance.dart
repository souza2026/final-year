import 'package:latlong2/latlong.dart';

void main() {
  const Distance distance = Distance();
  final double meter = distance(LatLng(15.0, 74.0), LatLng(16.0, 75.0));
  print(meter);
}
