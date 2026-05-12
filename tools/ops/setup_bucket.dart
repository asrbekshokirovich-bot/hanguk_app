import 'dart:io';
import 'package:supabase/supabase.dart';
void main() async {
  final client = SupabaseClient('https://lysjdtyanhdfphqyijsr.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E');
  
  try {
    print('Creating releases bucket...');
    await client.storage.createBucket('releases', const BucketOptions(public: true));
    print('Bucket created successfully!');
  } catch(e) {
    if (e.toString().contains('already exists')) {
      print('Bucket already exists, making it public...');
      await client.storage.updateBucket('releases', const BucketOptions(public: true));
    } else {
      print('Error: $e');
    }
  }
}
