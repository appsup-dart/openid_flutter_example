import 'package:flutter/material.dart';
import 'issuer_list.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (s) {},
      home: IssuerListWidget(),
    );
  }
}
