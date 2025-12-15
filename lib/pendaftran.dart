import 'package:flutter/material.dart';
import 'package:mpo/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pastikan inisialisasi Supabase sudah ada di main() Anda
final supabase = Supabase.instance.client;

class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({super.key});

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk input form
  final TextEditingController _kodeDealerController = TextEditingController();
  final TextEditingController _namaDealerController = TextEditingController();
  final TextEditingController _picController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _kodeDealerController.dispose();
    _namaDealerController.dispose();
    _picController.dispose();
    super.dispose();
  }

  // --- FUNGSI BARU: SIMPAN INFO DEALER KE SHARED PREFERENCES ---
  Future<void> _saveDealerInfo(String kodeDealer, String pic) async {
    final prefs = await SharedPreferences.getInstance();

    // Simpan kode dealer
    await prefs.setString('dealer_kode', kodeDealer);

    // Simpan nama PIC
    await prefs.setString('dealer_pic', pic);

    debugPrint(
      'Data berhasil disimpan lokal: Kode Dealer $kodeDealer, PIC $pic',
    );
  }

  // --- FUNGSI SUBMIT DATA KE SUPABASE ---
  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final registrationData = {
        // Kolom sesuai dengan file CSV Anda:
        'kode_dealer': _kodeDealerController.text.trim(),
        'nama_dealer': _namaDealerController.text.trim(),
        'pic': _picController.text.trim(),
        'sts': false, // Default status pendaftaran baru adalah false/pending
        // created_at dan id akan dibuat otomatis oleh Supabase
      };

      try {
        // PERHATIAN: Ganti 'users' dengan nama tabel Anda di Supabase (misal: 'dealer')
        await supabase.from('users').insert(registrationData);
        await _saveDealerInfo(
          _kodeDealerController.text.trim(),
          _picController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil! Data telah disimpan.'),
            ),
          );
          // Kosongkan form setelah sukses
          _kodeDealerController.clear();
          _namaDealerController.clear();
          _picController.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyApp()),
          ); // Kembali ke halaman sebelumnya
        }
      } on PostgrestException catch (e) {
        debugPrint("Supabase Error: ${e.message}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mendaftar: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terjadi kesalahan umum saat mendaftar.'),
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Form Pendaftaran Dealer")),
      body: Center(
        child: Container(
          width: 500, // Lebar Form di Flutter Web
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Pendaftaran Pengguna Baru",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 30),

                  // 1. Kode Dealer
                  TextFormField(
                    controller: _kodeDealerController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Kode Dealer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kode Dealer tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Nama Dealer
                  TextFormField(
                    controller: _namaDealerController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nama Dealer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama Dealer tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. PIC (Person In Charge)
                  TextFormField(
                    controller: _picController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pengguna',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama Pengguna tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 4. Tombol Submit
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'DAFTAR SEKARANG',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
