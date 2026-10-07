import json, sys
proj = {p["name"]: p for p in json.load(open(sys.argv[1]))["packages"]}
ml = json.load(open(sys.argv[2]))["packages"]
ok = True
for p in ml:
    q = proj.get(p["name"])
    same = q is not None and q["rev"] == p["rev"] and q["url"].rstrip("/").removesuffix(".git") == p["url"].rstrip("/").removesuffix(".git")
    ok &= same
    print("%-18s mathlib-pins %s  project-has %s  %s" % (p["name"], p["rev"][:12], (q or {}).get("rev", "MISSING")[:12], "OK" if same else "DIFFERENT"))
print("ALL MATCH" if ok else "MISMATCH")
