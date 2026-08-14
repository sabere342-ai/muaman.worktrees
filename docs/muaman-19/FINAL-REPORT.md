# MUAMAN-19 — تشغيل بيانات العرض بأمان / بدء نظيف (Safe Demo-Data Commissioning / Clean-Start Flow)

- التذكرة: MUAMAN-19
- الفرع: `codex/muaman-19-safe-demo-data-commissioning-clean-start`
- baseline (نقطة الإنتاج قبل التعديلات): `23cb92e64bbc7b1761457335626641aace8b0951` (MUAMAN-18)
- البيئة/التنفيذ: ISLAM / saber — Windows 11 Pro
- مرجع الجودة: `docs/muaman-19/EVIDENCE-SUMMARY.md` + `docs/muaman-19/evidence/`

## Outcome

**Outcome A — إصلاح كامل مع تحقق كامل (Complete fix, fully verified).**

الإنتاج يبدأ فارغًا افتراضيًا (لا بيانات تجريبية إطلاقًا)، ويتم زرع بيانات العرض فقط عبر
تعريف بناء صريح `--dart-define=MUAMAN_SEED_DEMO=true`، وكل عمليات المسح محمية
(owner-only + عبارة تأكيد + نسخة احتياطية موثقة قبل أي حذف + حذف في معاملة واحدة).
تم التحقق عبر: 501 اختبارًا ناجحًا، تحليل ساكن نظيف، تنسيق نظيف، بناء Windows Release
رسمي ناجح، قبول تشغيلي لبيئة DB نظيفة (فارغة افتراضيًا / مزروعة بالتعريف)، وضوابط
سلبية على المسح (رفض غير-owner، عبارة خاطئة، فشل النسخة، تراجع المعاملة).

---

## 1. Baseline (نقطة الإنتاج) — سلوك قبل التعديل

| الحقل | القيمة |
|---|---|
| النقطة | `23cb92e64bbc7b1761457335626641aace8b0951` (MUAMAN-18) |
| السلوك | `DataImporter.importData(db)` يُستدعى دائمًا داخل `_createDB` → كل إنشاء DB جديد في أي بناء (بما فيه الإنتاج) يُزرع بيانات تجريبية تلقائيًا |
| العيب | لا يمكن الحصول على إنتاج فارغ؛ بيانات العرض تُحقن في جميع البنيات (release/debug) |

## 2. التغيير: بوابة زرع بيانات العرض (seed gating)

- `app/lib/database/database_helper.dart`:
  - `static bool seedDemoEnabled = const bool.fromEnvironment('MUAMAN_SEED_DEMO')`
    — افتراضيًا `false` → الإنتاج يبدأ فارغًا؛ يُفعّل فقط عبر
    `--dart-define=MUAMAN_SEED_DEMO=true` (dev/demo builds).
  - `if (seedDemoEnabled) { await DataImporter.importData(db); }` داخل `_createDB`.
  - أُزيل استيراد `dart:io` غير المستخدم ووُضع `flutter/foundation.dart` فقط
    (`@visibleForTesting`).
  - seam اختباري `runCreateDbForTest(db)` لتشغيل `_createDB` الحقيقي على DB في
    الذاكرة (تحقق بوابة الزرع دون لمس ملف DB حقيقي).
- دليل القطع (tree-shaking): `binary-probe.json` — `app.so` الإنتاج لا يحتوي على
  barcode `2000000000001` (0 hit) بينما `app.so` المزروع يحتوي عليه (1 hit)،
  أي أن القيمة الثابتة طُبقت فعليًا في بناء AOT.

## 3. التغيير: خدمة المسح النظيف (Clean-Start) — fail-closed

`app/lib/services/clean_start_service.dart` (جديد):

| الشرط | السلوك |
|---|---|
| غير مالك (non-owner) | `PermissionDeniedException` — لا حذف |
| عبارة التأكيد `مسح البيانات` غير مطابقة (بعد trim) | `CleanStartConfirmationException` — إجهاض قبل أي حذف/نسخة |
| اختيار مجلد نسخة غير صالح / تعذّر إنشاء النسخة | `CleanStartBackupFailedException` — إجهاض قبل أي حذف |
| النسخة الاحتياطية | `VACUUM INTO` في المسار المختار + تحقق من الوجود/عدم الفراغ |
| تحقق النسخة | فتح سريع عبر اتصال جديد مستقل (`openDatabase(readOnly: true)`) + `PRAGMA integrity_check` = `ok` + تعداد الجداول > 0 |
| الحذف | معاملة واحدة (`db.transaction`) على الجداول: `inventory_count, sales, returns, expenses, invoices, import_batches, products` — كل شيء أو لا شيء |
| المحفوظ | `users`, `role_permissions`, `app_settings` (موسّع: بيانات المستخدمين/الأدوار/الإعدادات لا تُمسح) |
| المخرجات | `CleanStartReport` (timestamp, backupPath, deletedCounts لكل جدول) |

