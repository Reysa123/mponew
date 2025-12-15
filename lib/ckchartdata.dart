// ck_stat_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Enum untuk Pilihan Periode ---
enum CkPeriod { monthly, yearly }

// --- Model Data untuk Statistik CK1 dan CK2 (DITAMBAH totalPicAssigned) ---
class CkStat {
  final int ck1Count;
  final int ck2Count;
  final int
  totalPicAssigned; // <-- TAMBAHAN: Jumlah total data yang sudah ada PIC nya

  CkStat({
    required this.ck1Count,
    required this.ck2Count,
    required this.totalPicAssigned, // <-- TAMBAHAN
  });

  int get totalCount => ck1Count + ck2Count;
}

class CkStatPage extends StatefulWidget {
  const CkStatPage({super.key});

  @override
  State<CkStatPage> createState() => _CkStatPageState();
}

class _CkStatPageState extends State<CkStatPage> {
  CkPeriod _currentPeriod = CkPeriod.monthly; // Default: Bulanan
  bool _isLoading = true;
  // UPDATE INISIALISASI
  CkStat _ckStats = CkStat(ck1Count: 0, ck2Count: 0, totalPicAssigned: 0);
  String _kodeDealer = '';

  @override
  void initState() {
    super.initState();
    _loadDealerCode();
  }

  Future<void> _loadDealerCode() async {
    final prefs = await SharedPreferences.getInstance();
    _kodeDealer = prefs.getString('dealer_kode') ?? '';
    _fetchCkStats(_currentPeriod);
  }

  // --- Fungsi Pengambilan Data Statistik CK1 & CK2 dari Supabase (DIMODIFIKASI) ---
  Future<void> _fetchCkStats(CkPeriod period) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final now = DateTime.now();

    // Tentukan filter waktu (berdasarkan tgl_respon)
    DateTime startDate;
    DateTime endDate = now;

    if (period == CkPeriod.monthly) {
      startDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, 1, 1);
    }

    try {
      // Query: Filter oleh kode_dealer, harus sudah ada PIC (pic_fu is not null),
      // dan berada dalam range waktu tgl_respon.
      final response = await supabase
          .from('dataeus')
          .select('ck1, ck2, pic_fu, tgl_respon')
          .eq('kode_dealer', _kodeDealer)
          .not('pic_fu', 'is', null) // Hanya data yang sudah di-assign PIC FU
          .gte('tgl_respon', startDate.toIso8601String().substring(0, 10))
          .lte('tgl_respon', endDate.toIso8601String().substring(0, 10));

      int ck1Count = 0;
      int ck2Count = 0;
      final totalPicAssigned = response.length; // <-- PENGHITUNGAN TOTAL DATA

      for (var item in response) {
        // Hitung jika kolom ck1 atau ck2 bernilai 'V'
        if (item['ck1'] != null && item['ck1'].toString().isNotEmpty) {
          ck1Count++;
        }
        if (item['ck2'] != null && item['ck2'].toString().isNotEmpty) {
          ck2Count++;
        }
      }

      setState(() {
        // UPDATE MODEL DENGAN totalPicAssigned
        _ckStats = CkStat(
          ck1Count: ck1Count,
          ck2Count: ck2Count,
          totalPicAssigned: totalPicAssigned,
        );
        _isLoading = false;
        _currentPeriod = period;
      });
    } catch (e) {
      debugPrint('Error fetching CK stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data statistik CK: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Widget untuk Bar Chart (CK1 vs CK2) ---
  // ... (Tidak ada perubahan pada _buildBarChart, karena hanya menampilkan CK1 dan CK2)
  // ... (Gunakan kode _buildBarChart dari jawaban sebelumnya)

  // Widget untuk Bar Chart (CK1 vs CK2)
  Widget _buildBarChart() {
    if (_ckStats.totalCount == 0 && _ckStats.totalPicAssigned == 0) {
      return const Center(
        child: Text(
          "Tidak ada data CK1/CK2 yang sudah di Follow Up dalam periode ini.",
        ),
      );
    }

    final List<BarChartGroupData> barGroups = [
      // CK1 Bar
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: _ckStats.ck1Count.toDouble(),
            color: Colors.red.shade400,
            width: 30,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
      // CK2 Bar
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: _ckStats.ck2Count.toDouble(),
            color: Colors.green.shade400,
            width: 30,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      ),
    ];

    double maxCount =
        (_ckStats.ck1Count > _ckStats.ck2Count
                ? _ckStats.ck1Count
                : _ckStats.ck2Count)
            .toDouble();
    if (maxCount == 0 && _ckStats.totalPicAssigned > 0) {
      // Jika CK1 dan CK2 nol, pakai total Assigned sebagai patokan max Y untuk visualisasi
      maxCount = _ckStats.totalPicAssigned.toDouble();
    }

    double maxY = (maxCount / 10).ceil() * 10.0 + 10.0;
    if (maxY < 20) maxY = 20;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            //tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label = group.x == 0 ? 'CK1' : 'CK2';
              String count = rod.toY.toInt().toString();
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: count,
                    style: TextStyle(
                      color: Colors.yellow.shade100,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Label X-Axis
                String label = value.toInt() == 0 ? 'CK1' : 'CK2';
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5 > 1 ? (maxY / 5).ceil().toDouble() : 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxY) return Container();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        barGroups: barGroups,
      ),
    );
  }
  // ...

  @override
  Widget build(BuildContext context) {
    String periodText = _currentPeriod == CkPeriod.monthly
        ? "Bulanan (${DateTime.now().month}/${DateTime.now().year})"
        : "Tahunan (${DateTime.now().year})";
    String title = "CK1 & CK2 $periodText";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<CkPeriod>(
            onSelected: (CkPeriod result) {
              if (result != _currentPeriod) {
                _fetchCkStats(result);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<CkPeriod>>[
              const PopupMenuItem<CkPeriod>(
                value: CkPeriod.monthly,
                child: Text('Bulan Ini'),
              ),
              const PopupMenuItem<CkPeriod>(
                value: CkPeriod.yearly,
                child: Text('Tahun Ini'),
              ),
            ],
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Chart Container ---
                  Container(
                    height: 350,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildBarChart(),
                  ),
                  const SizedBox(height: 24),
                  // --- Ringkasan Data ---
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ringkasan Data (PIC Assigned/Responded) $periodText:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),

                          // --- TAMBAHAN: TOTAL DATA DENGAN PIC ---
                          ListTile(
                            leading: const Icon(
                              Icons.people_alt,
                              color: Colors.indigo,
                            ),
                            title: const Text("Total Data di FU"),
                            trailing: Text(
                              _ckStats.totalPicAssigned.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          const Divider(), // Garis pemisah
                          // -------------------------------------
                          ListTile(
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.red,
                            ),
                            title: const Text("CK1 Count ('V')"),
                            trailing: Text(
                              _ckStats.ck1Count.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: const Text("CK2 Count ('V')"),
                            trailing: Text(
                              _ckStats.ck2Count.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(
                              Icons.auto_graph,
                              color: Colors.blue,
                            ),
                            title: const Text("Total CK1 & CK2 (V)"),
                            trailing: Text(
                              _ckStats.totalCount.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
