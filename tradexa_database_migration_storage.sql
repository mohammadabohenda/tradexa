-- ============================================================
-- TREDEXA — Migration: Storage bucket لشعارات الشركات
-- ============================================================

-- Bucket عام للقراءة (الشعارات تُعرض بالتطبيق للجميع) لكن الكتابة
-- مقصورة على Platform Admin فقط عبر السياسات أدناه.
INSERT INTO storage.buckets (id, name, public)
VALUES ('company-logos', 'company-logos', true)
ON CONFLICT (id) DO NOTHING;

-- القراءة: عامة (أي حد يقدر يشوف الشعار — طبيعي لصورة معروضة بالتطبيق)
CREATE POLICY "public_read_company_logos"
ON storage.objects FOR SELECT
USING (bucket_id = 'company-logos');

-- الرفع/التعديل/الحذف: Platform Admin فقط
CREATE POLICY "admin_upload_company_logos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'company-logos'
  AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'platform_admin')
);

CREATE POLICY "admin_update_company_logos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'company-logos'
  AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'platform_admin')
);

CREATE POLICY "admin_delete_company_logos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'company-logos'
  AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'platform_admin')
);
