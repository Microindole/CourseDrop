#!/usr/bin/env python3
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
HARMONY = ROOT / "apps" / "harmony"
ETS_ROOT = HARMONY / "entry" / "src" / "main" / "ets"
MAIN_PAGES = HARMONY / "entry" / "src" / "main" / "resources" / "base" / "profile" / "main_pages.json"

EXPECTED_SERVICE_DIRS = {
    "ai",
    "clipboard",
    "crypto",
    "device",
    "file",
    "group",
    "identity",
    "local",
    "relay",
    "scan",
    "settings",
    "share",
    "transfer",
}


def main() -> int:
    errors: list[str] = []
    data = json.loads(MAIN_PAGES.read_text(encoding="utf-8"))
    pages = data.get("src", [])
    if not isinstance(pages, list):
        errors.append("main_pages.json: src must be a list")
        pages = []

    for page in pages:
        page_path = ETS_ROOT / f"{page}.ets"
        if not page_path.exists():
            errors.append(f"main_pages.json references missing page: {page}")
            continue
        text = page_path.read_text(encoding="utf-8")
        if "@Entry" not in text:
            errors.append(f"{page_path.relative_to(ROOT).as_posix()}: routed page should include @Entry")

    service_root = ETS_ROOT / "services"
    for name in sorted(EXPECTED_SERVICE_DIRS):
        index_file = service_root / name / "index.ets"
        if not index_file.exists():
            errors.append(f"Missing service barrel: services/{name}/index.ets")

    group_test = ETS_ROOT / "pages" / "GroupTestPage.ets"
    home = ETS_ROOT / "pages" / "HomePage.ets"
    if group_test.exists() and home.exists() and "pages/GroupTestPage" in home.read_text(encoding="utf-8"):
        errors.append("GroupTestPage should remain outside the HomePage main flow")

    if errors:
        print("Harmony route and layer check failed:")
        for error in errors:
            print(f"  {error}")
        return 1
    print("Harmony route and layer check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
