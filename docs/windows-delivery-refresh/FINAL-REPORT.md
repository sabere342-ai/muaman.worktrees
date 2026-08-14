# تحديث حزمة التسليم الحوكمية (Governed Windows Delivery-Package Refresh)

- الوحدة: `windows-delivery-package-refresh` (بدون رقم تذكرة — قرار حوكمي من
  Roadmap Alignment Check: **B — CONTROLLED DEVIATION REQUIRED**)
- الفرع: `codex/windows-delivery-package-refresh`
- baseline: `697a9f974cf7433dac30fe4f09940076d923fa2f` (MUAMAN-19 — الإنتاج المقبول)
- البيئة/التنفيذ: ISLAM / saber — Windows 11 Pro
- مرجع الجودة: `docs/windows-delivery-refresh/EVIDENCE-SUMMARY.md` + `docs/windows-delivery-refresh/evidence/`

## Outcome

**التسليم الحوكمي أُعيد بناؤه من الإصدار الكانوني المقبول MUAMAN-19 (16 ملفًا،
35,753,553 بايت) واستُبدل بالكامل داخل `delivery/` مع تحديث العقود القانونية
والتشغيلية، واجتاز قبولًا تشغيليًا حقيقيًا: تثبيت → إطلاق → قاعدة بيانات نظيفة
فارغة → إغلاق سلس → إلغاء تثبيت يحفظ بيانات الأعمال.**

---

## 1. القرار الحوكمي (Roadmap Alignment Check)

- لا يوجد ملف roadmap صريح؛ المرجع الحاكم هو تسلسل FINAL-REPORTs في `docs/`
  (`13F`→`13S`, `16`, `17`, `17W`, `18`, `19`) والهدف التجاري (نسخة ويندوز قابلة
  للتسليم للإنتاج).
- الفجوة الحرجة: `delivery/Muaman-1.0.0-Windows/Muaman-Setup.exe` كان مثبت
  MUAMAN-13R المجمّد (SHA `05509FA7...`, 12,528,766 بايت) — سابق لكل ما أنُجز في
  MUAMAN-14…19، وكان المثبت القديم يزرع بيانات العرض تلقائيًا (يعارض نتيجة
  MUAMAN-19)، وكان `installer/muaman.iss` يسرد 13 ملفًا بينما الإصدار الكانوني
  المقبول 16 ملفًا (خطوط NotoSansArabic + `THIRD_PARTY_NOTICES.txt`).
- الخلاصة الحوكمية: المضي قدمًا يتطلب انحرافًا محكومًا محدودًا — تحديث حزمة
  التسليم من الإصدار الكانوني المقبول فقط (دون لمس كود/مخطط الإنتاج، دون إعادة
  بناء `app.so`، دون رقم تذكرة جديد).

## 2. التغييرات

### إعلان المثبت — `installer/muaman.iss`
- قائمة المصادر 13 → 16: أُضيفت
  `data/flutter_assets/assets/fonts/NotoSansArabic-Bold.ttf`,
  `NotoSansArabic-Regular.ttf`, `THIRD_PARTY_NOTICES.txt` قبل خط الأيقونات.
- التعليق التوضيحي أصبح «16-file release payload».

### المانيفست القانوني الجديد — `docs/windows-delivery-refresh/evidence/legal/release-manifest.json`
- runId `WR1`، 16 ملفًا، 35,753,553 بايت، per-file SHA-256، crosshash
  `7BC418546CABA55A3389C22A277B327D32683ABC91DA6CAF75FDA163E7204D6F` —
  نسخة من هوية MUAMAN-19 المقبولة. (أُنشئ بجلسة إعادة البناء نفسها؛ يعوّض
  هوية 13K/13N/13O المجمّدة القديمة).

### خط أنابيب الإصدار — `tools/release/`
- `verify_release.ps1`: التوقع أصبح 16 ملفًا / 35,753,553 بايت / crosshash
  `7BC41854...`؛ رأس الملف يشير إلى المانيفست الجديد.
- `package_windows_installer.ps1`: ثوابت العقد المحدثة — ZIP SHA
  `FEC8B79BA57FEB01EE12561AD21A32183073BFFFD8054E5AE1CCB62F83683355`
  (15,555,975 بايت، 16 إدخالًا)، crosshash `7BC41854...`؛ مسار المانيفست
  القانوني الافتراضي → الملف الجديد.
