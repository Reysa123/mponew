import 'package:flutter/material.dart';
// Import 'dart:io' untuk pengecekan platform (atau 'flutter/foundation.dart' untuk web)
import 'package:flutter/foundation.dart';
import 'package:mpo/chartdata.dart';
import 'package:mpo/ckchartdata.dart';
// Import library excel
import 'package:mpo/pendaftran.dart';
import 'package:mpo/picchartdata.dart';
import 'package:mpo/uploaddownloadscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INISIALISASI SUPABASE ---
  await Supabase.initialize(
    // Ganti dengan URL dan Anon Key proyek Supabase Anda
    url: 'https://xrbdrltklhvcndtfpuoh.supabase.co/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhyYmRybHRrbGh2Y25kdGZwdW9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0MTg0MzksImV4cCI6MjA4MDk5NDQzOX0.4L5GA_S3BUFtAv9TaUO_aU1yuWhDdXqEaVoEtrpJL9c',
  );
  await Supabase.instance.client.auth.signInWithPassword(
    email: 'fieldadvisordenpasar@gmail.com',
    password: 'supabase1',
  );
  final prefs = await SharedPreferences.getInstance();
  final savedKodeDealer = prefs.getString('dealer_kode');
  final savedPic = prefs.getString('dealer_pic');
  if (savedKodeDealer != null && savedPic != null) {
    runApp(const MyApp());
  } else {
    runApp(
      const MaterialApp(
        home: RegistrationFormScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data EUS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DataEusPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Model Data
class DataEus {
  final String noRangka;
  final String noPolisi;
  final String namaCust;
  final String almtCust;
  final String kota;
  final String noTelp;
  final String namaSales;
  final String tglFaktur;
  final String tahun;
  final String ck1;
  final String ck2;
  final String pb15;
  final String pb20;
  final String pb25;
  final String pb30;
  final String pb35;
  final String pb40;
  final String picFU;
  final String? respon; // Tambahkan field respon
  final String? tglRespon; // Tambahkan field tglRespon
  final String? kodeDealer;

  DataEus({
    required this.noRangka,
    required this.noPolisi,
    required this.namaCust,
    required this.almtCust,
    required this.kota,
    required this.noTelp,
    required this.namaSales,
    required this.tglFaktur,
    required this.tahun,
    required this.ck1,
    required this.ck2,
    required this.pb15,
    required this.pb20,
    required this.pb25,
    required this.pb30,
    required this.pb35,
    required this.pb40,
    required this.picFU,
    this.respon,
    this.tglRespon,
    this.kodeDealer,
  });
  factory DataEus.fromMap(Map<String, dynamic> map) {
    return DataEus(
      noRangka: map['no_rangka'] ?? '-',
      noPolisi: map['no_polisi'] ?? '-',
      namaCust: map['nama_cust'] ?? '-',
      almtCust: map['almt_cust'] ?? '-',
      kota: map['kota'] ?? '-',
      noTelp: map['no_telp'] ?? '-',
      namaSales: map['nama_sales'] ?? '-',
      tglFaktur: map['tgl_faktur'] ?? '-',
      tahun: map['tahun'] ?? '-',
      ck1: map['ck1'] ?? '-',
      ck2: map['ck2'] ?? '-',
      pb15: map['pb15'] ?? '-',
      pb20: map['pb20'] ?? '-',
      pb25: map['pb25'] ?? '-',
      pb30: map['pb30'] ?? '-',
      pb35: map['pb35'] ?? '-',
      pb40: map['pb40'] ?? '-',
      picFU: map['pic_fu'] ?? '-',
      respon: map['respon'], // Ambil data respon jika ada
      tglRespon: map['tgl_respon'], // Ambil data tglRespon jika ada
      kodeDealer: map['kode_dealer'] ?? '-',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'no_rangka': noRangka,
      'no_polisi': noPolisi,
      'nama_cust': namaCust,
      'almt_cust': almtCust,
      'kota': kota,
      'no_telp': noTelp,
      'nama_sales': namaSales,
      'tgl_faktur': tglFaktur,
      'tahun': tahun,
      'ck1': ck1,
      'ck2': ck2,
      'pb15': pb15,
      'pb20': pb20,
      'pb25': pb25,
      'pb30': pb30,
      'pb35': pb35,
      'pb40': pb40,
      'pic_fu': picFU,
      'respon': respon,
      'tgl_respon': tglRespon,
      'kode_dealer': kodeDealer,
    };
  }
}

class DataEusPage extends StatefulWidget {
  const DataEusPage({super.key});

  @override
  State<DataEusPage> createState() => _DataEusPageState();
}

class _DataEusPageState extends State<DataEusPage> {
  List<DataEus> _dataList = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String kodeDealer = '';
  bool sts = false;
  @override
  void initState() {
    super.initState();
    _loadDataFromSupabase();
    _searchController.addListener(_onSearchChanged);
  }

  // --- VARIABEL UNTUK PAGINATION ---
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int _pageIndex = 0;
  final _pageController = ScrollController();
  // ---------------------------------
  void _onSearchChanged() {
    setState(() {
      _isLoading = true;
      _searchQuery = _searchController.text;
      _pageIndex = 0;
      _isLoading = false;
    });
  }

  // Ganti fungsi _loadExcel() dengan fungsi ini
  Future<void> _loadDataFromSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    kodeDealer = prefs.getString('dealer_kode') ?? '';
    final picDealer = prefs.getString('dealer_pic') ?? '';
    setState(() => _isLoading = true);

    try {
      sts = await supabase
          .from('users')
          .select('id')
          .eq('pic', picDealer)
          .eq('sts', true)
          .then((value) => value.isNotEmpty);

      // Asumsi nama tabel Supabase Anda adalah 'data_eus'
      final response = await supabase
          .from('dataeus') // Ganti jika nama tabel Anda berbeda
          .select('*')
          .eq('kode_dealer', kodeDealer) // Ambil semua kolom
          .order('tahun', ascending: true); // Contoh: Urutkan berdasarkan nama

      // Pastikan response adalah List<Map<String, dynamic>>
      final List<Map<String, dynamic>> dataMaps =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        _dataList = dataMaps
            .map(
              (map) => DataEus.fromMap(map),
            ) // Mapping menggunakan constructor baru
            .toList();
        _isLoading = false;
      });
      supabase
          .from('dataeus')
          .stream(primaryKey: ['id'])
          .eq('kode_dealer', kodeDealer)
          .listen((event) {
            setState(() {
              _dataList = event
                  .map(
                    (map) => DataEus.fromMap(map),
                  ) // Mapping menggunakan constructor baru
                  .toList();
            }); // Reload data saat ada perubahan
          });
    } on PostgrestException catch (e) {
      debugPrint('Supabase Error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: ${e.message}')),
        );
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('General Error: $e');
      setState(() => _isLoading = false);
    }
  }

  // Masukkan fungsi ini di dalam class _DataEusPageState
  List<DataEus> _getFilteredData() {
    if (_searchQuery.isEmpty) {
      return _dataList;
    }

    final query = _searchQuery.toLowerCase();

    return _dataList.where((data) {
      // Cek apakah query ada di Nama Customer
      final matchName = data.namaCust.toLowerCase().contains(query);
      // Cek apakah query ada di No. Polisi
      final matchPolice = data.noPolisi.toLowerCase().contains(query);
      // Cek apakah query ada di No. Telepon
      final matchPhone = data.noRangka.toLowerCase().contains(query);

      // Kembalikan true jika salah satu kondisi cocok
      return matchName || matchPolice || matchPhone;
    }).toList();
  }

  // Fungsi untuk Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dealer_kode');
    await prefs.remove('dealer_pic');
    await supabase.auth.signOut();
    if (mounted) {
      // Ganti aplikasi ke layar registrasi (seperti di main())
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const RegistrationFormScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Fungsi navigasi
  void _navigateToUploadDownloadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadDownloadScreen()),
    );
  }

  void _navigateToResponseChartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResponseChartPage()),
    );
  }

  void _navigateToCkChartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CkStatPage()),
    );
  }

  void _navigateToPicChartPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PicStatPage()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Widget untuk menu item
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isWeb = false,
  }) {
    if (isWeb) {
      // Menu Bar Item (Web)
      return TextButton.icon(
        icon: Icon(icon, color: Colors.black),
        label: Text(title, style: const TextStyle(color: Colors.black)),
        onPressed: onTap,
      );
    } else {
      // Drawer Item (Mobile)
      return ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        onTap: () {
          Navigator.pop(context); // Tutup drawer
          onTap();
        },
      );
    }
  }

  // Widget untuk Menu Bar (Web)
  Widget _buildWebMenuBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (sts)
          _buildMenuItem(
            title: 'Upload/Download',
            icon: Icons.add_task,
            onTap: _navigateToUploadDownloadScreen,
            isWeb: true,
          ),
        _buildMenuItem(
          title: 'Chart Respon',
          icon: Icons.show_chart,
          onTap: _navigateToResponseChartPage,
          isWeb: true,
        ),
        _buildMenuItem(
          title: 'Chart PIC',
          icon: Icons.show_chart,
          onTap: _navigateToPicChartPage,
          isWeb: true,
        ),
        _buildMenuItem(
          title: 'Chart CK',
          icon: Icons.show_chart,
          onTap: _navigateToCkChartPage,
          isWeb: true,
        ),
        _buildMenuItem(
          title: 'Reset',
          icon: Icons.logout,
          onTap: _logout,
          isWeb: true,
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // Widget untuk Drawer (Mobile)
  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu Aplikasi',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (sts)
            _buildMenuItem(
              title: 'Upload/Download Data',
              icon: Icons.add_task,
              onTap: _navigateToUploadDownloadScreen,
            ),
          _buildMenuItem(
            title: 'Lihat Chart Respon',
            icon: Icons.show_chart,
            onTap: _navigateToResponseChartPage,
          ),
          _buildMenuItem(
            title: 'Lihat Chart PIC',
            icon: Icons.show_chart,
            onTap: _navigateToPicChartPage,
          ),
          _buildMenuItem(
            title: 'Lihat Chart CK',
            icon: Icons.show_chart,
            onTap: _navigateToCkChartPage,
          ),
          const Divider(),
          _buildMenuItem(title: 'Reset', icon: Icons.logout, onTap: _logout),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    // --- BUAT DATA SOURCE BARU SETIAP KALI BUILD/DATA BERUBAH ---
    final dataSource = _DataEusDataSource(data: filteredData, context: context);
    // -----------------------------------------------------------
    final bool isWeb =
        kIsWeb &&
        MediaQuery.of(context).size.width >
            768; // Pengecekan apakah berjalan di web

    return Scaffold(
      appBar: AppBar(
        title: const Text("Data EUS"),
        // Jika web, gunakan Menu Bar di actions
        // Jika mobile, biarkan actions kosong (Drawer akan muncul otomatis)
        actions: isWeb ? [_buildWebMenuBar()] : null,
      ),
      // Jika mobile, gunakan Drawer
      drawer: isWeb ? null : _buildMobileDrawer(),
      body: RefreshIndicator(
        onRefresh: () {
          return _loadDataFromSupabase();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Gunakan Column untuk menempatkan Search Bar di atas Tabel
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- KOLOM PENCARIAN BARU ---
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari Data (Nama/No. Polisi/No. Rangka)',
                  hintText: 'Masukkan kata kunci...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16), // Jarak antara search bar dan tabel
              Expanded(
                // Pastikan tabel berada di dalam Expanded/SizedBox karena di dalam Column
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredData.isEmpty
                    ? const Center(child: Text("Tidak ada data."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        controller: _pageController,
                        child: PaginatedDataTable(
                          header: Text("Total Data: ${filteredData.length}"),
                          headingRowHeight: 30,
                          rowsPerPage: _rowsPerPage,
                          arrowHeadColor: Colors.blue,
                          headingRowColor: WidgetStateProperty.all(
                            Colors.blue.shade100,
                          ),
                          dividerThickness: 1,
                          onRowsPerPageChanged: (value) {
                            setState(() {
                              _rowsPerPage = value!;
                            });
                          },
                          availableRowsPerPage: const [10, 25, 50, 100],
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          onPageChanged: (index) {
                            // Update index saat halaman berubah
                            setState(() {
                              _pageIndex = index;
                            });
                            // Scroll ke atas saat pindah halaman
                            _pageController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          source: dataSource, // Warna header lebih tebal
                          columns: const [
                            DataColumn(
                              label: Text(
                                'No.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Nama Customer',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'WhatsApp',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(label: Text('Kota')),
                            DataColumn(label: Text('No. Polisi')),
                            DataColumn(label: Text('No. Rangka')),
                            DataColumn(label: Text('Sales')),
                            DataColumn(label: Text('Alamat')),
                            DataColumn(label: Text('Tgl. Faktur')),
                            DataColumn(label: Text('Tahun')),
                            DataColumn(label: Text('Checking 1')),
                            DataColumn(label: Text('Checking 2')),
                            DataColumn(label: Text('PB 15')),
                            DataColumn(label: Text('PB 20')),
                            DataColumn(label: Text('PB 25')),
                            DataColumn(label: Text('PB 30')),
                            DataColumn(label: Text('PB 35')),
                            DataColumn(label: Text('PB 40')),
                            DataColumn(label: Text('PIC FU')),
                            DataColumn(label: Text('Respon')),
                            DataColumn(label: Text('Tgl. Respon')),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ======================================================================
// 1. KELAS BARU UNTUK DATATABLESOURCE
// ======================================================================

class _DataEusDataSource extends DataTableSource {
  final List<DataEus> data;
  final BuildContext context;

  _DataEusDataSource({required this.data, required this.context});

  // // --- FUNGSI KLIK WHATSAPP (Diulang di sini untuk akses mudah) ---
  // Future<void> _launchWhatsApp(String phone) async {
  //   String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
  //   if (cleanPhone.startsWith('0')) cleanPhone = '62${cleanPhone.substring(1)}';
  //   final Uri url = Uri.parse("https://wa.me/$cleanPhone");
  //   await launchUrl(url, mode: LaunchMode.externalApplication);
  // }

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;

    final DataEus dataEus = data[index];

    // Fungsi untuk navigasi ke ResponseCallScreen
    void navigateToResponseScreen() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResponseCallScreen(customerData: dataEus),
        ),
      );
    }

    return DataRow(
      color: dataEus.tglRespon != null && dataEus.tglRespon!.isNotEmpty
          ? index % 2 == 0
                ? WidgetStateProperty.all(Colors.white)
                : WidgetStateProperty.all(Colors.grey.shade300)
          : WidgetStateProperty.all(Colors.yellow.shade100),
      cells: [
        DataCell(Text((index + 1).toString())),
        DataCell(Text(dataEus.namaCust)),

        // --- TOMBOL WHATSAPP (menggunakan InkWell seperti sebelumnya) ---
        DataCell(
          InkWell(
            onTap: navigateToResponseScreen,
            child: Row(
              children: [
                const Icon(Icons.chat_bubble, color: Colors.green, size: 20),
                const SizedBox(width: 6),
                Text(
                  dataEus.noTelp,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
        // -----------------------
        DataCell(Text(dataEus.kota)),
        DataCell(Text(dataEus.noPolisi)),
        DataCell(Text(dataEus.noRangka)),
        DataCell(Text(dataEus.namaSales)),
        DataCell(
          SizedBox(
            width: 250,
            child: Text(dataEus.almtCust, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(dataEus.tglFaktur)),
        DataCell(Text(dataEus.tahun)),
        DataCell(Text(dataEus.ck1)),
        DataCell(Text(dataEus.ck2)),
        DataCell(Text(dataEus.pb15)),
        DataCell(Text(dataEus.pb20)),
        DataCell(Text(dataEus.pb25)),
        DataCell(Text(dataEus.pb30)),
        DataCell(Text(dataEus.pb35)),
        DataCell(Text(dataEus.pb40)),
        DataCell(Text(dataEus.picFU)),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(dataEus.respon ?? '-', overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              dataEus.tglRespon ?? '-',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
// ======================================================================
// 2. LAYAR BARU (CHOICE & SUBMIT) - ResponseCallScreen
// ======================================================================

class ResponseCallScreen extends StatefulWidget {
  final DataEus customerData;

  const ResponseCallScreen({super.key, required this.customerData});

  @override
  State<ResponseCallScreen> createState() => _ResponseCallScreenState();
}

class _ResponseCallScreenState extends State<ResponseCallScreen> {
  final TextEditingController _responseController = TextEditingController();
  bool _isSubmitting = false;

  // --- FUNGSI KLIK WHATSAPP (Diulang di sini untuk akses mudah) ---
  Future<void> _launchWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) cleanPhone = '62${cleanPhone.substring(1)}';
    final Uri url = Uri.parse("https://wa.me/$cleanPhone");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // --- FUNGSI PANGGILAN TELEPON (Diulang di sini) ---
  Future<void> _launchPhoneCall(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Logika untuk mengubah format jika diperlukan (misal: +62 -> 0)
    // if (cleanPhone.substring(1, 3) == "62") {
    //   cleanPhone = "0${cleanPhone.substring(3)}";
    // }
    final Uri url = Uri.parse("tel:$cleanPhone");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // --- FUNGSI SUBMIT KE SUPABASE ---
  Future<void> _submitResponse() async {
    if (_responseController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Respons tidak boleh kosong.')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final savedPic = prefs.getString('dealer_pic');
    final responseData = {
      'tgl_respon': DateTime.now().toIso8601String().substring(
        0,
        10,
      ), // Hanya tanggal
      'pic_fu': savedPic,
      'respon': _responseController.text.trim(),
      // Anda bisa menambahkan kolom lain yang relevan di sini (misal: user_id yang merespons)
    };

    try {
      // PERHATIAN: Pastikan Anda memiliki tabel bernama 'call_responses' di Supabase
      // dengan kolom: timestamp, no_telp, nama_cust, no_polisi, response_text
      await supabase
          .from('dataeus')
          .update(responseData)
          .eq('no_rangka', widget.customerData.noRangka);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respons berhasil dikirim ke Data EUS!'),
          ),
        );
        Navigator.of(context).pop(); // Kembali ke layar sebelumnya (Tabel)
      }
    } on PostgrestException catch (e) {
      debugPrint("Data Error: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim: ${e.message}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan umum.')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _responseController.text = widget.customerData.respon ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail & Log Respon Panggilan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- DETAIL CUSTOMER ---
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Customer:",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      widget.customerData.namaCust,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("No. Polisi: ${widget.customerData.noPolisi}"),
                    Text(
                      "No. Telp: ${widget.customerData.noTelp}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- CHOICE (PILIHAN) ---
            const Text(
              "Pilih Cara Menghubungi:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Panggilan
                ElevatedButton.icon(
                  onPressed: () => _launchPhoneCall(widget.customerData.noTelp),
                  icon: const Icon(Icons.call),
                  label: const Text("Panggil Telepon"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                  ),
                ),
                // Tombol WhatsApp
                ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(widget.customerData.noTelp),
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text("Buka WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- TEXT EDITING AND SUBMIT ---
            const Text(
              "Catat Respon Panggilan:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),

            TextField(
              controller: _responseController,
              decoration: const InputDecoration(
                hintText:
                    "Hasil Respon (Contoh: Tidak diangkat/Telepon balik 2 hari lagi)",
                labelText: ' Hasil Respon : ',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitResponse,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting ? "Mengirim..." : "Submit Respon Panggilan",
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
