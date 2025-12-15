// pic_stat_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Model Data untuk Statistik PIC ---
class PicStat {
  final String picName;
  final int count;

  PicStat(this.picName, this.count);
}

// --- Enum untuk Pilihan Periode ---
enum Period { monthly, yearly }

class PicStatPage extends StatefulWidget {
  const PicStatPage({super.key});

  @override
  State<PicStatPage> createState() => _PicStatPageState();
}

class _PicStatPageState extends State<PicStatPage> {
  Period _currentPeriod = Period.monthly; // Default: Bulanan
  bool _isLoading = true;
  List<PicStat> _picStats = [];
  String _kodeDealer = '';

  @override
  void initState() {
    super.initState();
    _loadDealerCode();
  }

  Future<void> _loadDealerCode() async {
    final prefs = await SharedPreferences.getInstance();
    _kodeDealer = prefs.getString('dealer_kode') ?? '';
    _fetchPicStats(_currentPeriod);
  }

  // --- Fungsi Pengambilan Data Statistik PIC dari Supabase ---
  Future<void> _fetchPicStats(Period period) async {
    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;
    final now = DateTime.now();

    // Tentukan filter waktu
    DateTime startDate;
    DateTime endDate = now;

    if (period == Period.monthly) {
      // Bulan ini: Mulai dari hari pertama bulan ini
      startDate = DateTime(now.year, now.month, 1);
    } else {
      // Tahun ini: Mulai dari hari pertama tahun ini
      startDate = DateTime(now.year, 1, 1);
    }

    try {
      // 1. Ambil data yang sudah direspon (tgl_respon is not null)
      // 2. Filter berdasarkan kode_dealer
      // 3. Filter berdasarkan range waktu (tgl_respon)
      final response = await supabase
          .from('dataeus')
          .select('pic_fu') // Hanya ambil kolom PIC Follow Up
          .eq('kode_dealer', _kodeDealer)
          .not('tgl_respon', 'is', null) // Hanya data yang sudah direspon
          .gte('tgl_respon', startDate.toIso8601String().substring(0, 10))
          .lte('tgl_respon', endDate.toIso8601String().substring(0, 10));

      // Hitung jumlah respon per PIC
      Map<String, int> picCountMap = {};
      for (var item in response) {
        final picFu = item['pic_fu'];
        if (picFu != null) {
          picCountMap[picFu] = (picCountMap[picFu] ?? 0) + 1;
        }
      }

      // Konversi Map ke List<PicStat>
      List<PicStat> tempData = picCountMap.entries
          .map((entry) => PicStat(entry.key, entry.value))
          .toList();

      // Urutkan berdasarkan hitungan tertinggi
      tempData.sort((a, b) => b.count.compareTo(a.count));

      setState(() {
        _picStats = tempData;
        _isLoading = false;
        _currentPeriod = period;
      });
    } catch (e) {
      debugPrint('Error fetching PIC stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data statistik: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Widget untuk Bar Chart ---
  Widget _buildBarChart() {
    if (_picStats.isEmpty) {
      return const Center(child: Text("Tidak ada data respon PIC dalam periode ini."));
    }

    final List<BarChartGroupData> barGroups = _picStats.asMap().entries.map((entry) {
      int index = entry.key;
      PicStat stat = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: stat.count.toDouble(),
            color: Colors.blue.shade400,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
        showingTooltipIndicators: [0], // Tampilkan tooltip di atas bar
      );
    }).toList();

    // Tentukan MaxY (maksimum Y axis)
    double maxY = _picStats.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();
    // Tambahkan sedikit ruang di atas bar tertinggi
    maxY = (maxY / 10).ceil() * 10.0 + 10.0;
    if (maxY < 20) maxY = 20;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            //tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String picName = _picStats[groupIndex].picName;
              String count = rod.toY.toInt().toString();
              return BarTooltipItem(
                '$picName\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '$count Respon',
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 70,
              getTitlesWidget: (value, meta) {
                // Label X-Axis adalah Nama PIC
                String picName = _picStats[value.toInt()].picName;
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: RotatedBox(
                    quarterTurns: -1, // Rotasi 90 derajat
                    child: Text(
                      picName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5 > 1 ? (maxY / 5).ceil().toDouble() : 5, // Interval dinamis
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Label Y-Axis adalah jumlah respon
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

  @override
  Widget build(BuildContext context) {
    String title = _currentPeriod == Period.monthly
        ? "Statistik Respon Bulanan (${DateTime.now().month}/${DateTime.now().year})"
        : "Statistik Respon Tahunan (${DateTime.now().year})";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Tombol Pilihan Periode
          PopupMenuButton<Period>(
            onSelected: (Period result) {
              if (result != _currentPeriod) {
                _fetchPicStats(result);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Period>>[
              const PopupMenuItem<Period>(
                value: Period.monthly,
                child: Text('Bulan Ini'),
              ),
              const PopupMenuItem<Period>(
                value: Period.yearly,
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
                    height: 400, // Ketinggian chart
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
                  // --- Ringkasan Data dalam bentuk List/Tabel (Opsional) ---
                  const Text(
                    "Ringkasan Data PIC:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ..._picStats.map((stat) => ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(stat.picName),
                        trailing: Text(
                          "${stat.count} Respon",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}