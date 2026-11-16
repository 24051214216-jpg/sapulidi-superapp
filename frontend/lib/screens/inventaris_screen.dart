import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import 'form_peminjaman_screen.dart';

class InventarisScreen extends StatefulWidget {
  const InventarisScreen({super.key});

  @override
  State<InventarisScreen> createState() => _InventarisScreenState();
}

class _InventarisScreenState extends State<InventarisScreen> {
  List<dynamic> _assets = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final Color primaryGreen = const Color(0xFF006130);
  final Color lightGreen = const Color(0xFFE8FFF0);
  final Color bgColor = const Color(0xFFFAF8FF);
  final Color textDark = const Color(0xFF131B2E);
  final Color textGrey = const Color(0xFF3F4940);

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAssets();
      setState(() {
        _assets = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  List<dynamic> get _filteredAssets {
    return _assets.where((asset) {
      final name = (asset['namaAset'] ?? '').toString().toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());

      bool matchesCategory = true;
      if (_selectedCategory != 'Semua') {
        if (_selectedCategory == 'Tenda') {
          matchesCategory = name.contains('tenda');
        }
        if (_selectedCategory == 'Kebersihan') {
          matchesCategory = name.contains('rumput') || name.contains('sapu');
        }
        if (_selectedCategory == 'Perkakas') {
          matchesCategory = name.contains('tangga') || name.contains('cangkul');
        }
      }

      return matchesSearch && matchesCategory;
    }).toList();
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
              'Inventaris',
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
        ],
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadAssets,
        child: Column(
          children: [
            // Banner Info Pinjaman Aktif (Dummy)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, const Color(0xFF0C5C30)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.handyman, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1 PINJAMAN AKTIF ANDA',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tangga Lipat Aluminium 3.8m',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Jatuh tempo: Besok, 17:00 WIB',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.greenAccent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Kembalikan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari cangkul, kursi, tenda...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: const Icon(Icons.tune, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori Filter
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildChip('Semua'),
                  _buildChip('Tenda'),
                  _buildChip('Kebersihan'),
                  _buildChip('Perkakas'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List Alat
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    )
                  : _filteredAssets.isEmpty
                  ? Center(
                      child: Text(
                        'Alat tidak ditemukan.',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredAssets.length,
                      itemBuilder: (context, index) {
                        final asset = _filteredAssets[index];
                        return _buildAssetCard(asset);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    final isActive = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: isActive ? Colors.white : textGrey,
          ),
        ),
        selected: isActive,
        onSelected: (val) => setState(() => _selectedCategory = label),
        selectedColor: primaryGreen,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildAssetCard(dynamic asset) {
    final isAvailable = asset['status'] == 'TERSEDIA';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable ? lightGreen : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAvailable ? 'Tersedia' : 'Dipinjam',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? primaryGreen : Colors.grey,
                  ),
                ),
              ),
              Text(
                '1 Unit / KK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            asset['namaAset'] ?? 'Nama Alat',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kondisi: ${asset['kondisi'] ?? 'BAIK'}',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textGrey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Gudang Balai RT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isAvailable
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FormPeminjamanScreen(assetData: asset),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  // PERBAIKAN: Padding ditambahkan agar teks tidak mepet
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Pinjam Alat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
