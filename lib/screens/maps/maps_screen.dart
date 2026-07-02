import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsScreen extends StatefulWidget {
  final String mode; // 'restaurant' or 'exercise'
  const MapsScreen({super.key, this.mode = 'restaurant'});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  bool _loading = true;
  String? _error;
  LatLng? _currentLocation;
  final List<_HealthyLocation> _locations = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loading = true;
      _error = null;
      _locations.clear();
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Layanan lokasi tidak aktif. Aktifkan GPS atau layanan lokasi terlebih dahulu.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak. Aktifkan izin lokasi untuk menggunakan fitur peta.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );

      final current = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = current;
      });
      _mapController.move(current, 14);
      await _loadNearbyPlaces(current);
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
      });
    } catch (e) {
      setState(() {
        _error = 'Terjadi kesalahan saat mengambil lokasi. Coba lagi.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Bounding box around [center] — no fixed radius cap; scales with map area.
  (double south, double west, double north, double east) _bboxAround(LatLng center, {double delta = 0.35}) {
    return (
      center.latitude - delta,
      center.longitude - delta,
      center.latitude + delta,
      center.longitude + delta,
    );
  }

  Future<void> _loadNearbyPlaces(LatLng current) async {
    const endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
    ];

    final bbox = _bboxAround(current);
    final s = bbox.$1;
    final w = bbox.$2;
    final n = bbox.$3;
    final e = bbox.$4;

    String query;
    if (widget.mode == 'exercise') {
      query = '''
[out:json][timeout:25];
(
  node["leisure"="park"]($s,$w,$n,$e);
  way["leisure"="park"]($s,$w,$n,$e);
  relation["leisure"="park"]($s,$w,$n,$e);
  node["leisure"="pitch"]($s,$w,$n,$e);
  way["leisure"="pitch"]($s,$w,$n,$e);
  node["leisure"="fitness_centre"]($s,$w,$n,$e);
  way["leisure"="fitness_centre"]($s,$w,$n,$e);
  node["sport"="fitness_centre"]($s,$w,$n,$e);
  way["sport"="fitness_centre"]($s,$w,$n,$e);
  node["building"="gym"]($s,$w,$n,$e);
  node["amenity"="gym"]($s,$w,$n,$e);
  way["amenity"="gym"]($s,$w,$n,$e);
);
out center body;
''';
    } else {
      query = '''
[out:json][timeout:25];
(
  node["amenity"="restaurant"]($s,$w,$n,$e);
  way["amenity"="restaurant"]($s,$w,$n,$e);
  node["amenity"="cafe"]($s,$w,$n,$e);
  way["amenity"="cafe"]($s,$w,$n,$e);
  node["shop"="health_food"]($s,$w,$n,$e);
  way["shop"="health_food"]($s,$w,$n,$e);
);
out center body;
''';
    }

    debugPrint('[Maps] bbox: s=$s, w=$w, n=$n, e=$e');
    debugPrint('[Maps] query mode: ${widget.mode}');

    for (final endpoint in endpoints) {
      try {
        debugPrint('[Maps] Trying endpoint: $endpoint');
        final url = '$endpoint?data=${Uri.encodeComponent(query)}';
        final response = await Dio().get(
          url,
          options: Options(
            headers: {
              'User-Agent': 'CaloriMate/1.0 (Flutter; contact@calorimate.app)',
            },
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 10),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        debugPrint('[Maps] Response status: ${response.statusCode}');
        final body = response.data;

        if (body is Map<String, dynamic> && body['elements'] is List) {
          final elements = body['elements'] as List;
          debugPrint('[Maps] Elements found: ${elements.length}');

          final parsed = elements.whereType<Map>().map((element) {
            final map = Map<String, dynamic>.from(element);
            final lat = map['lat'] ?? map['center']?['lat'];
            final lon = map['lon'] ?? map['center']?['lon'];
            final tagsRaw = map['tags'];
            if (lat is! num || lon is! num || tagsRaw is! Map) return null;
            final tags = Map<String, dynamic>.from(tagsRaw);
            final defaultName = widget.mode == 'exercise' ? 'Tempat Olahraga (Tanpa Nama)' : 'Restoran (Tanpa Nama)';
            final name = tags['name']?.toString() ?? 
                         tags['name:id']?.toString() ??
                         tags['alt_name']?.toString() ??
                         tags['brand']?.toString() ?? 
                         tags['operator']?.toString() ?? 
                         defaultName;
            final hours = tags['opening_hours']?.toString() ?? 'Jam buka tidak tersedia';
            final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon';
            return _HealthyLocation(
              point: LatLng(lat.toDouble(), lon.toDouble()),
              name: name,
              detail: hours,
              mapUrl: Uri.parse(url),
            );
          }).whereType<_HealthyLocation>().toList();

          debugPrint('[Maps] Parsed locations: ${parsed.length}');

          setState(() {
            _locations.clear();
            _locations.addAll(parsed);
          });
          return; // success, stop trying other endpoints
        } else {
          debugPrint('[Maps] Unexpected response body: $body');
        }
      } catch (err) {
        debugPrint('[Maps] Error with $endpoint: $err');
        // try next endpoint
      }
    }
    // all endpoints failed — no markers but map stays visible
    debugPrint('[Maps] All Overpass endpoints failed');
  }

  Future<void> _showLocationInfo(_HealthyLocation location) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(location.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(location.detail, style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  bool opened = false;
                  try {
                    opened = await launchUrl(location.mapUrl, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                  
                  if (!opened) {
                    try {
                      // Fallback buka di browser biasa kalau aplikasi Google Maps tidak ada/gagal
                      opened = await launchUrl(location.mapUrl, mode: LaunchMode.platformDefault);
                    } catch (_) {}
                  }

                  if (!opened && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Tidak dapat membuka tautan peta')),
                    );
                  }
                },
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Buka di Google Maps / Browser'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'exercise' ? 'Gym & Taman Olahraga' : 'Restoran'),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _currentLocation ?? LatLng(-6.200000, 106.816666),
                    zoom: 14,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.calorimate_mobile',
                    ),
                    if (_currentLocation != null || _locations.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          if (_currentLocation != null)
                            Marker(
                              point: _currentLocation!,
                              width: 40,
                              height: 40,
                              builder: (_) => const Icon(
                                Icons.my_location,
                                color: Colors.orange,
                                size: 32,
                              ),
                            ),
                          ..._locations.map((location) {
                            return Marker(
                              point: location.point,
                              width: 36,
                              height: 36,
                              builder: (_) => GestureDetector(
                                onTap: () => _showLocationInfo(location),
                                child: Icon(
                                  widget.mode == 'exercise'
                                      ? Icons.fitness_center
                                      : Icons.restaurant,
                                  color: widget.mode == 'exercise'
                                      ? Colors.blue
                                      : Colors.green,
                                  size: 32,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                            _loading
                                ? (widget.mode == 'exercise'
                                    ? 'Mencari gym & taman olahraga di sekitar Anda...'
                                    : 'Mencari restoran di sekitar Anda...')
                                : (_locations.isEmpty
                                    ? (widget.mode == 'exercise'
                                        ? 'Tidak ditemukan gym atau taman terdekat. Coba lagi nanti.'
                                        : 'Tidak ditemukan restoran. Coba lagi nanti.')
                                    : (widget.mode == 'exercise'
                                        ? 'Menampilkan ${_locations.length} gym & taman terdekat.'
                                        : 'Menampilkan ${_locations.length} restoran di sekitar Anda.')),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  Positioned.fill(
                    child: Container(
                      color: const Color.fromRGBO(255, 255, 255, 0.85),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _currentLocation == null
          ? null
          : FloatingActionButton(
              onPressed: () {
                _mapController.move(_currentLocation!, 14);
              },
              child: const Icon(Icons.my_location),
            ),
    );
  }
}

class _HealthyLocation {
  final LatLng point;
  final String name;
  final String detail;
  final Uri mapUrl;

  _HealthyLocation({
    required this.point,
    required this.name,
    required this.detail,
    required this.mapUrl,
  });
}
