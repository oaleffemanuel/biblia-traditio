import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Typefaces are bundled in assets/fonts/; never reach fonts.gstatic.com.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: BibliaTraditioApp()));
}
