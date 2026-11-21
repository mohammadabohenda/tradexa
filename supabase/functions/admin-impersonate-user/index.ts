// Supabase Edge Function: admin-impersonate-user
//
// تُستخدم من زر "تسجيل الدخول كمشرف" بشاشة الشركات. تولّد رابط دخول
// مؤقت (Magic Link) لحساب صاحب الشركة، بدون معرفة كلمة سره، لأغراض
// الدعم الفني فقط. حساسة جدًا — تتحقق من صلاحية Platform Admin أولًا،
// وتسجّل كل استخدام بسجل التشغيل (Console) كخطوة أولى نحو Audit Log
// كامل لاحقًا.
//
// نشر الدالة: supabase functions deploy admin-impersonate-user

import { serve } from 'https://deno.land/std@0.203.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'غير مصرّح، الرجاء تسجيل الدخول' }, 401);
    }

    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user: caller },
      error: callerError,
    } = await callerClient.auth.getUser();

    if (callerError || !caller) {
      return jsonResponse({ error: 'غير مصرّح، الرجاء تسجيل الدخول' }, 401);
    }

    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: callerProfile } = await adminClient
      .from('profiles')
      .select('role')
      .eq('id', caller.id)
      .maybeSingle();

    if (callerProfile?.role !== 'platform_admin') {
      return jsonResponse({ error: 'هذا الإجراء متاح فقط لمدير المنصة' }, 403);
    }

    const { user_id } = await req.json();
    if (!user_id) {
      return jsonResponse({ error: 'معرّف المستخدم مطلوب' }, 400);
    }

    const { data: targetUser, error: targetError } =
      await adminClient.auth.admin.getUserById(user_id);

    if (targetError || !targetUser.user?.email) {
      return jsonResponse({ error: 'المستخدم المطلوب غير موجود' }, 404);
    }

    const { data: linkData, error: linkError } =
      await adminClient.auth.admin.generateLink({
        type: 'magiclink',
        email: targetUser.user.email,
      });

    if (linkError || !linkData) {
      return jsonResponse({ error: 'تعذّر إنشاء رابط الدخول' }, 400);
    }

    // خطوة أولى نحو Audit Log كامل — كل استخدام لهذه الميزة الحساسة
    // يُسجَّل هلق بسجل التشغيل على الأقل، لحد ما نبني جدول Audit Logs.
    console.log(
      `[SUPPORT LOGIN] platform_admin=${caller.id} impersonated user=${user_id} at ${new Date().toISOString()}`,
    );

    return jsonResponse({ link: linkData.properties.action_link }, 200);
  } catch (_err) {
    return jsonResponse({ error: 'حدث خطأ غير متوقع بالسيرفر' }, 500);
  }
});

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}
