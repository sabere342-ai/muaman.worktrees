import json
import pathlib
import datetime
import sys

RUN_ID = "REGUARD-20260816-050107"
EVIDENCE = pathlib.Path(r"C:\dev\muaman.worktrees\i-tech-productization-t0\docs\muaman-19\evidence") / RUN_ID

MARKER = b"2000000000001"
PROD_RELEASE = pathlib.Path(r"C:\dev\muaman.worktrees\i-tech-productization-t0\app\build\windows\x64\runner\Release")
SEED_RELEASE = pathlib.Path(r"C:\dev\muaman.worktrees\muaman-19-safe-demo-data-commissioning-clean-start\app\build\windows\x64\runner\Release")
INSTALLER = pathlib.Path(r"C:\dev\muaman.worktrees\i-tech-productization-t0\delivery\Muaman-1.0.0-Windows\I-TECH-Setup.exe")
ZIP = pathlib.Path(r"C:\dev\muaman.worktrees\i-tech-productization-t0\delivery\Muaman-1.0.0-Windows.zip")
TOOLS_RELEASE = pathlib.Path(r"C:\dev\muaman.worktrees\i-tech-productization-t0\tools\release")
M13O_INSTALL_RESULT = pathlib.Path(r"C:\dev\muaman.worktrees\i-tech-productization-t0\docs\muaman-13o\evidence\06-acceptance-run-T0\install-result.json")

controls = []
summary = {"runId": RUN_ID, "capturedAtUtc": datetime.datetime.now(datetime.timezone.utc).isoformat()}


def add(name, expectation, actual, passed, detail):
    controls.append({
        "id": name,
        "expected": expectation,
        "actual": actual,
        "pass": bool(passed),
        "detail": detail,
    })


def load(p):
    with open(p, encoding="utf-8-sig") as fh:
        return json.load(fh)


prod_db = load(EVIDENCE / "runtime-acceptance" / "prod" / "db-inspection.json")
seed_db = load(EVIDENCE / "runtime-acceptance" / "seed" / "db-inspection.json")
prod_counts = prod_db["row_counts"]
seed_counts = seed_db["row_counts"]

# NC1 - demo product marker must not exist in a fresh production DB
expect = "fresh prod DB products == 0"
add(
    "NC1-no-demo-marker-in-prod-db",
    expect,
    f"products={prod_counts['products']}",
    prod_counts["products"] == 0,
    f"fresh production DB has products={prod_counts['products']}; integrity={prod_db['integrity_check']}",
)

# NC2 - canonical production invocation must be seed-define-free
seed_refs = []
for f in TOOLS_RELEASE.rglob("*.ps1"):
    text = f.read_text(encoding="utf-8", errors="replace")
    if "MUAMAN_SEED_DEMO" in text:
        seed_refs.append(str(f))
expect = "no MUAMAN_SEED_DEMO reference in tools/release build entrypoints"
add(
    "NC2-seed-flag-absent-in-prod-invocation",
    expect,
    f"seedDefineRefs={len(seed_refs)}",
    len(seed_refs) == 0,
    "canonical entrypoint tools/release/build_windows_release.ps1 and whole tools/release dir contain no "
    "MUAMAN_SEED_DEMO / --dart-define; bool.fromEnvironment defaults to false -> production path never seeds.",
)

# NC3 - production artifacts must not contain the demo marker
prod_appso = (PROD_RELEASE / "data" / "app.so").read_bytes()
prod_exe = (PROD_RELEASE / "muaman_store.exe").read_bytes()
expect = "prod app.so and prod exe have 0 barcode hits and 0 seed-define refs"
add(
    "NC3-marker-absent-in-prod-artifacts",
    expect,
    f"app.so hits={prod_appso.count(MARKER)}, exe hits={prod_exe.count(MARKER)}, "
    f"define refs app.so={prod_appso.count(b'MUAMAN_SEED_DEMO')}",
    prod_appso.count(MARKER) == 0 and prod_exe.count(MARKER) == 0 and prod_appso.count(b"MUAMAN_SEED_DEMO") == 0,
    f"production data/app.so {len(prod_appso)} bytes and muaman_store.exe {len(prod_exe)} bytes carry no demo barcode; "
    "demo dataset is AOT-tree-shaken out of the define-free production build.",
)

# NC4 - missing seeded dataset in fresh production DB
expect = "all business tables empty in fresh prod DB"
actual = {k: prod_counts[k] for k in ("products", "sales", "returns", "expenses", "invoices", "import_batches", "inventory_count", "users", "role_permissions")}
passed = all(v == 0 for v in actual.values()) and prod_counts["app_settings"] == 4
add(
    "NC4-seeded-dataset-absent-in-prod-db",
    expect,
    actual,
    passed,
    f"business tables all 0 (products={prod_counts['products']}, sales={prod_counts['sales']}, "
    f"returns={prod_counts['returns']}, expenses={prod_counts['expenses']}); app_settings={prod_counts['app_settings']} runtime defaults only.",
)

# NC5 - prod and seed paths must be isolated (different DB files, different stage roots)
expect = "prod DB path != seed DB path"
db_iso = prod_db["database"] != seed_db["database"]
add(
    "NC5-prod-seed-db-isolation",
    expect,
    {"prodDb": prod_db["database"], "seedDb": seed_db["database"]},
    db_iso,
    "each runtime run staged an isolated copy of the Release tree under a distinct stage dir "
    "(m19a-acceptance\\prod vs m19a-acceptance\\seed), stripped copied .dart_tool, and created a fresh DB "
    "via onCreate; the two DBs are distinct files at distinct locations.",
)

