// إنشاء محل جديد مع حساب صاحبه بعملية واحدة.
//
// نشر: supabase functions deploy admin-create-shop --no-verify-jwt
// (التحقق من الهوية بيصير بالكود نفسه — --no-verify-jwt ضرورية
//  عشان طلب OPTIONS يعدّي بسلام ويشتغل CORS)

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

  // نتتبّع شو انخلق عشان نتراجع بالترتيب العكسي لو فشل شي
  let createdUserId: string | null = null;
  let createdProfile = false;

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'غير مصرّح' }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

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

    const body = await req.json();
    const {
      shop_name, slug, primary_color, currency_symbol, text_direction,
      whatsapp_number, max_qty_per_item, logo_url,
      owner_full_name, owner_username, owner_password, owner_phone,
    } = body;

    // ── التحقق ────────────────────────────────────────────────
    if (!shop_name?.trim()) return json({ error: 'اسم المحل مطلوب' }, 400);

    if (!/^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/.test(slug ?? '')) {
      return json({
        error: 'رابط المحل: حروف إنجليزية صغيرة وأرقام وشرطات، 3-40 خانة',
      }, 400);
    }

    if (!/^[a-zA-Z0-9_]{3,20}$/.test(owner_username ?? '')) {
      return json({
        error: 'اسم المستخدم: حروف وأرقام و_ فقط، 3-20 خانة',
      }, 400);
    }

    if (!owner_full_name?.trim()) {
      return json({ error: 'اسم صاحب المحل مطلوب' }, 400);
    }

    if (!owner_password || owner_password.length < 6) {
      return json({ error: 'كلمة السر: 6 خانات على الأقل' }, 400);
    }

    if (primary_color && !/^#[0-9A-Fa-f]{6}$/.test(primary_color)) {
      return json({ error: 'صيغة اللون: #RRGGBB' }, 400);
    }

    const wa = (whatsapp_number ?? '').replace(/[^0-9]/g, '');
    if (wa && (wa.length < 8 || wa.length > 15)) {
      return json({ error: 'رقم واتساب غير صحيح' }, 400);
    }

    // الرابط لازم يكون فريد — نفحصه قبل ما ننشئ الحساب عشان ما
    // نخلق مستخدمًا ثم نضطر نحذفه
    const { data: existing } = await admin
      .from('shops').select('id').eq('slug', slug).maybeSingle();

    if (existing) return json({ error: 'رابط المحل مستخدم بالفعل' }, 400);

    // ── 1) حساب المصادقة ──────────────────────────────────────
    const email = `${owner_username}@tradexa.internal`;

    const { data: created, error: createError } =
      await admin.auth.admin.createUser({
        email,
        password: owner_password,
        email_confirm: true,
      });

    if (createError || !created.user) {
      const dup = createError?.message?.includes('already');
      return json(
        { error: dup ? 'اسم المستخدم مستخدم بالفعل' : 'تعذّر إنشاء الحساب' },
        400,
      );
    }

    createdUserId = created.user.id;

    // ── 2) الملف الشخصي ───────────────────────────────────────
    const { data: token } = await admin.rpc('generate_access_token');

    const { error: profileError } = await admin.from('profiles').insert({
      id: createdUserId,
      username: owner_username,
      full_name: owner_full_name.trim(),
      phone: owner_phone?.trim() || null,
      role: 'buyer',
      access_token: token,
      token_issued_at: new Date().toISOString(),
      is_active: true,
    });

    if (profileError) {
      await rollback(admin, createdUserId, false);
      return json({ error: 'تعذّر حفظ بيانات صاحب المحل' }, 400);
    }

    createdProfile = true;

    // ── 3) المحل ──────────────────────────────────────────────
    const { data: shop, error: shopError } = await admin
      .from('shops')
      .insert({
        owner_id: createdUserId,
        slug,
        name: shop_name.trim(),
        logo_url: logo_url?.trim() || null,
        primary_color: primary_color || '#E8720C',
        currency_symbol: currency_symbol?.trim() || 'ل.س',
        text_direction: text_direction === 'ltr' ? 'ltr' : 'rtl',
        whatsapp_number: wa || null,
        max_qty_per_item: max_qty_per_item ?? 99,
      })
      .select('id, slug')
      .single();

    if (shopError || !shop) {
      await rollback(admin, createdUserId, createdProfile);
      return json({ error: 'تعذّر إنشاء المحل' }, 400);
    }

    return json({ shop_id: shop.id, slug: shop.slug, user_id: createdUserId }, 200);
  } catch (_) {
    return json({ error: 'خطأ غير متوقع بالسيرفر' }, 500);
  }
});

/// تراجع بالترتيب العكسي — الملف الشخصي ثم حساب المصادقة، عشان
/// ما يضل حساب يتيم لو فشل إنشاء المحل بالنص.
async function rollback(
  admin: ReturnType<typeof createClient>,
  userId: string | null,
  hadProfile: boolean,
) {
  if (!userId) return;
  if (hadProfile) {
    await admin.from('profiles').delete().eq('id', userId);
  }
  await admin.auth.admin.deleteUser(userId);
}

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}
