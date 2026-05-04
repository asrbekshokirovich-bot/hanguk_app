import 'package:supabase/supabase.dart';

Future<void> main() async {
  const supabaseUrl = 'https://lysjdtyanhdfphqyijsr.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E';
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  try {
    final unis = await client.from('universities').select('id, name_en, is_partner').limit(5);
    print('Universities: $unis');

    final partnerUnis = await client.from('universities').select('id, name_en, is_partner').eq('is_partner', true).limit(5);
    print('Partner Universities: $partnerUnis');
    
  } catch (e) {
    print('ERROR: $e');
  }
}
