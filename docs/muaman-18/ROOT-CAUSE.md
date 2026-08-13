# MUAMAN-18 — Root Cause Statement (Windows shutdown printing-teardown UAF)

> **تحديث نهائي:** مُصلَح ومُثبَت — انظر `docs/muaman-18/FINAL-REPORT.md`
> (Outcome A). هذا الملف يوثّق جذر المشكلة في الـ baseline فقط
> (`printing_plugin.dll+0x491B`). توجد أيضًا محاولة وسيطة فاشلة
> (SW_HIDE+PostQuitMessage) حرّكت الـ UAF إلى `flutter_windows.dll+0x1D9F0`
> (0xC000041D) — مسار destructor — وقد عالجها الإصلاح النهائي بإلغاء حوار
> الطباعة أولًا (IDCANCEL) ثم استئناف الإغلاق عبر WM_DESTROY القياسي.

- المعرف: MUAMAN-18
- الفرع: `codex/muaman-18-graceful-windows-shutdown-wm-close-hardening`
- الـ baseline: `5af7bc31b795963a4f637e1dd7d05da7760a226e` (MUAMAN-17W)
- المصدر الأساسي للأدلة: `docs/muaman-18/evidence/REPRO3-DUMP-20260813/` + minidump `muaman_store.exe_260813_055821.dmp` (509MB، procdump full memory)

## 1. التصنيف (Classification)

**Root cause: PROVEN — Use-After-Free (UAF)**

الكراش هو استخدام-after-free: `MethodChannel::InvokeMethod` يستدعي vtable الخاص
بالـ messenger الذي تم تحريره أثناء إغلاق التطبيق، في حين أن تدفق الطباعة
(HandleMethodCall -> printPdf -> onLayout -> InvokeMethod) لا يزال معلقًا على
الـ main thread داخل حوار الطباعة (Print Setup dialog).

## 2. توقيع الكراش (Crash signature)

- `exitCode = -1073741819` (0xC0000005، access violation)
- `RIP = printing_plugin.dll + 0x491B` = التعليمات `call qword ptr [rax+8]`
- التعليمات السابقة مباشرة: `mov rcx, r14` (0x4918)
- `RAX = 0xFEEEFEEEFEEEFEEE` = fill heap المحرر (MSVC debug heap fill) — يُستخدم
  كـ vtable pointer
- `RCX = r14 = 0x13855DBD5A0` = عنوان الـ messenger المحرر
- `RDX = 0x13855DDB438` = `&channel->name` (الاسم `net.nfet.printing`)
- `RSP = 0x36B68FDA00`، `RBP = 0x36B68FDB00`
- الخيط الفاعل: `tid = 0x1574` = thread #0 (main/UI)
- الاستثناء المسجل: code=0xC0000005، ExceptionAddress=printing_plugin.dll+0x491B
- الـ timestamp: 2026-08-13T05:58:21 local (procdump capture)

## 3. السلسلة الكاملة للاستدعاء (Full call chain — مثبتة بالـ disasm + مطابقة عناوين العودة)

| العنوان | الوظيفة | الدليل |
|---|---|---|
| +0x491B (fault) | `MethodChannel<EncodableValue>::InvokeMethod` | call [rax+8] يفشل |
| +0x5EE1 | `nfet::Printing::onLayout` (عودة بعد call عند 0x5EDC) | RSP+0x198 |
| +0xC683 | `nfet::PrintJob::printPdf` (عودة بعد call عند 0xC67E) | RSP+0xA88 |
| +0x7D27 | `PrintingPlugin::HandleMethodCall` (عودة بعد call عند 0x7D22) | RSP+0xC68 |
| +0x128C6 / +0x908F / +0x77B5 / +0x9047 / +0xF0F1 | دوال داخلية للـ plugin | RSP+0xE48..+0x1108 |
| flutter_windows.dll (+0x44FE .. +0xD9E0D) | محرك Flutter / معالجة platform message | RSP+0x1188.. |
| user32.dll / gdi32.dll frames | machinery رسائل/الحوار | RSP+0x19A8.. |
| muaman_store.exe+0x2466 / +0x75C8 / +0x5DE9 | main / wWinMain | RSP+0x1C18.. |

حجم دالة InvokeMethod = 0x4CF (pdata 0x45B0..0x4A7F)، onLayout = 0x648
(0x59C0..0x6008)، printPdf = 0x525 (0xC1B0..0xC6D5)، HandleMethodCall = 0xE43
(0x7A80..0x88C3) — كلها مطابقة تمامًا لأحجام COMDAT في map_funcs5.py.

## 4. الآلية (Mechanism)