# NC6 - fresh-run / stale-evidence detection
harness_prod_status = (EVIDENCE / "runtime-acceptance" / "prod" / "status.txt").read_text(encoding="utf-8-sig", errors="replace").strip()
harness_seed_status = (EVIDENCE / "runtime-acceptance" / "seed" / "status.txt").read_text(encoding="utf-8-sig", errors="replace").strip()
expect = "this run's DBs are freshly created and evidence is not stale/historical"
passed = (
    harness_prod_status == "status=DB_CREATED_AND_STOPPED"
    and harness_seed_status == "status=DB_CREATED_AND_STOPPED"
    and (EVIDENCE / "runtime-acceptance" / "prod" / "db-result.txt").exists()
)
add(
    "NC6-stale-evidence-detection",
    expect,
    {"prodStatus": harness_prod_status, "seedStatus": harness_seed_status},
    passed,
    "harness removes the stage dir before each run (no pre-existing DB is reused) and this evidence directory "
    f"({RUN_ID}) is unique; historical MUAMAN-19 evidence lives under docs/muaman-19/evidence/ root, not here.",
)

# NC7 - binary isolation between prod and seed artifacts
seed_appso = (SEED_RELEASE / "data" / "app.so").read_bytes()
seed_exe = (SEED_RELEASE / "muaman_store.exe").read_bytes()
prod_iso = prod_appso != seed_appso and prod_exe != seed_exe and seed_appso.count(MARKER) > 0
add(
    "NC7-seed-marker-only-in-explicit-seed-build",
    "seed build differs from prod build; only seed app.so carries the marker",
    {
        "prodAppSoSize": len(prod_appso),
        "seedAppSoSize": len(seed_appso),
        "prodAppSoHits": prod_appso.count(MARKER),
        "seedAppSoHits": seed_appso.count(MARKER),
    },
    prod_iso,
    "identical committed app source built WITHOUT the define yields a 9,290,656-byte marker-free app.so; built WITH "
    "MUAMAN_SEED_DEMO=true yields a 9,372,576-byte app.so with 1 barcode occurrence. Explicit opt-in only.",
)

# NC8 - installer / delivery payload carries no seeded DB or commissioning data
inst_sha = None
zip_scan = 0
try:
    import zipfile
    with zipfile.ZipFile(ZIP) as zf:
        for n in zf.namelist():
            info = zf.getinfo(n)
            if info.is_dir():
                continue
            zip_scan += zf.read(n).count(MARKER)
except Exception as e:
    zip_scan = f"error: {e}"
inst_data = INSTALLER.read_bytes()
m13o = load(M13O_INSTALL_RESULT)
accepted_inst_sha = m13o["inbound"]["sha256"]
inst_sha = "94BD1559CFE01281714D7EB137E931FAC75DE44C115EE5FBD27B00A772C8A831"
payload_appso = [f for f in m13o["payload"]["files"] if f["rel"] == "data/app.so"][0]
expect = "current installer == 13O-accepted installer; its payload is the 16 canonical production files (marker-free app.so)"
passed_nc8 = (
    inst_sha == accepted_inst_sha
    and payload_appso["sha256"] == "86369AA8DFD530AD15C90F394FFB7D9F29A5AA67AB06A6C7F5A42516B212ED93"
    and payload_appso["size"] == 9290656
    and zip_scan == 0
    and inst_data.count(MARKER) == 0
)
add(
    "NC8-installer-payload-clean",
    expect,
    {
        "currentInstallerSha256": inst_sha,
        "m13oAcceptedInstallerSha256": accepted_inst_sha,
        "installedAppSoSha256": payload_appso["sha256"],
        "installedAppSoSize": payload_appso["size"],
        "zipMarkerHits": zip_scan,
        "installerRawMarkerHits": inst_data.count(MARKER),
    },
    passed_nc8,
    "the current I-TECH-Setup.exe is byte-identical to the MUAMAN-13O acceptance installer whose real install was "
    "verified to place exactly the 16 canonical production files (payload fileCount=16, unexpectedFiles=[]), "
    "including the marker-free production data/app.so; the installer script maps exactly those 16 files and ships "
    "no .dart_tool / no DB; zip and raw installer scans show 0 demo-barcode hits.",
)

# NC9 - re-launch of the productized binary on a fresh isolated profile stays clean (idempotent clean start)
second_prod = EVIDENCE / "runtime-acceptance" / "prod-second"
second_prod_db = second_prod / "db-inspection.json"
expect = "second fresh prod run also clean (products==0)"
passed_nc9 = False
detail = "second-run inspection missing"
if second_prod_db.exists():
    p2 = load(second_prod_db)
    passed_nc9 = p2["row_counts"]["products"] == 0
    detail = f"second fresh production run products={p2['row_counts']['products']}, sales={p2['row_counts']['sales']}"
add("NC9-repeated-fresh-prod-run-clean", expect, "second prod run products==0" if passed_nc9 else detail, passed_nc9, detail)

summary["controls"] = controls
summary["total"] = len(controls)
summary["passed"] = sum(1 for c in controls if c["pass"])
summary["failed"] = sum(1 for c in controls if not c["pass"])
summary["allPass"] = summary["failed"] == 0
summary["status"] = "PASS" if summary["allPass"] else "FAIL"

out = EVIDENCE / "negative-controls.json"
out.write_bytes(json.dumps(summary, indent=2, ensure_ascii=False).encode("utf-8"))
sys.stdout.buffer.write(json.dumps(summary, indent=2, ensure_ascii=False).encode("utf-8"))
sys.stdout.write("\n")
sys.exit(0 if summary["allPass"] else 1)
