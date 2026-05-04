const SUPABASE_URL = 'https://lysjdtyanhdfphqyijsr.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5c2pkdHlhbmhkZnBocXlpanNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjg1NTEwNiwiZXhwIjoyMDg4NDMxMTA2fQ.68R5Yiz8wOyWvtDy5bt263C-d6pSykMkDC2YAt0Og_E';

async function test() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/applications?select=*,university:universities(id,name_en)`, {
    headers: {
      'apikey': ANON_KEY,
      'Authorization': `Bearer ${ANON_KEY}`
    }
  });
  const text = await res.text();
  console.log("STATUS:", res.status);
  console.log("RESPONSE:", text);
}

test();
