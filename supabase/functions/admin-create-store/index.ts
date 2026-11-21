// Supabase Edge Function: admin-create-store
//
// لماذا هذه الدالة ضرورية ولا يمكن الاستغناء عنها بمنطق داخل التطبيق:
// إنشاء مستخدم جديد في auth.users يتطلب صلاحية service_role،
// وهذه الصلاحية لا يجب أبدًا أن تصل لتطبيق Flutter (لو سُرّبت، أي شخص
// يقدر يتحكم بكامل قاعدة البيانات). لذلك العملية لازم تصير على السيرفر
// فقط، بعد التحقق الصارم أن الطالب فعلًا Platform Admin.
//
// نشر الدالة: supabase functions deploy admin-create-store

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
  // طلب CORS Preflight — المتصفح (خصوصًا Flutter Web) يرسله تلقائيًا
  // قبل أي POST فعلي. بدون هذا الرد، المتصفح يرفض الطلب الحقيقي
  // بالكامل قبل ما يوصل لأي منطق بالدالة — وهذا سبب شائع جدًا
  // لفشل صامت أو غامض عند استدعاء Edge Functions من تطبيق Flutter.
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }

  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    // عميل يستخدم توكن المستخدم المرسل مع الطلب — لمعرفة هويته والتحقق من دوره.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'غير مصرّح، الرجاء تسجيل الدخول' }, 401);
    }

    const callerClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await callerClient.auth.getUser();

    if (userError || !user) {
      return jsonResponse({ error: 'غير مصرّح، الرجاء تسجيل الدخول' }, 401);
    }

    // عميل بصلاحية service_role كاملة — يُستخدم فقط بعد التحقق من الدور.
    const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: callerProfile } = await adminClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

    if (callerProfile?.role !== 'platform_admin') {
      return jsonResponse({ error: 'هذا الإجراء متاح فقط لمدير المنصة' }, 403);
    }

    const body = await req.json();
    const {
      store_name,
      vertical_id,
      owner_username,
      owner_full_name,
      owner_phone,
      owner_password,
    } = body;

    if (!store_name || !vertical_id || !owner_username || !owner_full_name || !owner_password) {
      return jsonResponse({ error: 'الرجاء تعبئة جميع الحقول المطلوبة' }, 400);
    }

    // إيميل داخلي مولّد تلقائيًا — التاجر لا يراه ولا يحتاجه إطلاقًا،
    // فقط وسيلة تقنية لأن Supabase Auth يتطلب إيميل لكل حساب.
    const internalEmail = `${owner_username}@tradexa.internal`;

    // 1) إنشاء حساب Auth للتاجر
    const { data: authData, error: authError } =
      await adminClient.auth.admin.createUser({
        email: internalEmail,
        password: owner_password,
        email_confirm: true,
      });

    if (authError || !authData.user) {
      const message = authError?.message?.includes('already registered')
        ? 'اسم المستخدم مستخدم مسبقًا'
        : 'تعذّر إنشاء حساب التاجر';
      return jsonResponse({ error: message }, 400);
    }

    const newUserId = authData.user.id;

    // 2) إنشاء صف profiles — مع تنظيف تلقائي (rollback) لو فشل
    const { error: profileError } = await adminClient.from('profiles').insert({
      id: newUserId,
      vertical_id,
      role: 'merchant',
      username: owner_username,
      full_name: owner_full_name,
      phone: owner_phone,
    });

    if (profileError) {
      await adminClient.auth.admin.deleteUser(newUserId);
      const message = profileError.code === '23505'
        ? 'اسم المستخدم مستخدم مسبقًا'
        : 'تعذّر إنشاء بيانات التاجر';
      return jsonResponse({ error: message }, 400);
    }

    // 3) إنشاء المتجر نفسه — مع تنظيف تلقائي لو فشل
    const { data: storeData, error: storeError } = await adminClient
      .from('stores')
      .insert({ vertical_id, owner_id: newUserId, name: store_name })
      .select()
      .single();

    if (storeError) {
      await adminClient.from('profiles').delete().eq('id', newUserId);
      await adminClient.auth.admin.deleteUser(newUserId);
      return jsonResponse({ error: 'تعذّر إنشاء المتجر' }, 400);
    }

    return jsonResponse({ store: storeData }, 200);
  } catch (err) {
    return jsonResponse({ error: 'حدث خطأ غير متوقع بالسيرفر' }, 500);
  }
});

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}
