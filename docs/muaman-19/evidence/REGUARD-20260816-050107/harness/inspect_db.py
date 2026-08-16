import sqlite3
import json
import sys
import datetime

db_path = sys.argv[1]

tables = [
    "app_settings", "expenses", "import_batches", "inventory_count",
    "invoices", "products", "returns", "role_permissions", "sales", "users",
]

con = sqlite3.connect(db_path)
cur = con.cursor()
integrity = cur.execute("PRAGMA integrity_check").fetchone()[0]

counts = {}
for t in tables:
    try:
        counts[t] = cur.execute(f'SELECT COUNT(*) FROM "{t}"').fetchone()[0]
    except sqlite3.Error as e:
        counts[t] = f"ERROR: {e}"

first_products = []
try:
    rows = cur.execute('SELECT * FROM "products" LIMIT 5').fetchall()
    cols = [d[0] for d in cur.description]
    name_i = cols.index("name") if "name" in cols else 1
    barcode_i = cols.index("barcode") if "barcode" in cols else 2
    first_products = [
        {"name": r[name_i] if r[name_i] else "", "barcode": r[barcode_i]}
        for r in rows
    ]
except sqlite3.Error as e:
    first_products = [{"error": str(e)}]

settings = []
try:
    rows = cur.execute('SELECT * FROM "app_settings" LIMIT 10').fetchall()
    cols = [d[0] for d in cur.description]
    if cols and cols[0] != "id":
        settings = [list(r) for r in rows]
    else:
        settings = [list(r[1:]) if len(r) > 1 else list(r) for r in rows]
except sqlite3.Error as e:
    settings = [{"error": str(e)}]

result = {
    "database": db_path,
    "inspectedAtUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "integrity_check": integrity,
    "row_counts": counts,
    "first_product_samples": first_products,
    "app_settings": settings,
}
payload = json.dumps(result, indent=2, ensure_ascii=False).encode("utf-8")
if len(sys.argv) > 2:
    with open(sys.argv[2], "wb") as fh:
        fh.write(payload)
    sys.stdout.write("written=" + sys.argv[2] + "\n")
else:
    sys.stdout.buffer.write(payload)
    sys.stdout.write("\n")
con.close()
