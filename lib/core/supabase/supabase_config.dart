import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://svwyipmdszjfgvqywyff.supabase.co';


  static const String anonKey = 'sb_publishable_MPT18QB0rLRcb0VV-61Xng_L6WMKW9P';


  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
