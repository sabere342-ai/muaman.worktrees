# MUAMAN-07 — Product Identity Input Normalization & Whitespace Safety

## Branch

`codex/muaman-07-product-identity-input-normalization`

## Starting HEAD

`c6b9a704c92494c85f8a32e2e8c26f6e192eff55` — `MUAMAN-06: prevent deletion of referenced products`

## Final commit

`24267247c9b397ed41dd88e7c6137a8b4585bb60` — `MUAMAN-07: normalize product identity inputs`

## المشكلة المثبتة قبل التنفيذ

قبل التعديل، تم فحص تدفقات إضافة وتعديل المنتج في كلا المستويين:

### السلوك السابق للاسم
- الاسم يُحفظ كما هو دون `trim()` — المسافات البادئة واللاحقة تُحفظ في قاعدة البيانات.
- `"  سكر  "` يُحفظ حرفيًا بما فيه المسافات.
- الاسم المكوّن من مسافات فقط `"   "` يمر عبر التحقق `nameController.text.isEmpty` لأنه ليس فارغًا (`isEmpty` يعيد `false` لسلسلة تحتوي مسافات).

### السلوك السابق للباركود
- الباركود يُحفظ كما هو دون `trim()`.
- إضافة منتج بباركود `" 12345 "` يمر عبر UNIQUE constraint رغم وجود `"12345"` لأن SQLite يعتبرهما قيمتين مختلفتين.
- لا يوجد فحص تكرار صريح في طبقة البيانات — الاعتماد فقط على UNIQUE constraint.

### نقاط الضعف
1. يمكن حفظ اسم `"   "` (مسافات فقط) كاسم منتج.
2. يمكن حفظ باركود `" 12345 "` حتى مع وجود `"12345"` مسبقًا.
3. لا توجد رسالة خطأ مناسبة للمستخدم عند حدوث مثل هذه الحالات.

## السلوك النهائي

### سياسة تطبيع الاسم
- يُطبّع الاسم بـ `trim()` قبل أي validation أو كتابة.
- يُرفض الاسم إذا أصبح فارغًا بعد `trim()` برسالة: `يجب إدخال اسم المنتج`.
- المسافات الداخلية المشروعة (مثل `"سكر أبيض"`) لا تتغير.

### سياسة تطبيع الباركود
- يُطبّع الباركود بـ `trim()` قبل فحص التكرار وقبل الكتابة.
- يُرفض الباركود إذا أصبح فارغًا بعد `trim()` برسالة: `الباركود مطلوب`.
- لا تغيير في حالة الأحرف (case)، لا حذف أصفار بداية، لا تحويل إلى رقم.

### سياسة الباركود الفارغ
- الباركود `NOT NULL` في schema. يبقى مطلوبًا.
- يُرفض الباركود الفارغ أو المكوّن من مسافات فقط بعد `trim()`.

### منع duplicate barcode بالمسافات
- يستخدم استعلام `SELECT id FROM products WHERE trim(barcode) = ?` لاكتشاف التكرار.
- يمنع إضافة `" 12345 "` عند وجود `"12345"`.
- يمنع تحديث باركود منتج إلى باركود مطابق بعد الـtrim لمنتج آخر.
- يسمح بالتحديث إذا كان الباركود نفسه (whitespace variation) — باستثناء `id != ?`.

## مواضع حماية الواجهة

`lib/screens/inventory/inventory_screen.dart:235-246`:
- تطبيع الاسم بـ `trim()` قبل التحقق.
- رسالة SnackBar `يجب إدخال اسم المنتج` للاسم الفارغ بعد الـtrim.
- رسالة SnackBar للـ `ArgumentError` من طبقة البيانات (مثل تكرار الباركود).
- عدم استدعاء الحفظ عند فشل التحقق.

## مواضع حماية طبقة البيانات

`lib/database/database_helper.dart`:
- **`insertProduct`** (السطور 110-147): تطبيع الاسم والباركود، التحقق من الاسم الفارغ، فحص تكرار الباركود بالـtrim، حفظ القيم المطبّعة.
- **`updateProduct`** (السطور 163-200): نفس التحقق مع استبعاد المنتج نفسه (`id != ?`) في فحص التكرار.

## الملفات المعدلة والجديدة

| الملف | الحالة |
|-------|--------|
| `lib/database/database_helper.dart` | تعديل — تطبيع في `insertProduct` و `updateProduct` |
| `lib/screens/inventory/inventory_screen.dart` | تعديل — تطبيع في `_showAddEditDialog` ومعالجة `ArgumentError` |
| `test/database/product_normalization_test.dart` | إضافة (جديد) — 14 اختبارًا |
| `docs/MUAMAN-07-PRODUCT-IDENTITY-INPUT-NORMALIZATION.md` | إضافة (جديد) — تقرير المرحلة |

## الاختبارات الجديدة (14 اختبارًا)

في `test/database/product_normalization_test.dart`:

1. Name with leading/trailing spaces is trimmed on insert
2. Whitespace-only name is rejected on insert
3. Empty name is rejected on insert
4. Name with leading/trailing spaces is trimmed on update
5. Whitespace-only name is rejected on update
6. Barcode with leading/trailing spaces is trimmed on insert
7. Insert with barcode that matches existing after trim is rejected
8. Update with barcode that matches another product after trim is rejected
9. Update with same barcode (whitespace variation) allowed for self
10. Product count unchanged after rejected insert
11. Product unchanged after rejected update
12. Inserted name and barcode are stored trimmed
13. Updated name and barcode are stored trimmed
14. Empty barcode after trim is rejected

## نتائج الاختبارات المركزة

```
product_normalization_test: 14/14 ✅
All 14 tests passed.
```

## نتائج اختبارات الانحدار

```
product_validation_test (MUAMAN-05):          6/6 ✅
sale_transaction_test (MUAMAN-02):           11/11 ✅
inventory_count_transaction_test (MUAMAN-03): 10/10 ✅
barcode_and_deletion_test (MUAMAN-04):         6/6 ✅
product_deletion_referential_test (MUAMAN-06): 14/14 ✅
Total regression:                             47/47 ✅
```

## نتائج full suite

```
61 passed, 1 failed
الفاشل: widget_test.dart (فشل قبلي غير مرتبط — "databaseFactory not initialized")
```

## Analyzer

```
No issues found! (ran in 9.1s)
```

## Formatter

```
Formatted 3 files (2 changed) — سليم.
```

## git diff --check

لا توجد مشكلات (فقط CRLF warnings عادية على Windows).

## Windows build

لم يُشغّل — العائق البيئي القبلي (MSBuild/المسار العربي) ما زال قائمًا.

## Schema/migration/cascade

| السؤال | الإجابة |
|--------|---------|
| هل تغير schema؟ | لا |
| هل نُفذت migration؟ | لا |
| هل تم cascade delete؟ | لا |
| هل تم Push أو Tag؟ | لا |

## Working tree status

```
 M app/lib/database/database_helper.dart
 M app/lib/screens/inventory/inventory_screen.dart
 D شهر7/.~lock.*.xlsx#  ← inherited out-of-scope (lock file)
?? app/test/database/product_normalization_test.dart
```

الشجرة نظيفة بعد الالتزام (ما عدا inherited lock file خارج النطاق).

## Outcome

**Outcome A — FULL SUCCESS**
