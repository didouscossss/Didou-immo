import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/rendement/rendement_home.dart';
import 'state/rendement_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DidouImmoApp());
}

class DidouImmoApp extends StatelessWidget {
  const DidouImmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RendementState(),
      child: MaterialApp(
        title: 'Rendement',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const RendementHome(),
      ),
    );
  }
}
