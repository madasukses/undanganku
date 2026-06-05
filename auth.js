const AUTH = {
  async loginGoogle() {
    const { error } = await sb.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin + '/auth-callback.html' }
    });
    if (error) alert('Login gagal: ' + error.message);
  },

  async logout() {
    await sb.auth.signOut();
    window.location.href = '/login.html';
  },

  async getUser() {
    const { data: { session } } = await sb.auth.getSession();
    if (!session) return null;

    const { data: profile, error } = await sb
      .from('profiles')
      .select('*')
      .eq('id', session.user.id)
      .single();

    if (error || !profile) {
      // Profile belum ada, buat dulu
      const { data: newProfile } = await sb
        .from('profiles')
        .upsert({
          id: session.user.id,
          email: session.user.email,
          nama: session.user.user_metadata?.full_name || '',
          avatar_url: session.user.user_metadata?.avatar_url || '',
          role: 'customer'
        }, { onConflict: 'id' })
        .select()
        .single();
      return newProfile;
    }

    return profile;
  },

  async requireAuth(allowedRoles = []) {
    const user = await AUTH.getUser();
    if (!user) {
      window.location.href = '/login.html';
      return null;
    }
    if (allowedRoles.length && !allowedRoles.includes(user.role)) {
      window.location.href = '/login.html';
      return null;
    }
    return user;
  },

  redirectByRole(role) {
    const map = {
      admin:    '/admin/dashboard.html',
      reseller: '/reseller/dashboard.html',
      customer: '/customer/dashboard.html',
    };
    window.location.href = map[role] || '/customer/dashboard.html';
  }
};
