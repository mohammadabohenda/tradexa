// تحويل رمز الباركود إلى جلسة دخول.
// نشر: supabase functions deploy barcode-login --no-verify-jwt
//
// --no-verify-jwt ضرورية: المستخدم لسا ما سجّل دخول وقت المسح.

import { serve } from 'https://deno.land/std@0.203.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  // رسالة خطأ واحدة موحّدة لكل حالات الفشل — عشان ما نساعد
  // حدا يخمّن رموز صحيحة عن طريق اختلاف الرسائل.
  const REJECT = { error: 'رمز غير صالح' };

  try {
    const { token } = await req.json();

    if (!token || typeof token !== 'string' || !token.startsWith('TDX-')) {
      return json(REJECT, 401);
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: profile } = await admin
      .from('profiles')
      .select('id, is_active, role')
      .eq('access_token', token)
      .maybeSingle();

    if (!profile || !profile.is_active) return json(REJECT, 401);

    const { data: authUser } = await admin.auth.admin.getUserById(profile.id);
    if (!authUser.user?.email) return json(REJECT, 401);

    const { data: link, error: linkError } = await admin.auth.admin.generateLink({
      type: 'magiclink',
      email: authUser.user.email,
    });

    if (linkError || !link) return json(REJECT, 401);

    console.log(`[BARCODE LOGIN] user=${profile.id} at ${new Date().toISOString()}`);

    return json({ link: link.properties.action_link, role: profile.role }, 200);
  } catch (_) {
    return json({ error: 'خطأ غير متوقع' }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}
