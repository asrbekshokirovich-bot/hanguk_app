import 'dart:io';
import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://lysjdtyanhdfphqyijsr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E');
  
  try {
    final msgs = await client.from('channel_messages').select('sender_id').limit(10);
    for (var m in msgs) {
       final sid = m['sender_id'];
       if (sid == null) continue;
       
       try {
         final p = await client.from('profiles').select('id').eq('id', sid).maybeSingle();
         if (p != null) print('Found $sid in profiles!');
       } catch(e) {}
       
       try {
         final s = await client.from('students').select('id').eq('id', sid).maybeSingle();
         if (s != null) print('Found $sid in students!');
       } catch(e) {}
    }
  } catch(e) {
    print('Failed: $e');
  }
  exit(0);
}
