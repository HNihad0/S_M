import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmekdasDovriyyesiPage extends StatefulWidget {
  @override
  _EmekdasDovriyyesiPageState createState() => _EmekdasDovriyyesiPageState();
}

class _EmekdasDovriyyesiPageState extends State<EmekdasDovriyyesiPage>  {
  List<dynamic> data = [];
  bool isLoading = false;
  DateTime? startDate;
  DateTime? endDate;
  final int userId = 1;

  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();

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
    final String baseUrl = 'http://10.0.2.2:3000/api/emekdas-dovriyyesi';
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
        });
      } else {
        throw Exception('Veri çekme başarısız oldu: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Hata oluştu: $error');
      // Xəta vəziyyətində istifadəçiyə bildiriş göstəriləbilir
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
                        'Əməkdaş Dövriyyəsi',
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
                                    DataColumn(label: Text('Əməkdaş')),
                                    DataColumn(label: Text('İlkin Qalıq')),
                                    DataColumn(label: Text('Artıb')),
                                    DataColumn(label: Text('Azalıb')),
                                    DataColumn(label: Text('Son Qalıq')),
                                    DataColumn(label: Text('Qeyd')),
                                  ],
                                  rows: data.map((item) {
                                    return DataRow(cells: [
                                      DataCell(Text(item['idn'] ?? '')),
                                      DataCell(Text(item['kontra_name'] ?? '')),
                                      DataCell(Text(item['ilkqal']?.toString() ?? '')),
                                      DataCell(Text(item['medmiq']?.toString() ?? '')),
                                      DataCell(Text(item['mexmiq']?.toString() ?? '')),
                                      DataCell(Text(item['sonqal']?.toString() ?? '')),
                                      DataCell(Text(item['qeyd'] ?? '')),
                                      
                                    ]);
                                  }).toList(),
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
                      width: 120,
                      child: TextField(
                        controller: startDateController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.calendar_today, size: 18),
                          labelText: 'Başlama Tarixi',
                        ),
                        readOnly: true,
                        onTap: () => _selectStartDate(context),
                      ),
                    ),
                    const SizedBox(width: 22),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: endDateController,
                        decoration: const InputDecoration(
                          icon: Icon(Icons.calendar_today, size: 18),
                          labelText: 'Bitmə Tarixi',
                        ),
                        readOnly: true,
                        onTap: () => _selectEndDate(context),
                      ),
                    ),
                    const SizedBox(width: 30),
                    TextButton.icon(
                      onPressed: fetchData,
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