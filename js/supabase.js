// js/supabase.js
// Ganti dengan URL dan anon key dari Supabase Dashboard > Settings > API

const SUPABASE_URL  = 'https://XXXXXXXXXXXXXXXX.supabase.co';
const SUPABASE_ANON = 'eyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON);
