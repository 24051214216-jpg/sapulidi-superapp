import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _invoices = [];
  Map<String, dynamic>? _cashData;
  bool _isLoading = true;
  String? _error;
  String? _uploadingId;

  // Palet Warna
  final Color primaryGreen = const Color(0xFF006130);
  final Color lightGreen = const Color(0xFFE8FFF0);
  final Color orange = const Color(0xFFFB7800);
  final Color bgColor = const Color(0xFFFAF8FF);
  final Color textDark = const Color(0xFF131B2E);
  final Color textGrey = const Color(0xFF3F4940);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final invoices = await ApiService.getInvoices();
      final cash = await ApiService.getCashLedger();

      setState(() {
        _invoices = invoices;
        _cashData = cash;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Format Rupiah
  String _formatRupiah(dynamic value) {
    final n = num.tryParse(value.toString())?.round() ?? 0;
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade600 : primaryGreen,
      ),
    );
  }

  Future<void> _uploadBukti(dynamic invoice) async {
    final invoiceId = invoice['id'].toString();

    // Pilih gambar
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingId = invoiceId);

    try {
      // 1. Upload gambar ke server
      final url = await ApiService.uploadFoto(picked);
      if (url == null) {
        _snack('Gagal mengunggah gambar bukti', error: true);
        return;
      }

      // 2. Kirim data pembayaran
      final res = await ApiService.createPayment(invoiceId, url);
      if (res['success'] == true) {
        _snack(res['message'] ?? 'Bukti bayar berhasil dikirim');
        await _loadData(); // Refresh data
      } else {
        _snack(res['message'] ?? 'Gagal mengirim pembayaran', error: true);
      }
    } finally {
      if (mounted) setState(() => _uploadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'SapuLidi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: primaryGreen,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1.5, height: 16, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Text(
              'Keuangan',
              style: GoogleFonts.plusJakartaSans(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: primaryGreen,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(color: Colors.red),
              ),
            )
          : RefreshIndicator(
              color: primaryGreen,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingCard(),
                    const SizedBox(height: 20),
                    _buildInvoiceSection(),
                    const SizedBox(height: 20),
                    _buildBankSection(),
                    const SizedBox(height: 24),
                    _buildTransparencySection(),
                    const SizedBox(height: 24),
                    _buildHistorySection(),
                    const SizedBox(height: 24),
                    _buildHelpBanner(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // 1. KARTU SAMBUTAN HIJAU
  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GOTONG ROYONG RT 04',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Iuran Tepat Waktu,\nWarga Tenang',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keluarga Bpk. Hendra Gunawan (Blok B2/14)',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Gambar Karakter (Kotak putih kecil)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/karakter_sapulidi.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. KARTU TAGIHAN & RINCIAN
  Widget _buildInvoiceSection() {
    // Cari tagihan yang belum bayar, jika tidak ada ambil yang pertama
    dynamic activeInvoice;
    if (_invoices.isNotEmpty) {
      activeInvoice = _invoices.firstWhere(
        (inv) => inv['status'] == 'BELUM_BAYAR',
        orElse: () => _invoices.first,
      );
    }

    if (activeInvoice == null) {
      return Center(
        child: Text(
          'Belum ada tagihan.',
          style: GoogleFonts.plusJakartaSans(color: textGrey),
        ),
      );
    }

    final status = activeInvoice['status'];
    final isLunas = status == 'LUNAS';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tagihan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: textGrey),
                      const SizedBox(width: 6),
                      Text(
                        'Periode Tagihan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeInvoice['periode'] ?? 'November 2024',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isLunas ? lightGreen : orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLunas ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: isLunas ? primaryGreen : orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLunas ? 'Lunas' : 'Belum Bayar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isLunas ? primaryGreen : orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kotak Nominal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Kewajiban Iuran',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: textGrey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Jatuh Tempo: 25 Nov',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(activeInvoice['jumlah']),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rincian Dummy (karena db belum punya rincian)
          _buildRincianRow(
            Icons.cleaning_services,
            'Iuran Kebersihan & Sampah',
            'Rp 65.000',
            Colors.blue.shade700,
          ),
          const SizedBox(height: 12),
          _buildRincianRow(
            Icons.security,
            'Iuran Keamanan / Satpam',
            'Rp 60.000',
            Colors.teal.shade700,
          ),
          const SizedBox(height: 12),
          _buildRincianRow(
            Icons.volunteer_activism,
            'Dana Sosial & Kas Kematian',
            'Rp 25.000',
            Colors.purple.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildRincianRow(
    IconData icon,
    String title,
    String amount,
    Color iconColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textDark),
            ),
          ],
        ),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ],
    );
  }

  // 3. REKENING BANK & TOMBOL UPLOAD
  Widget _buildBankSection() {
    // Cek apakah ada tagihan yang belum dibayar
    final hasUnpaid = _invoices.any((inv) => inv['status'] == 'BELUM_BAYAR');
    final unpaidInvoice = hasUnpaid
        ? _invoices.firstWhere((inv) => inv['status'] == 'BELUM_BAYAR')
        : null;
    final isUploading =
        unpaidInvoice != null && _uploadingId == unpaidInvoice['id'].toString();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        color: primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rekening Resmi Kas RT',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Transfer Manual',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Mandiri',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: textGrey,
                          ),
                        ),
                        Text(
                          '137-00-1928374-1',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'a.n KAS RT 05 MENTENG ASRI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () {
                        _snack('Nomor rekening disalin!');
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.copy, size: 14, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tombol Upload Besar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (unpaidInvoice == null || isUploading)
                ? null
                : () => _uploadBukti(unpaidInvoice),
            icon: isUploading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : const Icon(Icons.upload_file),
            label: Text(
              isUploading ? 'MENGIRIM...' : 'Upload Bukti Transfer Manual',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. TRANSPARANSI KAS RT
  Widget _buildTransparencySection() {
    final totalMasuk = _cashData?['ringkasan']?['totalMasuk'] ?? 0;
    final totalKeluar = _cashData?['ringkasan']?['totalKeluar'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transparansi Kas RT',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textDark,
                        ),
                      ),
                      Text(
                        'Update Keuangan Terbaru',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Publik',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: primaryGreen,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Masuk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(totalMasuk),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.arrow_upward, color: orange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Keluar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(totalKeluar),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: orange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Progress Ring (Simulasi)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    children: [
                      Center(
                        child: CircularProgressIndicator(
                          value: 0.82,
                          color: primaryGreen,
                          backgroundColor: Colors.grey.shade300,
                          strokeWidth: 4,
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.trending_up,
                          size: 16,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kas Terkumpul 82%',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: textDark,
                        ),
                      ),
                      Text(
                        '41 dari 50 KK telah melunasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 16),
              label: Text(
                'Unduh PDF Laporan Kas RT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. RIWAYAT PEMBAYARAN
  Widget _buildHistorySection() {
    // Filter hanya yang LUNAS untuk riwayat
    final history = _invoices.where((inv) => inv['status'] == 'LUNAS').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Pembayaran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            Text(
              'Lihat Semua',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Text(
            'Belum ada riwayat lunas.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textGrey),
          )
        else
          ...history.take(3).map((inv) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: primaryGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                inv['periode'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                color: primaryGreen,
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Transfer Bank Mandiri',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatRupiah(inv['jumlah']),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textDark,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LUNAS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // 6. BANTUAN BANNER
  Widget _buildHelpBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUTUH BANTUAN?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hubungi Bendahara RT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Konsultasikan kendala pembayaran atau dispensasi iuran bulanan warga.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: textGrey,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.chat,
                    size: 16,
                    color: primaryGreen,
                  ), // <-- Perbaikan: Hapus kata 'const'
                  label: Text(
                    'Chat Pak RT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/karakter_sapulidi.png',
            width: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.person, size: 60, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
