import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const FiyatAvcisiApp());
}

class FiyatAvcisiApp extends StatelessWidget {
  const FiyatAvcisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fiyat Avcisi (%90+)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const FiyatTakipEkrani(),
    );
  }
}

class UrunKaydi {
  final String baslik;
  final String platform;
  final String link;
  final double eskiFiyat;
  final double yeniFiyat;

  UrunKaydi({
    required this.baslik,
    required this.platform,
    required this.link,
    required this.eskiFiyat,
    required this.yeniFiyat,
  });

  double get yuzdeDegisim {
    if (eskiFiyat <= 0) return 0;
    return ((yeniFiyat - eskiFiyat) / eskiFiyat) * 100;
  }

  bool get yuzde90DusustuMu => yuzdeDegisim <= -90.0;
}

class FiyatTakipEkrani extends StatefulWidget {
  const FiyatTakipEkrani({super.key});

  @override
  State<FiyatTakipEkrani> createState() => _FiyatTakipEkraniState();
}

class _FiyatTakipEkraniState extends State<FiyatTakipEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _baslikController = TextEditingController();
  final _linkController = TextEditingController();
  final _eskiFiyatController = TextEditingController();
  final _yeniFiyatController = TextEditingController();

  String _seciliPlatform = 'Trendyol';
  bool _otomatikPaylasAktif = true;
  final List<UrunKaydi> _kayitlar = [];

  @override
  void dispose() {
    _baslikController.dispose();
    _linkController.dispose();
    _eskiFiyatController.dispose();
    _yeniFiyatController.dispose();
    super.dispose();
  }

  Future<void> _linkPaylas(UrunKaydi urun) async {
    final oranText = urun.yuzdeDegisim.abs().toStringAsFixed(1);
    final mesaj =
        '%%%$oranText FIYAT DUSUSU (${urun.platform})!\n'
        '${urun.baslik}\n'
        'Eski: ${urun.eskiFiyat.toStringAsFixed(2)} TL -> Yeni: ${urun.yeniFiyat.toStringAsFixed(2)} TL\n'
        'Link: ${urun.link}';

    await Share.share(mesaj, subject: 'Yuzde 90+ Fiyat Dususu Yakalandi');
  }

  void _urunEkleVeKontrolEt() {
    if (!_formKey.currentState!.validate()) return;

    final eskiFiyat =
        double.tryParse(_eskiFiyatController.text.replaceAll(',', '.')) ?? 0;
    final yeniFiyat =
        double.tryParse(_yeniFiyatController.text.replaceAll(',', '.')) ?? 0;

    final yeniKayit = UrunKaydi(
      baslik: _baslikController.text.trim(),
      platform: _seciliPlatform,
      link: _linkController.text.trim(),
      eskiFiyat: eskiFiyat,
      yeniFiyat: yeniFiyat,
    );

    setState(() {
      _kayitlar.insert(0, yeniKayit);
    });

    if (yeniKayit.yuzde90DusustuMu && _otomatikPaylasAktif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('%90+ dusus tespit edildi! Paylasim ekrani aciliyor...'),
        ),
      );
      _linkPaylas(yeniKayit);
    }

    _baslikController.clear();
    _linkController.clear();
    _eskiFiyatController.clear();
    _yeniFiyatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiyat Avcisi (%90+ Degisim)'),
        actions: [
          Row(
            children: [
              const Text('Oto Paylas', style: TextStyle(fontSize: 12)),
              Switch(
                value: _otomatikPaylasAktif,
                onChanged: (val) => setState(() => _otomatikPaylasAktif = val),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _seciliPlatform,
                        decoration: const InputDecoration(
                          labelText: 'Platform',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Trendyol', child: Text('Trendyol')),
                          DropdownMenuItem(value: 'Amazon', child: Text('Amazon')),
                          DropdownMenuItem(value: 'Hepsiburada', child: Text('Hepsiburada')),
                          DropdownMenuItem(value: 'Diger', child: Text('Diger')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _seciliPlatform = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _baslikController,
                        decoration: const InputDecoration(
                          labelText: 'Urun Adi',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Urun adi girin' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _linkController,
                        decoration: const InputDecoration(
                          labelText: 'Urun Linki (https://...)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || !v.trim().startsWith('http')) {
                            return 'Gecerli bir http/https linki girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _eskiFiyatController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Onceki Fiyat (TL)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final n = double.tryParse(
                                    (v ?? '').replaceAll(',', '.'));
                                if (n == null || n <= 0) return 'Gecersiz fiyat';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _yeniFiyatController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Yeni Fiyat (TL)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final n = double.tryParse(
                                    (v ?? '').replaceAll(',', '.'));
                                if (n == null || n < 0) return 'Gecersiz fiyat';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _urunEkleVeKontrolEt,
                          icon: const Icon(Icons.bolt),
                          label: const Text('Kaydet ve %90 Degisimi Kontrol Et'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _kayitlar.isEmpty
                ? const Center(child: Text('Henuz kontrol edilen urun yok.'))
                : ListView.builder(
                    itemCount: _kayitlar.length,
                    itemBuilder: (context, index) {
                      final item = _kayitlar[index];
                      final degisim = item.yuzdeDegisim;
                      final alarm = item.yuzde90DusustuMu;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            alarm ? Icons.local_fire_department : Icons.show_chart,
                            color: alarm ? Colors.red : Colors.grey,
                          ),
                          title: Text('${item.baslik} (${item.platform})'),
                          subtitle: Text(
                            '${item.eskiFiyat.toStringAsFixed(0)} TL -> ${item.yeniFiyat.toStringAsFixed(0)} TL '
                            '(${degisim.toStringAsFixed(1)}%)',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => _linkPaylas(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
