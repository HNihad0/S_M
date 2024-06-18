import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CariHesab extends StatefulWidget {
  final bool showAppBar;

  CariHesab({this.showAppBar = true});
  
  @override
  _CariHesabState createState() => _CariHesabState();
}

class _CariHesabState extends State<CariHesab> {
  List<dynamic> data = [];
  bool isLoading = false;
  DateTime? startDate;
  DateTime? endDate;
  final int userId = 1;

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

  double toplamVerilecek = 0.0;
  double toplamAlinacak = 0.0;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    startDate = now;
    endDate = now;
    startDateController.text = DateFormat('dd-MM-yyyy').format(startDate!);
    endDateController.text = DateFormat('dd-MM-yyyy').format(endDate!);
  }

  Future<void> fetchData() async {
    final String baseUrl = 'http://192.168.0.103:3000/api/cari_hes';
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    startDate ??= DateTime.now();
    endDate ??= DateTime.now();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl?start=${formatter.format(startDate!)}&end=${formatter.format(endDate!)}&user=$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          toplamVerilecek = data.fold<double>(0, (sum, item) => sum + (item['ilkqal'] ?? 0).toDouble());
          toplamAlinacak = data.fold<double>(0, (sum, item) => sum + (item['sonqal'] ?? 0).toDouble());
        });
      } else {
        throw Exception('Veri çekme başarısız oldu: ${response.reasonPhrase}');
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor:  Color.fromARGB(255, 56, 103, 154),
          content: Text('İnternetə qoşulmayıb. İnternet əlaqənizi yoxlayın.'),
        ),
      );
    } on HttpException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor:  Color.fromARGB(255, 56, 103, 154),
          content: Text('HTTP hatası: Bağlantı kurulamadı.'),
        ),
      );
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor:  Color.fromARGB(255, 56, 103, 154),
          content: Text('Format hatası: Geçersiz yanıt alındı.'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:  const Color.fromARGB(255, 56, 103, 154),
          content: Text('Xəta baş verdi: $error'),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedStartDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedStartDate != null && pickedStartDate != startDate) {
      if (pickedStartDate.isAfter(endDate!)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Tarix aralığı xətası"),
              content: const Text("Başlama tarixi bitmə tarixindən sonra ola bilməz"),
              actions: [
                TextButton(
                  child: const Text("Tamam"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          startDate = pickedStartDate;
          startDateController.text = DateFormat('dd-MM-yyyy').format(startDate!);
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedEndDate != null && pickedEndDate != endDate) {
      if (pickedEndDate.isBefore(startDate!)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Tarix aralığı xətası"),
              content: const Text("Bitmə tarixi başlama tarixindən əvvəl ola bilməz"),
              actions: [
                TextButton(
                  child: const Text("Tamam"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          endDate = pickedEndDate;
          endDateController.text = DateFormat('dd-MM-yyyy').format(endDate!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text("Soffen Mobil", style: TextStyle(color: Colors.white)),
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
              ),
              elevation: 0.00,
              backgroundColor: const Color.fromARGB(255, 56, 103, 154),
            )
          : null,
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Stack(
            children: [
              Column(
                children: [
                  const Padding(padding: EdgeInsets.all(30)),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cari hesablar',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : data.isEmpty
                            ? const Center(child: Text('Məlumat yoxdur'))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('IDN')),
                                    DataColumn(label: Text('Adı')),
                                    DataColumn(label: Text('Veriləcək')),
                                    DataColumn(label: Text('Alınacaq')),
                                  ],
                                  rows: [
                                    ...data.map((item) {
                                      return DataRow(cells: [
                                        DataCell(Text(item['idn'].toString())),
                                        DataCell(Text(item['kontra_name'] ?? '')),
                                        DataCell(Text(item['ilkqal'].toString())),
                                        DataCell(Text(item['sonqal'].toString())),
                                      ]);
                                    }).toList(),
                                    DataRow(cells: [
                                      const DataCell(Text('Toplam', style: TextStyle(fontWeight: FontWeight.bold))),
                                      const DataCell(Text('')),
                                      DataCell(Text(toplamVerilecek.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                      DataCell(Text(toplamAlinacak.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    ]),
                                  ],
                                ),
                              ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 7.5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 120,  // Genişliği küçültmek için
                      child: TextField(
                        controller: startDateController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.calendar_today, size: 18),  // Icon boyutunu küçültmek için
                          labelText: 'Başlama Tarixi',
                        ),
                        readOnly: true,
                        onTap: () => _selectStartDate(context),
                      ),
                    ),
                    const SizedBox(width: 22),
                    SizedBox(
                      width: 120,  // Genişliği küçültmek için
                      child: TextField(
                        controller: endDateController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.calendar_today, size: 18),  // Icon boyutunu küçültmek için
                          labelText: 'Bitmə Tarixi',
                        ),
                        readOnly: true,
                        onTap: () => _selectEndDate(context),
                      ),
                    ),
                    const SizedBox(width: 30),
                    TextButton.icon(
                      onPressed: (){},
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Axtar'),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: const Color.fromARGB(255, 56, 103, 154),
                  onPressed: fetchData,
                  child: const Icon(Icons.calculate, color: Colors.white, size: 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