1. المستخدم/الـ harness يفتح حوار الطباعة (Print Setup، class #32770) من
   invoice preview — `PrintJob::printPdf` يدخل modal loop داخل user32
   (يتم ضخ رسائل الخيط، لذلك يظل التطبيق يبدو تفاعليًا؛ `S08 canceled: false`
   يؤكد أن الحوار لم يُغلق فعليًا).
2. الـ main thread يبقى معلقًا في ذلك الـ loop والـ messenger (خصية الـ
   PluginRegistrar) ما زال حيًا.
3. أثناء الإغلاق (`S12`): الـ harness يرسل `WM_CLOSE` ثم `PostQuitMessage`.
4. `WM_CLOSE` -> `DefWindowProc` -> `DestroyWindow` -> `WM_DESTROY` ->
   `Win32Window::MessageHandler` (case WM_DESTROY) -> `Destroy()` ->
   `FlutterWindow::OnDestroy` -> `flutter_controller_ = nullptr` ->
   `FlutterDesktopViewControllerDestroy` -> teardown engine ->
   `~PluginRegistrar` = `ClearPlugins()` ثم `messenger_.reset()` ->
   **يُحرَّر الـ messenger** (يمتلئ بـ 0xFEEEFEEEFEEEFEEE).
5. `PostQuitMessage(0)` بعد التدمير.
6. الـ modal loop يستقبل `WM_QUIT` -> يُغلق الحوار -> يعود التنفيذ إلى
   `printPdf` (الكود محرَّر) -> `onLayout` -> `MethodChannel::InvokeMethod`.
7. `InvokeMethod` يقرأ vtable الـ messenger من الذاكرة المحررة:
   `RAX = 0xFEEEFEEEFEEEFEEE` -> `call [rax+8]` -> access violation
   (استثناء 0xC0000005) -> خروج بالكود -1073741819.

الـ channel هو كائن global داخل الـ plugin (`net.nfet.printing`) وما زال سليمًا
تمامًا (الاسم size=17، الـ codec vtable=printing_plugin.dll+0x17080)؛ **العنصر
المحرَّر الوحيد هو `messenger_`** (تم التحقق: كتلة 4096 بايت متواصلة
من 0xFEEEFEEEFEEEFEEE عند 0x13855DBD5A0).

## 5. لماذا 0xFEEEFEEE deterministic؟

- `0xFEEEFEEEFEEEFEEE` هو fill الـ freed-heap في MSVC debug CRT.
- يشير إلى عملية إغلاق/تدمير أثناء بقاء الحوار معلقًا (لا إلى إلغاء عادي يعيد
  DefDlgProc بلاش)، والتوقيت ثابت: teardown ثم WM_QUIT ثم استئناف printPdf.

## 6. Teardown timeline (REPRO3-DUMP, 2026-08-13 UTC)

| T | التوقيت (UTC) | الحدث |
|---|---|---|
| T0 | 02:53:41 | بدء run REPRO3-DUMP |
| T1 | 02:53:49 | S01-launch PASS (pid 5688) |
| T2 | 02:54:12 | S02-setup-owner PASS |
| T3 | 02:54:24 | S03-login-owner PASS |
| T4 | 02:54:51 | S04-add-product PASS |
| T5 | 02:55:52 | S05-create-sale PASS |
| T6 | 02:56:16 | S06-save-pdf PASS (spooler RPC exception 0x6BA غير قاتلة عند 02:55:55) |
| T7 | 02:56:21 | S07-open-pdf PASS |
| T8 | 02:56:22 | S08: click Print -> تظهر Print Setup dialog (modal loop يبدأ) |
| T9 | 02:56:57 | S08 PASS مع `canceled: false` (الحوار لم يُغلق) |
| T10 | 02:57:07 | S09-sales-history PASS (التطبيق يبقى تفاعليًا عبر loop الحوار) |
| T11 | 02:57:44 | S10-add-cashier PASS |
| T12 | 02:58:00 | S11-cashier-denied PASS |
| T13 | 02:58:01-18 | S12-logout-close: logout -> login screen |
| T14 | ~02:58:14 | harness يرسل WM_CLOSE -> WM_DESTROY -> teardown -> messenger يُحرَّر |
| T15 | 02:58:21 | استثناء 0xC0000005 عند +0x491B -> procdump يلتقط full dump |
| T16 | 02:58:29 | S12 PASS: exitCode=-1073741819، close seconds=6.6 |

## 7. S08 anomaly (`canceled: false`)

التصنيف: **جانبية (incidental)** — السبب المباشر لـ UAF ليس فشل الإلغاء.

- `canceled: false` = محاولة الـ harness إلغاء الحوار فشلت (OCR click لم يُغلق
  الحوار)؛ هذا يفسر بقاء الحوار مفتوحًا طوال T8..T15 وهو شرط الـ UAF (التعليق).
- `appBackOnPreview: true` = الـ harness رأى الـ preview خلف الحوار
  (check غير حاسم).
- لا يوجد دليل أن قيم `canceled` تؤثر على تسلسل التحرير؛ التحرير يحدث في
  teardown بغض النظر عن نتيجة الإلغاء.

## 8. لماذا ليس شيئًا آخر

- ليس try/catch أو exception swallowing: لم نرَ أي محاولة catch في مسار التحرير.
- ليس race بين خيطين: كل الـ teardown والـ print flow على نفس الـ main thread
  (tid 0x1574)؛ الـ 28 خيطًا الآخرون مركونون في waits.
- ليس إصدار plugin أو Flutter قديمًا: الآلية تعتمد على ordering في
  `~PluginRegistrar` (ClearPlugins ثم messenger_.reset()) وترتيب
  WM_DESTROY -> PostQuitMessage في القالب القياسي.
- `0xC0000005` ليس "قبولًا" — هو فشل إغلاق حقيقي.

## 9. Residual unknowns

- السبب الدقيق لـ `canceled: false` (لماذا فشل إلغاء الـ harness) — INFERRED:
  قيد OCR/تنسيق حوار، غير مؤثر على الـ UAF.
- ما إذا كان الحوار modal بحظر المالك أم لا — غير حاسم من الـ dump، لكن
  التفاعل اللاحق للـ harness يشير إلى أن owner لم يُعطَّل (أو أن loop الحوار
  ضخ الرسائل) — INFERRED وغير مؤثر.
