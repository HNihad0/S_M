import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:soffen_mobile/ana_seh.dart';
import 'package:soffen_mobile/cari_hes.dart';
import 'package:soffen_mobile/cari_hes_dov.dart';
import 'package:soffen_mobile/emek_dov.dart';
import 'package:soffen_mobile/gelir_hes.dart';
import 'package:soffen_mobile/kas_dov.dart';
import 'package:soffen_mobile/kas_hes.dart';
import 'package:soffen_mobile/my_flutter_app_icons.dart';
import 'package:soffen_mobile/xerc_hes.dart';

class PinCodeWidget extends StatefulWidget {
  const PinCodeWidget({super.key});

  @override
  State<PinCodeWidget> createState() => _PinCodeWidgetState();
}

class _PinCodeWidgetState extends State<PinCodeWidget> {
  static const String correctPin = '0000'; // ŞİFRƏ
  String enteredPin = '';
  bool isPinVisible = false;
  String feedbackMessage = '';

  Widget numButton(int number) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton(
        onPressed: () {
          setState(() {
            if (enteredPin.length < 4) {
              enteredPin += number.toString();
              if (enteredPin.length == 4) {
                validatePin();
              }
            }
          });
        },
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  void validatePin() {
    if (enteredPin == correctPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Menu()),
      );
    } else {
      setState(() {
        feedbackMessage = 'Şifrə yanlışdır!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(218, 241, 241, 241),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/soffen-logo.png',
                width: 145,
                height: 145,
              ),
              const Center(
                child: Text(
                  'Şifrə daxil edin',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              /// PIN kod hissəsi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) {
                    return Container(
                      margin: const EdgeInsets.all(6.0),
                      width: isPinVisible ? 50 : 16,
                      height: isPinVisible ? 50 : 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                        color: index < enteredPin.length
                            ? isPinVisible
                                ? Colors.green
                                : CupertinoColors.activeBlue
                            : CupertinoColors.activeBlue.withOpacity(0.1),
                      ),
                      child: isPinVisible && index < enteredPin.length
                          ? Center(
                              child: Text(
                                enteredPin[index],
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
              ),

              /// Şifrənin görünüb-görünməməsi üçün buton
              IconButton(
                onPressed: () {
                  setState(() {
                    isPinVisible = !isPinVisible;
                  });
                },
                icon: Icon(
                  isPinVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),

              SizedBox(height: isPinVisible ? 50.0 : 8.0),

              /// Rəqəmlər
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      3,
                      (index) => numButton(1 + 3 * i + index),
                    ).toList(),
                  ),
                ),

              /// Rəqəmləri bir-bir silmə butonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TextButton(onPressed: null, child: SizedBox()),
                    numButton(0),
                    TextButton(
                      onPressed: () {
                        setState(
                          () {
                            if (enteredPin.isNotEmpty) {
                              enteredPin =
                                  enteredPin.substring(0, enteredPin.length - 1);
                            }
                          },
                        );
                      },
                      child: const Icon(
                        Icons.backspace,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              /// Geri dönüş mesajı
              Center(
                child: Text(
                  feedbackMessage,
                  style: TextStyle(
                    fontSize: 20,
                    color: feedbackMessage == 'Şifrə doğrudur'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),

              /// Sıfırla button
              TextButton(
                onPressed: () {
                  setState(() {
                    enteredPin = '';
                    feedbackMessage = '';
                  });
                },
                child: const Text(
                  'Sıfırla',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
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

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String selectedPage = '';

  @override
  Widget build(BuildContext context) {
    Widget content;

    switch (selectedPage) {
      case 'Ana Səhifə':
        content = const HomePage();
        break;
      case 'Kassa hesabatı':
        content = MSSQLTableDataFetch(showAppBar: false);
        break;
      case 'Əməkdaş dövriyyəsi':
        content = EmekdasDovriyyesiPage();
        break;
      case 'Cari hesablar':
        content = CariHesab(showAppBar: false);
        break;
      case 'Cari hesab dövriyyəsi':
        content = CariHesabDov();
        break;
      case 'Kassa dövriyyəsi':
        content = KassaDovriyyesi();
        break;
      case 'Xərc hesabatı':
        content = XercHesabati(showAppBar: false);
        break;
      case 'Gəlir hesabatı':
        content = GelirHesabat(showAppBar: false);
        break;
      default:
        content = const HomePage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Soffen Mobil", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(25), bottomLeft: Radius.circular(25)),
        ),
        elevation: 0.00,
        backgroundColor: const Color.fromARGB(255, 56, 103, 154),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 56, 103, 154),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/soffen-logo.png',
                    width: 90,
                    height: 90,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Username',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Ana Səhifə'),
              onTap: () {
                setState(() {
                  selectedPage = 'Ana Səhifə';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Əməkdaş dövriyyəsi'),
              onTap: () {
                setState(() {
                  selectedPage = 'Əməkdaş dövriyyəsi';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money_outlined),
              title: const Text('Cari hesablar'),
              onTap: () {
                setState(() {
                  selectedPage = 'Cari hesablar';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Cari hesab dövriyyəsi'),
              onTap: () {
                setState(() {
                  selectedPage = 'Cari hesab dövriyyəsi';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(
                MyFlutterApp.cash_register,
                size: 18,
              ),
              title: const Text('Kassa hesabatı'),
              onTap: () {
                setState(() {
                  selectedPage = 'Kassa hesabatı';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(Icons.currency_exchange),
              title: const Text('Kassa dövriyyəsi'),
              onTap: () {
                setState(() {
                  selectedPage = 'Kassa dövriyyəsi';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(
                MyFlutterApp.basket,
                size: 18,
              ),
              title: const Text('Xərc hesabatı'),
              onTap: () {
                setState(() {
                  selectedPage = 'Xərc hesabatı';
                });
                Navigator.of(context).pop();  
              },
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Gəlir hesabatı'),
              onTap: () {
                setState(() {
                  selectedPage = 'Gəlir hesabatı';
                });
                Navigator.of(context).pop();  
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(3),
        child: content,
      ),
    );
  }
}
