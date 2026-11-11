import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_service.dart';
import '../utils/theme.dart';

enum _Mode { idle, camera, preview }

class DetailEventScreen extends StatefulWidget {
  final Map<String, dynamic> eventData;
  const DetailEventScreen({super.key, required this.eventData});

  @override
  State<DetailEventScreen> createState() => _DetailEventScreenState();
}

class _DetailEventScreenState extends State<DetailEventScreen>
    with WidgetsBindingObserver {
  _Mode _mode = _Mode.idle;

  // --- Kamera ---
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;
  bool _isCapturing = false;

  // --- GPS & jam (live, dipakai untuk overlay pada preview) ---
  Position? _position;
  StreamSubscription<Position>? _posSub;
  Timer? _clock;
  DateTime _now = DateTime.now();

  // --- Hasil jepretan (nilai DIKUNCI saat tombol jepret ditekan) ---
  Uint8List? _hasilBytes;
  Position? _posisiTerkunci;
  DateTime? _waktuTerkunci;

  bool _isLoading = false;

  String get _namaEvent => (widget.eventData['judul'] ?? 'Event').toString();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _posSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // Lepas kamera saat app tidak aktif, nyalakan lagi saat kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_mode != _Mode.camera) return;

    if (state == AppLifecycleState.inactive) {
      _lepasKamera();
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        _cameras.isNotEmpty) {
      _initCamera(_cameras[_cameraIndex]).catchError((e) => _snack('$e'));
    }
  }

  // ---------------------------------------------------------------------------
  // HELPER UI
  // ---------------------------------------------------------------------------
  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  // ---------------------------------------------------------------------------
  // GPS
  // ---------------------------------------------------------------------------
  Future<void> _siapkanGps() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'GPS tidak aktif. Nyalakan lokasi HP/PC Anda.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw 'Izin lokasi ditolak.';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan aplikasi.';
    }

    // Titik pertama (sama seperti kode lama).
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );
    final first = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    if (mounted) setState(() => _position = first);

    // Lalu pantau terus supaya angka di overlay selalu terbaru.
    await _posSub?.cancel();
    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        ).listen(
          (p) {
            if (mounted) setState(() => _position = p);
          },
          onError: (_) {}, // abaikan; nilai terakhir tetap dipakai
        );
  }

  // ---------------------------------------------------------------------------
  // KAMERA
  // ---------------------------------------------------------------------------
  Future<void> _bukaKamera() async {
    setState(() => _isLoading = true);
    try {
      await _siapkanGps();

      _cameras = await availableCameras();
      if (_cameras.isEmpty) throw 'Kamera tidak ditemukan di perangkat ini.';

      // Default kamera depan (selfie), jika ada.
      final front = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = front >= 0 ? front : 0;

      await _initCamera(_cameras[_cameraIndex]);

      _clock?.cancel();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });

      if (mounted) setState(() => _mode = _Mode.camera);
    } on CameraException catch (e) {
      _matikanKamera();
      _snack(_pesanKamera(e));
    } catch (e) {
      _matikanKamera();
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _pesanKamera(CameraException e) {
    if (e.code.startsWith('CameraAccess')) {
      return 'Izin kamera ditolak. Aktifkan izin kamera di Pengaturan.';
    }
    return e.description ?? 'Kamera gagal dibuka (${e.code}).';
  }

  Future<void> _initCamera(CameraDescription desc) async {
    final lama = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await lama?.dispose();

    final baru = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = baru;
    await baru.initialize();

    try {
      // Kunci orientasi hasil foto ke portrait (tidak didukung di web).
      await baru.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _gantiKamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _initCamera(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      _snack(_pesanKamera(e));
    }
  }

  // Melepas controller dari tree dulu, baru di-dispose setelah frame selesai.
  void _lepasKamera() {
    final c = _controller;
    if (c == null) return;
    _controller = null;
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  void _matikanKamera() {
    _clock?.cancel();
    _clock = null;
    _posSub?.cancel();
    _posSub = null;
    _lepasKamera();
  }

  void _tutupKamera() {
    _matikanKamera();
    if (mounted) setState(() => _mode = _Mode.idle);
  }

  // ---------------------------------------------------------------------------
  // JEPRET + GABUNGKAN FOTO DENGAN TEKS
  // ---------------------------------------------------------------------------
  Future<void> _jepret() async {
    final c = _controller;
    final pos = _position;
    if (c == null || !c.value.isInitialized || pos == null || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      // Dikunci SEBELUM takePicture, supaya yang tercetak = saat tombol ditekan.
      final waktu = DateTime.now();

      final XFile mentah = await c.takePicture();
      final Uint8List mentahBytes = await mentah.readAsBytes();

      final Uint8List hasil = await _buatGambarBerStempel(
        mentahBytes,
        namaEvent: _namaEvent,
        waktu: waktu,
        pos: pos,
      );

      _matikanKamera();
      if (!mounted) return;
      setState(() {
        _hasilBytes = hasil;
        _posisiTerkunci = pos;
        _waktuTerkunci = waktu;
        _mode = _Mode.preview;
      });
    } on CameraException catch (e) {
      _snack(_pesanKamera(e));
    } catch (e) {
      _snack('Gagal mengambil foto: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  /// Menempelkan teks (event, waktu, lat, lng) PERMANEN ke piksel foto.
  /// Hasilnya satu gambar utuh (PNG) pada resolusi foto asli.
  Future<Uint8List> _buatGambarBerStempel(
    Uint8List mentah, {
    required String namaEvent,
    required DateTime waktu,
    required Position pos,
  }) async {
    final codec = await ui.instantiateImageCodec(mentah);
    final frame = await codec.getNextFrame();
    final ui.Image foto = frame.image;
    final int lebar = foto.width;
    final int tinggi = foto.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, lebar.toDouble(), tinggi.toDouble()),
    );
    canvas.drawImage(foto, Offset.zero, Paint());

    // Semua ukuran diskalakan terhadap lebar foto (360 satuan = lebar foto),
    // jadi tampilannya konsisten di resolusi berapa pun.
    final double u = lebar / 360.0;
    final double margin = 12 * u;
    final double pad = 10 * u;
    final double maxTeks = lebar - (2 * margin) - (2 * pad);

    TextPainter buatTeks(String teks, double ukuran, FontWeight berat) {
      return TextPainter(
        text: TextSpan(
          text: teks,
          style: TextStyle(
            color: Colors.white,
            fontSize: ukuran * u,
            fontWeight: berat,
            height: 1.25,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: maxTeks);
    }

    final baris = <TextPainter>[
      buatTeks(namaEvent, 15, FontWeight.bold),
      buatTeks(_formatWaktu(waktu), 13, FontWeight.w500),
      buatTeks('Lat: ${pos.latitude.toStringAsFixed(6)}', 13, FontWeight.w500),
      buatTeks('Lng: ${pos.longitude.toStringAsFixed(6)}', 13, FontWeight.w500),
    ];

    final double tinggiTeks = baris.fold(0.0, (sum, p) => sum + p.height);
    final double tinggiBox = tinggiTeks + (2 * pad);
    final double top = tinggi - margin - tinggiBox;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, top, lebar - (2 * margin), tinggiBox),
        Radius.circular(10 * u),
      ),
      Paint()..color = Colors.black.withAlpha(153),
    );

    double y = top + pad;
    for (final p in baris) {
      p.paint(canvas, Offset(margin + pad, y));
      y += p.height;
    }

    final ui.Picture gambar = recorder.endRecording();
    final ui.Image hasil = await gambar.toImage(lebar, tinggi);
    final ByteData? data = await hasil.toByteData(
      format: ui.ImageByteFormat.png,
    );

    foto.dispose();
    hasil.dispose();
    codec.dispose();

    if (data == null) throw 'Gagal menyusun gambar bertimestamp.';
    return data.buffer.asUint8List();
  }

  // ---------------------------------------------------------------------------
  // SIMPAN KE STORAGE -> UPLOAD -> KIRIM ABSEN
  // ---------------------------------------------------------------------------
  Future<XFile> _simpanKeStorage(Uint8List bytes, DateTime waktu) async {
    final nama = 'absen_${waktu.millisecondsSinceEpoch}.png';

    // Web tidak punya filesystem; kirim langsung dari memori.
    if (kIsWeb) {
      return XFile.fromData(bytes, name: nama, mimeType: 'image/png');
    }

    final dir = await getApplicationDocumentsDirectory();
    final folder = await Directory('${dir.path}/absensi')
        .create(recursive: true);
    final file = await File('${folder.path}/$nama')
        .writeAsBytes(bytes, flush: true);
    return XFile(file.path, name: nama, mimeType: 'image/png');
  }

  Future<void> _submitAbsen() async {
    final bytes = _hasilBytes;
    final pos = _posisiTerkunci;
    final waktu = _waktuTerkunci;
    if (bytes == null || pos == null || waktu == null) return;

    setState(() => _isLoading = true);
    try {
      final XFile fileUpload = await _simpanKeStorage(bytes, waktu);

      final String? fotoUrl = await ApiService.uploadFoto(fileUpload);
      if (fotoUrl == null) {
        _snack('Gagal upload foto ke server.');
        return;
      }

      // Koordinat yang dikirim = koordinat yang tercetak di foto.
      final result = await ApiService.absenKerjaBakti(
        widget.eventData['id'],
        pos.latitude,
        pos.longitude,
        fotoUrl,
        pos.isMocked,
      );

      if (!mounted) return;
      _snack(result['message'].toString());
      if (result['success'] == true) Navigator.pop(context);
    } catch (e) {
      _snack('Gagal menyimpan/mengirim absensi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_mode == _Mode.camera) return _buildKamera();
    return _buildHalaman();
  }

  // ----- Layar kamera penuh -----
  Widget _buildKamera() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _tutupKamera();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: Center(child: _previewDenganOverlay())),
              _kontrolKamera(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewDenganOverlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    final double ar = c.value.aspectRatio;
    final bool portrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final double rasio = (kIsWeb || !portrait) ? ar : 1 / ar;

    return AspectRatio(
      aspectRatio: rasio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(c),
          Positioned(left: 12, right: 12, bottom: 12, child: _overlayStempel()),
        ],
      ),
    );
  }

  // Widget overlay live (tampilan pratinjau; versi permanennya digambar di
  // _buatGambarBerStempel dengan isi yang sama).
  Widget _overlayStempel() {
    final pos = _position;
    const style = TextStyle(color: Colors.white, fontSize: 13, height: 1.25);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _namaEvent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(_formatWaktu(_now), style: style),
          Text(
            pos == null
                ? 'Lat: mencari sinyal GPS...'
                : 'Lat: ${pos.latitude.toStringAsFixed(6)}',
            style: style,
          ),
          Text(
            pos == null
                ? 'Lng: mencari sinyal GPS...'
                : 'Lng: ${pos.longitude.toStringAsFixed(6)}',
            style: style,
          ),
        ],
      ),
    );
  }

  Widget _kontrolKamera() {
    final bisaJepret = _position != null && !_isCapturing;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _isCapturing ? null : _tutupKamera,
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
          ),
          GestureDetector(
            onTap: bisaJepret ? _jepret : null,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: bisaJepret ? Colors.white : Colors.white38,
                  width: 4,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bisaJepret ? Colors.white : Colors.white38,
                ),
                child: _isCapturing
                    ? const Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : null,
              ),
            ),
          ),
          IconButton(
            onPressed: (_cameras.length > 1 && !_isCapturing)
                ? _gantiKamera
                : null,
            icon: Icon(
              Icons.cameraswitch,
              color: _cameras.length > 1 ? Colors.white : Colors.white24,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // ----- Halaman biasa: idle & preview hasil -----
  Widget _buildHalaman() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Absensi Kegiatan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.bgColor,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _namaEvent,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),
            if (_mode == _Mode.idle) _buildIdle(),
            if (_mode == _Mode.preview) _buildPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            size: 80,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Ambil selfie. Tanggal, waktu, nama event, dan koordinat GPS akan '
          'tercetak langsung di foto sebagai bukti kehadiran.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textGrey, height: 1.5),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _bukaKamera,
          icon: const Icon(Icons.camera),
          label: Text(_isLoading ? 'Memproses...' : 'BUKA KAMERA & LOKASI'),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.memory(_hasilBytes!, fit: BoxFit.contain),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitAbsen,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
          ),
          child: Text(_isLoading ? 'MENGIRIM...' : 'KIRIM ABSENSI'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _hasilBytes = null;
                    _posisiTerkunci = null;
                    _waktuTerkunci = null;
                  });
                  _bukaKamera();
                },
          child: const Text(
            'Ulangi Ambil Foto',
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// FORMAT WAKTU (tanpa package intl)
// -----------------------------------------------------------------------------
String _dua(int n) => n.toString().padLeft(2, '0');

String _zonaWaktu(DateTime d) {
  final o = d.timeZoneOffset;
  final tanda = o.isNegative ? '-' : '+';
  final jam = _dua(o.inHours.abs());
  final menit = _dua(o.inMinutes.abs() % 60);
  return 'GMT$tanda$jam:$menit';
}

String _formatWaktu(DateTime d) =>
    '${_dua(d.day)}/${_dua(d.month)}/${d.year} '
    '${_dua(d.hour)}:${_dua(d.minute)}:${_dua(d.second)} ${_zonaWaktu(d)}';
