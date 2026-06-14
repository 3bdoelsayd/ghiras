import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ghiras/core/constants/app_colors.dart';
import 'package:ghiras/features/settings/settings_screen.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _pickedLocation = const LatLng(30.0444, 31.2357); // القاهرة افتراضي
  bool _isLoadingAddress = false;

  String _cityName = "القاهرة";
  String _governorate = "";
  String _countryName = "";

  @override
  void initState() {
    super.initState();
    _resolveAddress(_pickedLocation);
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      await setLocaleIdentifier("ar");
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          // اسم المدينة
          _cityName = place.locality?.isNotEmpty == true
              ? place.locality!
              : (place.subAdministrativeArea?.isNotEmpty == true
                  ? place.subAdministrativeArea!
                  : (place.name ?? "موقع محدد"));

          // المحافظة (administrativeArea)
          _governorate = place.administrativeArea ?? "";

          _countryName = place.country ?? "";
        });
      }
    } catch (e) {
      setState(() {
        _cityName = "موقع محدد";
        _governorate = "";
      });
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingAddress = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("تنبيه", "خدمة الموقع غير مفعلة");
        setState(() => _isLoadingAddress = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar("تنبيه", "تم رفض إذن الوصول للموقع");
        setState(() => _isLoadingAddress = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() => _pickedLocation = newLocation);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 13));

      await _resolveAddress(newLocation);
    } catch (e) {
      Get.snackbar("خطأ", "تعذر تحديد موقعك الحالي");
      setState(() => _isLoadingAddress = false);
    }
  }

  void _confirmSelection() {
    final controller = Get.find<SettingsController>();

    controller.updateManualLocationFull(
      cityName: _cityName,
      governorate: _governorate,
      lat: _pickedLocation.latitude,
      lng: _pickedLocation.longitude,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'تحديد الموقع',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            fontFamily: 'Cairo',
            color: AppColors.textDark,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (LatLng position) {
              setState(() => _pickedLocation = position);
              _resolveAddress(position);
            },
            markers: {
              Marker(
                markerId: const MarkerId('picked'),
                position: _pickedLocation,
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // زر "موقعي الحالي"
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'currentLocationBtn',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: _isLoadingAddress ? null : _useCurrentLocation,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // البطاقة السفلية
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingAddress)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          _cityName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_governorate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "محافظة $_governorate${_countryName.isNotEmpty ? ' - $_countryName' : ''}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoadingAddress ? null : _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "تأكيد الموقع",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