## 4. التغيير: واجهة الإعدادات (owner-only commissioning)

`app/lib/screens/settings_screen.dart`: قسم «تشغيل نظيف» يظهر فقط لمالك المتجر
(`currentRole == UserRole.owner`):
- اختيار مجلد النسخة الاحتياطية (FilePicker).
- حقل عبارة تأكيد إلزامي.
- حوار نتيجة بعد التنفيذ يعرض عدد الصفوف المحذوفة لكل جدول (بأسماء عربية).
- يُعالج أخطاء الأذونات/التأكيد/النسخة/العامة برسائل snackbar عربية.

## 5. الاختبارات (جديدة)

- `app/test/database/seed_gating_test.dart` (بوابة الزرع):
  - الإنتاج افتراضيًا: `seedDemoEnabled == false`.
  - مع تعطيل الزرع: `_createDB` يترك الجداول فارغة.
  - مع تفعيل الزرع: `_createDB` يزرع (products > 10 + أول barcode `2000000000001`).
  - العودة إلى تعطيل الزرع على DB جديدة: فارغة.
- `app/test/database/clean_start_service_test.dart` (المسح):
  - مالك + عبارة صحيحة → حذف الجداول التشغيلية، حفظ `users/role_permissions/app_settings`، تقرير بعدّادات + مسار النسخة، النسخة صالحة (SQLite) تحتوي المنتجات قبل المسح.
  - غير-مالك → رفض بدون حذف وبدون نسخة.
  - عبارة خاطئة / فارغة → إجهاض قبل النسخة والحذف.
  - فشل النسخة (ملف محجوب) → إجهاض بلا حذف.
  - فشل في منتصف المسح (trigger يرمي `ABORT`) → تراجع كامل (all-or-nothing).
- `app/integration_test/login_invoice_smoke_test.dart`: أصبح مستقلًا عن بيانات العرض
  (يُنشئ مستخدم owner + منتج بنفسه، barcode `9000000000001`) حتى لا يعتمد الاختبار
  على التعريف.

## 6. الأدلة (تحت `docs/muaman-19/evidence/`)

- `test-results.txt`: `All tests passed!` (501) — exit 0.
- `analyze.txt`: `No issues found!` — exit 0.
- `format.txt`: `Formatted 6 files (0 changed)` — exit 0.
- `release-build/build-result.json`: `PASS` (exit 0) — البناء الرسمي
  `tools/release/build_windows_release.ps1` بدون أي `--dart-define`، والـ release tree
  هو القطعة الإنتاجية الفارغة افتراضيًا (manifest: 16 ملفًا، 35,753,553 بايت).
- `dev-seed-build/build.log`: نجاح `flutter build windows --release --dart-define=MUAMAN_SEED_DEMO=true`.
- `runtime-acceptance/prod/db-inspection.json`: DB جديدة بعد تشغيل exe الإنتاج في
  مجلد معزول → كل الجداول التشغيلية = 0 (`integrity_check: ok`).
- `runtime-acceptance/seed/db-inspection.json`: DB جديدة بعد تشغيل exe المزروع →
  products=86, sales=225, returns=8, expenses=32 وأول منتج barcode `2000000000001`.
- `binary-probe.json`: قطع/إبقاء `DataImporter` في بناء الإنتاج/المزروع.
- `runtime-acceptance/run_isolated_app.ps1`: نص القبول التشغيلي (ينسخ Release إلى
  مجلد معزول، يزيل `.dart_tool` المنسوخة لضمان إنشاء DB جديد عبر `onCreate`).

## 7. التحقق النهائي للفرع

- commmit واحد ذري على baseline `23cb92e64bbc7b1761457335626641aace8b0951`.
- `git status` نظيف بعد الالتزام، `git diff --check` نظيف، لم يُنفَّذ push/tag/merge.
- لم يُعد فتح MUAMAN-18، ولم تتغير أذونات MUAMAN-14/15 أو العلامة MUAMAN-16 أو
  الفوترة/الطباعة MUAMAN-17/17W.
