// Model Data Respon Harian
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyResponse {
  final int day; // Hari ke-X (digunakan sebagai nilai X pada grafik)
  final double value; // Nilai respon (digunakan sebagai nilai Y pada grafik)

  const DailyResponse(this.day, this.value);
}

class ResponseChartPage extends StatefulWidget {
  const ResponseChartPage({super.key});

  @override
  State<ResponseChartPage> createState() => _ResponseChartPageState();
}

class _ResponseChartPageState extends State<ResponseChartPage> {
  // Data Dummy Respon Harian
  bool isloading = false;
  List<DailyResponse> dailyData = [];
  void getData() async {
    setState(() {
      isloading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final kode = prefs.getString('dealer_kode') ?? '';
    final supabase = Supabase.instance.client;
    List<Map<String, dynamic>> items = [];
    List<Map<String, dynamic>> itemss = [];
    await supabase.from('dataeus').select().eq('kode_dealer', kode).then((
      value,
    ) {
      for (var item in value) {
        if (item['tgl_respon'] != null) {
          items.add(item);
        }
      }
    });
    List<DailyResponse> tempData = [];
    for (var item in items.where(
      (v) =>
          DateTime.parse(v['tgl_respon']).month == DateTime.now().month &&
          DateTime.parse(v['tgl_respon']).year == DateTime.now().year,
    )) {
      itemss.add(item);
    }
    tempData = List.generate(31, (index) {
      final day = index + 1;
      final dayItems = itemss.where((item) {
        final tglRespon = DateTime.parse(item['tgl_respon']);
        return tglRespon.day == day;
      }).toList();
      final value = dayItems.length.toDouble();
      return DailyResponse(day, value);
    });
    setState(() {
      dailyData = tempData;
      isloading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grafik Follow Up')),
      body: isloading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(24),
                width: MediaQuery.of(context).size.width * 1.8, // Lebar 80%
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(51),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LineChart(mainData()),
              ),
            ),
    );
  }

  // Konfigurasi Utama Grafik
  LineChartData mainData() {
    return LineChartData(
      // 1. Judul (Axis X dan Y)
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: getBottomTitles, // Label di bawah (Hari ke-X)
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5, // Interval Y axis: 5, 10, 15, ...
            reservedSize: 40,
            getTitlesWidget: getLeftTitles, // Label di kiri (Nilai Respon)
          ),
        ),
      ),

      // 2. Garis Grid (kotak-kotak)
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        drawVerticalLine: true,
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.grey.shade300, strokeWidth: 1),
      ),

      // 3. Batas Grafik
      minX: 1,
      maxX: dailyData.length.toDouble(),
      minY: 0,
      maxY: 25, // Disesuaikan agar nilai 30.0 masuk di batas atas
      // 4. Data Garis
      lineBarsData: [
        LineChartBarData(
          spots: dailyData
              .map((data) => FlSpot(data.day.toDouble(), data.value))
              .toList(),
          isCurved: true, // Garis melengkung (lebih halus)
          color: Colors.blue, // Warna garis utama
          dotData: FlDotData(
            show: true, // Tampilkan titik-titik data
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue.shade700,
                  strokeWidth: 1.5,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withAlpha(100), // Isi area di bawah garis
          ),
        ),
      ],
    );
  }

  // Widget untuk Label Horizontal (X-Axis)
  Widget getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    return SideTitleWidget(
      meta: meta,
      space: 8.0,
      child: Text(value.toString(), style: style),
    );
  }

  // Widget untuk Label Vertikal (Y-Axis)
  Widget getLeftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    // Hanya tampilkan label untuk interval 0, 5, 10, 15, ...
    if (value % 5 == 0) {
      text = value.toInt().toString();
    } else {
      return Container(); // Sembunyikan label di antara interval
    }

    return SideTitleWidget(
      meta: meta,
      space: 8.0,
      child: Text(text, style: style),
    );
  }
}
