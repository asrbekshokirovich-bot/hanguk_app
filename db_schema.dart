import 'dart:io';
import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://lysjdtyanhdfphqyijsr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E');
  
  try {
    final msg = await client.from('channel_messages').select('*, students(*)').limit(1);
    print('Students works');
  } catch(e) {
    print('Students: $e');
  }
  
  try {
    final msg = await client.from('channel_messages').select('*, profiles(*)').limit(1);
    print('Profiles works');
  } catch(e) {
    print('Profiles: $e');
  }
  
  try {
    final msg = await client.from('channel_messages').select('*, users(*)').limit(1);
    print('Users works');
  } catch(e) {
    print('Users: $e');
  }
  exit(0);
}
