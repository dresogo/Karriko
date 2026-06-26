import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'data/services/appwrite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppwriteService.initialize();
  runApp(const ProviderScope(child: KarrikoApp()));
}
