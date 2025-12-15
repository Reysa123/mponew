import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mpo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Ganti dengan konfigurasi Supabase Client Anda
final supabase = Supabase.instance.client;

class UploadDownloadScreen extends StatefulWidget {
  const UploadDownloadScreen({super.key});

  @override
  State<UploadDownloadScreen> createState() => _UploadDownloadScreenState();
}

class _UploadDownloadScreenState extends State<UploadDownloadScreen> {
  double _uploadProgress = 0.0;
  String _uploadStatus = 'Siap Upload';
  double _downloadProgress = 0.0;
  String _downloadStatus = 'Siap Download';

  final String bucketName = 'data-storage'; // Ganti dengan nama bucket Anda
  final String templateFileName = 'template_data_eus.xlsx'; // Nama template

  // --- LOGIKA UPLOAD ---
  Future<void> _uploadData() async {
    final prefs = await SharedPreferences.getInstance();
    final kodeDealer = prefs.getString('dealer_kode') ?? '';
    setState(() {
      _uploadStatus = 'Memilih file...';
      _uploadProgress = 0.0;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );

    if (result == null || result.files.single.bytes == null) {
      setState(() => _uploadStatus = 'Batal memilih file.');
      return;
    }

    final fileBytes = result.files.single.bytes!;
    final fileName = 'data_eus_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    try {
      setState(() {
        _uploadStatus = 'Mengunggah ke awan...';
        _uploadProgress = 0.1; // Mulai progress
      });

      // Upload file ke Supabase Storage
      // 2. Decode Excel
      var excel = Excel.decodeBytes(fileBytes);

      List<DataEus> tempList = [];

      // 3. Loop setiap Sheet (biasanya sheet pertama)
      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];

        if (sheet != null) {
          // Loop setiap baris (mulai index 1 untuk skip Header di index 0)
          // Pastikan baris > 1 agar tidak error jika file kosong
          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.rows[i];

            // Cek jika baris kosong (kadang excel membaca baris kosong di akhir)
            if (row.isEmpty) continue;

            // Helper function agar aman saat ambil data (menghindari null)
            String getVal(int index) {
              if (index >= row.length) return ''; // Handle jika kolom kurang
              return row[index]?.value?.toString() ?? "";
            }

            // Mapping kolom (Sesuaikan urutan kolom di Excel Anda)
            // 0:NoRangka, 1:NoPol, 2:Nama, 3:Alamat, 4:Kota, 5:NoTelp, 6:Sales, 7:Tgl, 8:Thn
            if (getVal(0).isEmpty) continue; // Skip jika NoRangka kosong
            tempList.add(
              DataEus(
                noRangka: getVal(0),
                noPolisi: getVal(1),
                namaCust: getVal(2),
                almtCust: getVal(3),
                kota: getVal(4),
                noTelp: getVal(5), // Ini yang akan kita pakai untuk WA
                namaSales: getVal(6),
                tglFaktur: getVal(7),
                tahun: getVal(8),
                ck1: "",
                ck2: "",
                pb15: "",
                pb20: "",
                pb25: "",
                pb30: "",
                pb35: "",
                pb40: "",
                picFU: "",
                respon: "",
                tglRespon: "",
                kodeDealer: kodeDealer,
              ),
            );
          }
        }
      }
      await supabase
          .from('dataeus')
          .upsert(tempList.map((e) => e.toMap()).toList());

      setState(() {
        _uploadStatus = "Upload berhasil: $fileName";
        _uploadProgress = 1.0;
      });
    } on StorageException catch (e) {
      setState(() {
        _uploadStatus = "Gagal upload: ${e.message}";
        _uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _uploadStatus = "Error: ${e.toString()}";
        _uploadProgress = 0.0;
      });
    }
  }

  // --- LOGIKA DOWNLOAD TEMPLATE ---
  Future<void> _downloadTemplate() async {
    setState(() {
      _downloadStatus = 'Mendapatkan link download...';
      _downloadProgress = 0.0;
    });

    try {
      // 1. Dapatkan URL tanda tangan (signed URL)
      final url = await supabase.storage
          .from(bucketName)
          .createSignedUrl(templateFileName, 60);

      setState(() {
        _downloadStatus = 'Link berhasil dibuat. Membuka browser...';
        _downloadProgress = 0.5;
      });

      // 2. Buka URL untuk download (di Flutter Web ini akan otomatis mendownload)
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

        setState(() {
          _downloadStatus = "Template '$templateFileName' berhasil didownload!";
          _downloadProgress = 1.0;
        });
      } else {
        throw 'Tidak dapat membuka link download.';
      }
    } on StorageException catch (e) {
      setState(() {
        _downloadStatus = "Gagal download: ${e.message}";
        _downloadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _downloadStatus = "Error: Gagal mendownload template.";
        _downloadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Data EUS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- FITUR DOWNLOAD ---
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Download Template Excel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _downloadTemplate,
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Download Template .xlsx'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.yellow.shade700,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          shadowColor: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 5),
                      Text('Status: $_downloadStatus'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // --- FITUR UPLOAD ---
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload Data Excel Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _uploadData,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Pilih & Upload File .xlsx'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          shadowColor: Colors.yellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 5),
                      Text('Status: $_uploadStatus'),
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
