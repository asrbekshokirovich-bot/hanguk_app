import 'dart:io';
import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://lysjdtyanhdfphqyijsr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E');
  
  try {
    final res = await client.rpc('get_schema_info_for_channel_messages', params: {}); // just seeing if we can query channel_messages
    final msg = await client.from('channel_messages').select('*, students(*)').limit(1);
    print('Students: $msg');
  } catch(e) {
    print('Failed with students: $e');
  }
  
  try {
    final msg2 = await client.from('channel_messages').select('*, profiles(*)').limit(1);
    print('Profiles: $msg2');
  } catch(e) {
    print('Failed with profiles: $e');
  }
  
  try {
    final msg3 = await client.from('channel_messages').select('*, users(*)').limit(1);
    print('Users: $msg3');
  } catch(e) {
    print('Failed with users: $e');
  }
  exit(0);
}
