const SUPABASE_URL  = 'https://dwrxehnyjfzighzysosw.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3cnhlaG55amZ6aWdoenlzb3N3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2MzYwMjUsImV4cCI6MjA5NjIxMjAyNX0.lPPsnhRpyDcFhUvrbxJEMc7DAjlM-BMyICOVi9KPqWc';

const { createClient } = supabase;
const sb = createClient(SUPABASE_URL, SUPABASE_ANON, {
  auth: {
    detectSessionInUrl: true,
    flowType: 'pkce'
  }
});
