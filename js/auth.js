// js/auth.js
// Require: supabase.js dimuat sebelum file ini

const AUTH = {
  // Login Google
  async loginGoogle() {
    const { error } = await sb.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin + '/auth-callback.html' }
    });
    if (error) alert('Login gagal: ' + error.message);
  },

  // Logout
  async logout() {
    await sb.auth.signOut();
    window.location.href = '/login.html';
  },

  // Ambil session + profile
  async getUser() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) return null;
    const { data: profile } = await sb
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .single();
    return profile;
  },

  // Guard: redirect jika belum login
  async requireAuth(allowedRoles = []) {
    const user = await AUTH.getUser();
    if (!user) { window.location.href = '/login.html'; return null; }
    if (allowedRoles.length && !allowedRoles.includes(user.role)) {
      window.location.href = '/login.html'; return null;
    }
    return user;
  },

  // Redirect sesuai role setelah login
  redirectByRole(role) {
    const map = {
      admin:    '/admin/dashboard.html',
      reseller: '/reseller/dashboard.html',
      customer: '/customer/dashboard.html',
    };
    window.location.href = map[role] || '/login.html';
  }
};
