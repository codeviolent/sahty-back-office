import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/sahhti_back_office_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ymmdyaqjuallibixpeil.supabase.co',
    anonKey: 'sb_publishable_MMhux97CTu6TO5VQbVkdeg_CDAr6Xzw',
  );
  //await OfflineCacheService.init();
  runApp(const SahhtiBackOfficeApp());
}
