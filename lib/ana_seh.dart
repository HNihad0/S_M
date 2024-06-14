import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:soffen_mobile/cari_hes.dart';
import 'package:soffen_mobile/gelir_hes.dart';
import 'package:soffen_mobile/kas_hes.dart';
import 'package:soffen_mobile/model/dashboard_card.dart';
import 'package:soffen_mobile/my_flutter_app_icons.dart';
import 'package:soffen_mobile/xerc_hes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void navigateToKasHes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MSSQLTableDataFetch(showAppBar: true)),
    );
  }
  void navigateToCariHes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CariHesab(showAppBar: true)),
    );
  }
  void navigateToXercHes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => XercHesabati(showAppBar: true)),
    );
  }
  void navigateToGelirHes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GelirHesabat(showAppBar: true)),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Ana Səhifə',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: StaggeredGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                children: [
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,
                    child: DashboardCard(
                      icon: MyFlutterApp.cash_register,
                      title: 'Kassa hesabatı',
                      onTap: () => navigateToKasHes(context),
                    ),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 3,
                    child: DashboardCard(
                      icon: Icons.monetization_on,
                      title: 'Cari hesab',
                      onTap: () => navigateToCariHes(context),
                    ),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 3,
                    child: DashboardCard(
                      icon: MyFlutterApp.basket,
                      title: 'Xərc hesabatı',
                      onTap: () => navigateToXercHes(context),
                    ),
                  ),
                  StaggeredGridTile.count(
                    crossAxisCellCount: 2,
                    mainAxisCellCount: 2,
                    child: DashboardCard(
                      icon: Icons.money,
                      title: 'Gəlir hesabatı',
                      onTap: () => navigateToGelirHes(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
