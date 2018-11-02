import 'package:flutter/material.dart' hide Flow;

import 'src/widgets/app.dart';
import 'src/blocs.dart';

void main() async {
  await init();
  runApp(MyApp());
}
