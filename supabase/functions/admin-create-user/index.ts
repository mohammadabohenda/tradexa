// إنشاء حساب مستخدم جديد مع رمز دخول سرّي.
// نشر: supabase functions deploy admin-create-user

import { serve } from 'https://deno.land/std@0.203.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'غير مصرّح' }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // التحقق أن الطالب مدير منصة
    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user: caller } } = await callerClient.auth.getUser();
    if (!caller) return json({ error: 'غير مصرّح' }, 401);

    const { data: callerProfile } = await admin
      .from('profiles').select('role').eq('id', caller.id).maybeSingle();
    if (callerProfile?.role !== 'platform_admin') {
      return json({ error: 'هذا الإجراء متاح لمدير المنصة فقط' }, 403);
    }

    const { username, full_name, phone, password, role } = await req.json();

    if (!username || !full_name || !password) {
      return json({ error: 'اسم المستخدم والاسم الكامل وكلمة السر مطلوبة' }, 400);
    }
    if (!/^[a-zA-Z0-9_]{3,20}$/.test(username)) {
      return json({ error: 'اسم المستخدم: حروف وأرقام و_ فقط، 3-20 خانة' }, 400);
    }
    if (password.length < 6) {
      return json({ error: 'كلمة السر: 6 خانات على الأقل' }, 400);
    }

    const email = `${username}@tradexa.internal`;

    const { data: created, error: createError } =
      await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

    if (createError || !created.user) {
      const duplicate = createError?.message?.includes('already');
      return json(
        { error: duplicate ? 'اسم المستخدم مستخدم بالفعل' : 'تعذّر إنشاء الحساب' },
        400,
      );
    }

    // توليد الرمز السرّي عبر دالة قاعدة البيانات
    const { data: token } = await admin.rpc('generate_access_token');

    const { error: profileError } = await admin.from('profiles').insert({
      id: created.user.id,
      username,
      full_name,
      phone: phone ?? null,
      role: role ?? 'buyer',
      access_token: token,
      token_issued_at: new Date().toISOString(),
      is_active: true,
    });

    if (profileError) {
      // تراجع: نحذف حساب المصادقة عشان ما يضل يتيم
      await admin.auth.admin.deleteUser(created.user.id);
      return json({ error: 'تعذّر حفظ بيانات المستخدم' }, 400);
    }

    return json({ user_id: created.user.id, access_token: token }, 200);
  } catch (_) {
    return json({ error: 'خطأ غير متوقع بالسيرفر' }, 500);
  }
});

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}
