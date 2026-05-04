import 'dart:io';
import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://lysjdtyanhdfphqyijsr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E');
  
  try {
    final res = await client.from('app_versions').select().eq('id', 'android').single();
    print('Row: $res');
  } catch(e) {
    print('Failed: $e');
  }
  exit(0);
}
