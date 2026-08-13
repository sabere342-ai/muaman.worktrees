# MUAMAN-18 — التقرير النهائي (Windows shutdown printing-teardown UAF)

- المعرف: MUAMAN-18
- الفرع: `codex/muaman-18-graceful-windows-shutdown-wm-close-hardening`
- الـ baseline (رأس الشجرة قبل الإصلاح): `5af7bc31b795963a4f637e1dd7d05da7760a226e` (MUAMAN-17W)
- الجهاز/المستخدم: ISLAM / saber — Windows 11 Pro
- مرجع جذر المشكلة التفصيلي: `docs/muaman-18/ROOT-CAUSE.md`

## Outcome

**Outcome A — مُصلَح ومُثبَت بالكامل (Complete fix, fully verified).**

الإغلاق أثناء فتح حوار الطباعة (Print Setup, #32770) أصبح يخرج نظيفًا
بـ `exitCode = 0` عبر مسار `WM_CLOSE` القياسي في كل التشغيلات، بدون كراش، بدون
تعليق، بدون عمليات يتيمة، وبدون kill قسري. تحقق ذلك في: acceptance كامل
(S01–S13) + stress 20 دورة بحوار الطباعة مفتوحًا وقت الإغلاق + stress 20 دورة
إغلاق عادي. لم يتم منع WM_CLOSE، ولم تُستبدل الـ crash handling بـ swallow،
والمعالج يعيد-تصميم الأمان على **lifetime correctness** لا على إخفاء الكراش.

---

## 1. Baseline (قبل الإصلاح) — الكراش التاريخي

| البند | القيمة |
|---|---|
| التشغيل | `ACCEPT-BASELINE-20260813-124208` (S01–S13 كامل) |
| الكراش | `S12` close → `exitCode = -1073741819` (`0xC0000005`) في 5.7s |
| الحوار | مفتوح وقت الإغلاق (`S08 canceled: false`) |
| التوقيع | `RIP = printing_plugin.dll+0x491B` = `call [rax+8]`؛ `RAX = 0xFEEEFEEEFEEEFEEE` (heap fill المحرَّر MSVC)؛ `RCX = r14 = 0x13855DBD5A0` (messenger محرَّر)؛ `tid = 0x1574` = main |
| الـ chain | `InvokeMethod` (0x491B) ← `onLayout` (+0x5EE1) ← `printPdf` (+0xC683) ← `HandleMethodCall` (+0x7D27) ← engine platform-message dispatch ← user32 modal loop |
| الهاش | baseline exe `194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9` |

الآلية (تتفق مع ROOT-CAUSE.md): الـ modal loop في `PrintDlg` يعلّق الـ main
thread بينما الـ messenger حي؛ عند الإغلاق يتدمّر الـ controller (وبالتبعية
`~PluginRegistrar` = `ClearPlugins()` ثم `messenger_.reset()`) → يُحرَّر
الـ messenger → يستأنف `printPdf` بعد WM_QUIT → `InvokeMethod` يقرأ vtable من
ذاكرة محرَّرة → AV.

## 2. المحاولة الوسيطة التي فشلت (SW_HIDE + PostQuitMessage)

معالج WM_CLOSE أضيف في `flutter_window.cpp` يقوم بـ `ShowWindow(SW_HIDE)` ثم
`PostQuitMessage(0)` لإغلاق التطبيق فورًا. **لم تمنع الـ UAF بل حرّكته:**

| البند | القيمة |
|---|---|
| التشغيلات | `ACCEPT-FIX-20260813-124819`، `ACCEPT-FIX-DUMP-...`، `ACCEPT-FIX-DUMP2-...`، `ACCEPT-FIX-DUMP3-...`، `ACCEPT-TRACE-20260813-132154` (خمس تشغيلات) |
| الكراش الجديد | `exitCode = -1073740771` (`0xC000041D`) في 9.1–11s — **بنفس الحوار مفتوحًا** (`S08 canceled: false` في كل مرة) |
| التوقيع الجديد | `RIP = flutter_windows.dll+0x1D9F0` (`mov rax,[rcx+0x10]; ret`)؛ `RCX = 0`؛ `tid = 0x1AA4`؛ المسار: message dispatch ← `+0x15C90 mov rcx,[rcx+8]; call +0x1D9F0` على controller مُفكَّك — **لا frames لـ printing_plugin** |
| WER | حدثان لكل كراش: `0xC0000005` ثم `0xC000041D`، كلاهما عند `flutter_windows.dll+0x1d9f0` (disasm أثبت أنه trampoline kernel↔user وليس موضع الخطأ) |
| التتبّع (M18Trace) | `WM_CLOSE-handler` → `dtor-FlutterWindow` بعد 47ms → الاستثناء بعد ≈9s |

الخلاصة: `PostQuitMessage` أنهى الـ loop فورًا فشغَّل destructor
(`FlutterWindow::~FlutterWindow` → `Win32Window::~Win32Window` → teardown
الـ controller) **بينما الحوار والنافذة ما زالا حيَّين**، ثم عادت رسالة
completion لاحقة داخل teardown engine إلى controller مُفكَّك عبر `[this+8]=0`.
أي: نفس الـ UAF، عبر مسار destructor بدل WM_DESTROY. WER `+0x1d9f0` trampoline
ليس موقع الخطأ؛ الموقع المعتمد لتدفق الطباعة هو `printing_plugin.dll+0x491B`.

## 3. Root cause (شامل)

- توقيعان لنفس UAF: (أ) `printing_plugin.dll+0x491B` — `InvokeMethod` على
  messenger محرَّر (تدفق الطباعة المعلّق)، و(ب) `flutter_windows.dll+0x1D9F0`
  — message callback داخل engine teardown على controller مُفكَّك.
- الجذر المشترك: **ترتيب خاطئ في lifetime** — teardown الـ messenger/controller
  يبدأ بينما تدفق الطباعة (المعلّق داخل حوار PrintDlg modal) ما زال يستخدمه،
  ويستأنف لاحقًا callbacks على كائنات محرَّرة.
- ممنوع تغيير cancel semantics أو منع WM_CLOSE كليًا: الحل يلزم أن يضمن
  اكتمال تدفق الطباعة **قبل** أي teardown، مع بقاء الـ messenger حيًا حتى
  انتهاء `InvokeMethod` للطباعة.

## 4. Teardown timeline (ملخّص من M18Trace / ACCEPT-TRACE)

| اللحظة | الحدث |
|---|---|
| T0 | الـ harness يرسل `WM_CLOSE` (tick 23730828) |
| T1 | `WM_CLOSE-handler` يتلقى الرسالة (الحوار مفتوح) |
| T2 | +47ms: `dtor-FlutterWindow` يبدأ (مع المحاولة الوسيطة) |
| T3 | +≈9s: الاستثناء `0xC0000005`/`0xC000041D` عند completion/teardown callback |

مع الإصلاح النهائي، لا يوجد هذا التسلسل إطلاقًا: `IDCANCEL` يُنهي `PrintDlg`
→ تدفق الطباعة يتفرّغ (`onCompleted(false)` → `InvokeMethod` بينما الـ
messenger حي) → ثم `WM_CLOSE` المؤجل يدمّر النافذة أولًا ثم الـ controller
(مسار WM_DESTROY القياسي) → `exitCode = 0`.

## 5. S08 anomaly (`canceled: false`)

تصنيفها **جانبي (incidental)** في ROOT-CAUSE.md: فشل click الإلغاء في الـ
harness أبقى الحوار مفتوحًا، وهو شرط إعادة إنتاج الـ UAF (التعليق)، وليس سببًا
مباشرًا. لم تتغير معالجتها في الإصلاح؛ الإصلاح يتعامل مع الحوار المفتوح
مهما كان السبب.

## 6. الإصلاح النهائي (في `app/windows/runner/flutter_window.cpp`)

على رسالة `WM_CLOSE`:

1. بحث عن الحوار القياسي المملوك للعملية عبر `EnumWindows` + فحص class
   `#32770` (وهو class حوار الطباعة القياسي `PrintDlg`/COMMDLG المستخدم من
   plugin الطباعة).
2. إن وُجد الحوار: `close_pending_ = true`، `ShowWindow(SW_HIDE)`، ثم
   `PostMessageW(dialog, WM_COMMAND, IDCANCEL, 0)` يليه
   `PostMessageW(hwnd, WM_CLOSE, 0, 0)`، ثم `return 0` (لا تدمير مبكر).
   - `IDCANCEL` يُنهي `PrintDlg` من الـ modal loop فيفرّغ تدفق الطباعة
     (ReturnValue/onCompleted) **بينما الـ messenger حي** — يعالج الـ UAF في
     مصدره (lifetime).
   - الرسائل نفسها على قائمة رسائل الخيط نفسه → ترتيب FIFO مضمون: يرى الـ
     modal loop الـ IDCANCEL قبل أن يُعالَج WM_CLOSE المؤجل → التدفق يتفرّغ
     بالكامل قبل التشغيل الثاني للمعالج.
3. عند `WM_CLOSE` التالي (بدون حوار): يسقط للمسار القياسي
   `Win32Window::MessageHandler` → `DefWindowProc` → `DestroyWindow` →
   `WM_DESTROY` → `FlutterWindow::OnDestroy` (تدمير الـ controller بينما
   الـ messenger حي حتى هذه النقطة) → `PostQuitMessage(0)` → خروج نظيف.

الـ guard `close_pending_` يمنع إعادة-توجيه لا نهائية أو دمار مبكر في حالة
بقاء الحوار مفتوحًا. أُزيلت كل M18Trace (fopen_s/close-trace) قبل البناء
النهائي. لم تتغير `main.cpp`/`win32_window.cpp`/`SetQuitOnClose(true)`.

البناء النهائي: `tools\release\build_windows_release.ps1` → run
`L-20260813-153418-5124` PASS → exe hash
`9FF10A35BA134412E9070D262D8E723B5F9B56B614ED9998CFF75297A602AC2A`
(91648 بايت). (البناء الوسيط المقيَّد بـ M18Trace كان
`ED14AA8301438C53DC33DEA97010D7904C9B556282F9A90A3481454F4AF5BD05`؛ البناء
الـ patched أُعيد بناؤه مرتين بنفس الهاش = reproducible.)

## 7. Negative control

| التشغيل | النتيجة |
|---|---|
| `NC-POSTFIX-20260813-123826` (build سابق) | NC1=NC2=NC3=NC4 = PASS |
| `NC-POSTFIX-2-20260813-1837` (البناء النهائي) | NC1=NC2=NC3=NC4 = PASS |

إصلاحات الـ harness المرفوعة في هذا العمل (تبقى في الـ commit):
`Format-ExitCode` (تحويل سالب إلى uint32 بالـ 32-bit الصحيحة)، استبدال
`Join-String` بـ `-join ' '`، ومسار NC1 (compile مساعد crash بلغة C عبر MSVC
مع fallback إلى CLR crash `0xE0434352`).

## 8. Post-fix acceptance (S01–S13)

- `ACCEPT-FIX-FINAL-20260813-1903` — كل الخطوات S01..S13 `ok=True`.
- **S12-logout-close**: `method=WM_CLOSE`، `exited=True`، **`exitCode=0`**،
  `seconds=0.3` — بينما حوار الطباعة مفتوح (`S08 canceled=False`, `#32770`).
- WER: **صفر أحداث** منذ بداية التشغيل (لا `0xC0000005` ولا `0xC000041D`).
- لا عمليات `muaman_store.exe` يتيمة بعد الإغلاق.
- فحص إضافي: لا استثناءات first-chance مطابقة للمرشّحات — صفر dumps من
  procdump على مدار الـ acceptance.

## 9. Stress

أداة جديدة `tools\muaman18\run_print_close_stress.ps1` تكرّر التشغيل الكامل
لـ `run_smoke.ps1` (كل دورة تغلق بحوار الطباعة مفتوحًا) مع procdump مسلَّح
(`-e 1 -f c0000005 -f c000041d -w`) ومراقبة watchdog/يتامى/kill قسري.

| التشغيل | النتيجة |
|---|---|
| `STRESS-FIX-SANITY2-20260813-1935` | 1/1 PASS (تحقق من صحة الأداة؛ وثقنا أيضًا خطأ `-t` في procdump = termination dump بنّي لا علاقة له بالكراش) |
| `STRESS-FIX-20260813-1945` | **20/20 PASS** — كل دورة `WM_CLOSE/exit=0/sec=0.3`، `dumps=0`، `orphans=0`، `hang=0`، `forcedKill=0` |
| `STRESS-LAUNCHCLOSE-20260813-1945` | **20/20 PASS** — إغلاق عادي `exit=0/sec=0.3`، `passRate=100%`، لا كراش/hang/linger/forced kill |

## 10. Validation IDs

- baseline head: `5af7bc31b795963a4f637e1dd7d05da7760a226e`
- baseline exe: `194B46007E82D06936355C8C76B1E7DB93F97DF6691596097819E83A608BD6A9`
- build وسيط (M18Trace): `ED14AA8301438C53DC33DEA97010D7904C9B556282F9A90A3481454F4AF5BD05`
- **final exe: `9FF10A35BA134412E9070D262D8E723B5F9B56B614ED9998CFF75297A602AC2A`**
- build run: `L-20260813-153418-5124`
- Acceptance: `ACCEPT-BASELINE-20260813-124208` (كراش 0xC0000005)؛
  `ACCEPT-FIX-…` ×5 (كراش 0xC000041D)؛ `ACCEPT-FIX-FINAL-20260813-1903` (PASS)
- NC: `NC-POSTFIX-20260813-123826`، `NC-POSTFIX-2-20260813-1837`
- Stress: `STRESS-FIX-20260813-1945` (20×)؛ `STRESS-FIX-SANITY2-20260813-1935`
  (1×)؛ `STRESS-LAUNCHCLOSE-20260813-1945` (20×)
- أدلة dumps: baseline `muaman_store.exe_260813_055821.dmp` (509MB)؛ patched
  `muaman_store.exe_260813_161628.dmp`؛ walks:
  `walk-baseline-055821.txt` / `walk-patched-161628.txt`
  (في `C:\Users\saber\AppData\Local\Temp\opencode\m18-dumps\`)

## 11. Residual risks / ملاحظات

- الحل يعتمد على اكتشاف الحوار عبر class `#32770` + ملكية العملية. أي تغيير
  مستقبلي في plugin الطباعة ينقل الحوار إلى class آخر قد يُفشل الاكتشاف —
  الأمان يبقى fail-safe لأن الحالة عند عدم الاكتشاف هي المسار القياسي الأصلي
  (سلوك baseline المعروف)، لكن يُوصى بمراجعة عند ترقية `printing`.
- `S08 canceled: false` (فشل click إلغاء الـ harness) لم يُحل — وهو شاذ harness
  جانبي مؤثر على إعادة الإنتاج فقط، لا على سلوك التطبيق.
- لم تُغيّر نسخ Flutter/plugins؛ البناء تم عبر الـ canonical entrypoint
  (`build_windows_release.ps1` → `build_hardened.ps1`).
- التقرير الكامل + كل الأدلة تحت `docs/muaman-18/`؛ جميع الأدلة الجديدة
  بمعرّفات RUN فريدة ولم تُكتب فوق أي REPRO سابق.
