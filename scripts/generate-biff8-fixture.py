from __future__ import annotations

import sys
from pathlib import Path

import xlwt


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: generate-biff8-fixture.py OUTPUT.xls")

    output = Path(sys.argv[1])
    output.parent.mkdir(parents=True, exist_ok=True)
    workbook = xlwt.Workbook(encoding="utf-8")
    sheet = workbook.add_sheet("Legacy checks")
    sheet.write(0, 0, "marker")
    sheet.write(0, 1, "amount")
    sheet.write(1, 0, "PLUXEL_GUEST_OK_7319")
    sheet.write(1, 1, 7319)
    workbook.save(str(output))

    signature = output.read_bytes()[:8]
    if signature != bytes.fromhex("d0cf11e0a1b11ae1"):
        raise RuntimeError("xlwt did not generate an OLE Compound File BIFF workbook")


if __name__ == "__main__":
    main()
