/// Position utilisateur résolue (GPS ou repli Marrakech).
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.isFromGps,
  });

  final double latitude;
  final double longitude;
  final String cityName;
  final bool isFromGps;
}
