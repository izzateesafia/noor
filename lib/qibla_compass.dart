import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';

import 'location_error_widget.dart';
import 'main.dart';


class QiblaCompass extends StatefulWidget {
  const QiblaCompass({Key? key}) : super(key: key);

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  final _locationStreamController =
  StreamController<LocationStatus>.broadcast();

  get stream => _locationStreamController.stream;

  @override
  void initState() {
    _checkLocationStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with back button and theme switch
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Kompas Qiblah',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Theme mode switch
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, mode, _) => Row(
                        children: [
                          Icon(
                            mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                            color: mode == ThemeMode.dark ? Colors.yellow : Theme.of(context).colorScheme.primary,
                          ),
                          Switch(
                            value: mode == ThemeMode.dark,
                            onChanged: (val) {
                              themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                            },
                            activeColor: Colors.yellow,
                            inactiveThumbColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Cari arah ke Kaabah di Makkah',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Main Content
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20.0),
                  child: StreamBuilder(
                    stream: stream,
                    builder: (context, AsyncSnapshot<LocationStatus> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(radius: 20),
                              SizedBox(height: 20),
                              Text(
                                'Memeriksa perkhidmatan lokasi...',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.data!.enabled == true) {
                        switch (snapshot.data!.status) {
                          case LocationPermission.always:
                          case LocationPermission.whileInUse:
                            return  QiblahCompassWidget();
                  
                          case LocationPermission.denied:
                            return LocationErrorWidget(
                              error: "Kebenaran perkhidmatan lokasi ditolak",
                              callback: _checkLocationStatus,
                            );
                          case LocationPermission.deniedForever:
                            return LocationErrorWidget(
                              error: "Perkhidmatan lokasi ditolak selamanya!",
                              callback: _checkLocationStatus,
                            );
                          default:
                            return Container();
                        }
                      } else {
                        return LocationErrorWidget(
                          error: "Sila aktifkan perkhidmatan lokasi",
                          callback: _checkLocationStatus,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await FlutterQiblah.checkLocationStatus();
    if (locationStatus.enabled &&
        locationStatus.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      final s = await FlutterQiblah.checkLocationStatus();
      _locationStreamController.sink.add(s);
    } else {
      _locationStreamController.sink.add(locationStatus);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _locationStreamController.close();
    FlutterQiblah().dispose();
  }
}

class QiblahCompassWidget extends StatelessWidget {
  final _kaabaSvg = SvgPicture.asset('assets/4.svg');

  QiblahCompassWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (_, AsyncSnapshot<QiblahDirection> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        final qiblahDirection = snapshot.data!;
        var angle = ((qiblahDirection.qiblah) * (pi / 180) * -1);

        return Column(
          children: [
            // Compass Container
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Compass background
                  Transform.rotate(
                    angle: angle,
                    child: SvgPicture.asset(
                      'assets/5.svg',
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  // Kaaba icon
                  _kaabaSvg,
                  // Compass needle
                  SvgPicture.asset(
                    'assets/3.svg',
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Direction Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.navigation,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Arah Qiblah: ${qiblahDirection.qiblah.toStringAsFixed(1)}°',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Selaraskan kedua-dua kepala anak panah untuk mencari arah yang betul',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Usage Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cara Menggunakan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildInstructionItem(
                    '1. Pegang peranti anda rata dan mendatar',
                    Icons.phone_android,
                    context,
                  ),
                  _buildInstructionItem(
                    '2. Putar sehingga anak panah merah menunjuk ke Kaabah',
                    Icons.rotate_right,
                    context,
                  ),
                  _buildInstructionItem(
                    '3. Jauhkan dari objek logam dan magnet',
                    Icons.block,
                    context,
                  ),
                  _buildInstructionItem(
                    '4. Kalibrasi kompas sebelum setiap penggunaan',
                    Icons.refresh,
                    context,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructionItem(String text, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: 300,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