- `package_windows_release.ps1`: مسار المانيفست القانوني الافتراضي → الملف الجديد.

### حزم القبول — `tools/muaman13p/` و`tools/muaman13q/`
- `acceptance-config.json` في كليهما حُدّث من الهوية القديمة (مثبّت `05509FA7...`/
  12,528,766؛ exe `194B4600...`/90,624؛ payload 13/33,273,462/`EE892B35...`) إلى
  الهوية الجديدة (مثبّت `9A3AEFDD...`/13,225,828؛ exe `9FF10A35...`/91,648؛
  payload 16/35,753,553/`7BC41854...`). `flutter_windows.dll` وAppId ثابتان.

### حزمة التسليم — `delivery/Muaman-1.0.0-Windows/`
- `Muaman-Setup.exe` الجديد: 13,225,828 بايت، SHA
  `9A3AEFDD9188BD9A5D25D1D95324BE48C546DBB78BEC4B6998ECA4D4F1BAE0E1`.
- `SHA256SUMS.txt` حُدّث إلى التجزئة الجديدة؛ `README.txt` لم يتغير.
- `Muaman-1.0.0-Windows.zip`: 12,668,785 بايت، SHA
  `DD7D335B840676180487B10C5DEC2CEAD9008D5D99192242A886CA4FCBCBC789`
  + ملف `.sha256` مطابق؛ أُعيد توليده بشكل حتمي من الحزمة الجديدة (تحقق: فك
  الضغط يعيد إنتاج الشجرة بايتًا-ببايت).

## 3. الأدلة (تحت `docs/windows-delivery-refresh/evidence/`)

- `legal/release-manifest.json`: المانيفست القانوني الجديد (runId WR1).
- `acceptance/01-runtime-acceptance.json`: قبول تشغيلي حقيقي في الجلسة.
- `acceptance/launch-window.png`: لقطة نافذة الإطلاق (دليل بصري).
- القبول التشغيلي (هذا الجهاز، مستخدم حقيقي):
  1. إلغاء تثبيت مثبّت MUAMAN-13R القديم الموجود → exit 0.
  2. تثبيت صامت للمثبّت الجديد → exit 0؛ 16 ملفًا مثبتة (بما فيها خطا العربية
     و`THIRD_PARTY_NOTICES.txt`)؛ `muaman_store.exe` و`data/app.so` يطابقان
     الإصدار الكانوني (`9FF10A35...` / `9BC4C95E...`).
  3. إطلاق من دليل التثبيت (مكافئ لاختصار Start Menu، `WorkingDir={app}`):
     نافذة تظهر وتستجيب.
  4. قاعدة بيانات جديدة أُنشئت عند
     `{app}\.dart_tool\sqflite_common_ffi\databases\muaman_store.db`
     (81,920 بايت): 10 جداول، وكل الجداول التشغيلية = 0
     (products/sales/returns/expenses/invoices/import_batches/inventory_count/
     users/role_permissions)، `app_settings` = 4 قيم افتراضية فقط، منتجات
     العرض (barcode `200000000000*`) = 0 → **الإنتاج المُثبَّت يبدأ نظيفًا، بلا
     زرع بيانات**.
  5. إغلاق عبر `WM_CLOSE` → خروج سلس (مرتان) دون انهيار (مسار MUAMAN-18).
  6. إلغاء التثبيت → exit 0؛ اختفى مفتاح التسجيل واختصار Start Menu وملفات
     البرنامج؛ بقيت قاعدة بيانات الأعمال فقط (ضمانة حفظ البيانات).

## 4. التحقق النهائي للفرع

- commmit واحد ذري على baseline `697a9f974cf7433dac30fe4f09940076d923fa2f`.
- `git status` نظيف بعد الالتزام، `git diff --check` نظيف، لم يُنفَّذ push/tag/merge.
- لم يُعد بناء `app.so`، ولم يُغيّر كود/مخطط الإنتاج، ولم تفتح تذكرة جديدة.
- القيد المسجل: تشغيل واجهة الإعداد الكاملة (13P/13Q UI flow على مستخدم جديد)
  خارج نطاق هذه الجلسة؛ حزم القبول حُدّثت لهوية المثبّت الجديد لتشغيلها لاحقًا.
