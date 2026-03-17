"""
Ruraflex Tariff Processor
=========================
Processes Elster meter CSV exports and summarises Import W (kW) per
tariff band (Red / Yellow / Green) per week.

Usage:
    python ruraflex_processor.py <input_csv> [output_csv]

If output_csv is omitted, the result is saved next to the input file
with "_tariff_summary" appended to the name.

Tariff schedule (South Africa – Ruraflex):
    Weekdays:
        Red    : 06:00–08:00  &  17:00–20:00
        Yellow : 08:00–16:00  &  20:00–22:00
        Green  : all other hours
    Saturday:
        Yellow : 07:00–12:00  &  17:00–19:00
        Green  : all other hours
    Sunday:
        Yellow : 17:00–19:00
        Green  : all other hours

Output columns:
    Week Starting | Red kWh | Yellow kWh | Green kWh | Total kWh
"""

import csv
import sys
import os
from datetime import datetime, timedelta, time


# ---------------------------------------------------------------------------
# Tariff schedule
# ---------------------------------------------------------------------------

def get_tariff(dt: datetime) -> str:
    """Return 'Red', 'Yellow', or 'Green' for a given datetime."""
    weekday = dt.weekday()   # 0=Mon … 5=Sat, 6=Sun
    t = dt.time()

    def between(t, start_h, start_m, end_h, end_m):
        return time(start_h, start_m) <= t < time(end_h, end_m)

    if weekday == 6:  # Sunday
        if between(t, 17, 0, 19, 0):
            return "Yellow"
        return "Green"

    if weekday == 5:  # Saturday
        if between(t, 7, 0, 12, 0) or between(t, 17, 0, 19, 0):
            return "Yellow"
        return "Green"

    # Monday – Friday
    if between(t, 6, 0, 8, 0) or between(t, 17, 0, 20, 0):
        return "Red"
    if between(t, 8, 0, 16, 0) or between(t, 20, 0, 22, 0):
        return "Yellow"
    return "Green"


# ---------------------------------------------------------------------------
# CSV parsing
# ---------------------------------------------------------------------------

def find_header_row(rows):
    """Return the index of the row containing 'Date', 'Start', 'Import W'."""
    for i, row in enumerate(rows):
        if "Date" in row and "Start" in row and "Import W" in row:
            return i
    raise ValueError("Could not find header row with 'Date', 'Start', 'Import W'.")


def parse_float(value: str) -> float:
    """Parse a number that may use a comma as decimal separator."""
    return float(value.strip().replace(",", "."))


def week_start(dt: datetime) -> str:
    """Return the Monday of the week containing dt, as YYYY-MM-DD."""
    monday = dt - timedelta(days=dt.weekday())
    return monday.strftime("%Y-%m-%d")


# ---------------------------------------------------------------------------
# Main processing
# ---------------------------------------------------------------------------

def process(input_path: str, output_path: str):
    with open(input_path, newline="", encoding="utf-8-sig") as f:
        raw = list(csv.reader(f))

    header_idx = find_header_row(raw)
    headers = raw[header_idx]

    # Locate column indices
    date_col     = headers.index("Date")
    start_col    = headers.index("Start")
    import_col   = headers.index("Import W")

    # Accumulate kWh per week per tariff
    # Structure: { week_start_str: { "Red": float, "Yellow": float, "Green": float } }

    # Accumulate total kWh per tariff for entire file
    totals = {"Red": 0.0, "Yellow": 0.0, "Green": 0.0}

    skipped = 0
    processed = 0

    for row in raw[header_idx + 2:]:   # +2 to skip header + units row
        # Skip short / empty rows
        if len(row) <= max(date_col, start_col, import_col):
            continue

        date_str  = row[date_col].strip()
        start_str = row[start_col].strip()
        import_str = row[import_col].strip()

        if not date_str or not start_str or not import_str:
            continue

        try:
            dt = datetime.strptime(f"{date_str} {start_str}", "%Y/%m/%d %H:%M")
            kw = parse_float(import_str)
        except (ValueError, IndexError):
            skipped += 1
            continue

        # kW over 5 minutes = kWh
        kwh = kw * (5 / 60)

        tariff = get_tariff(dt)
        totals[tariff] += kwh
       
    # Write output
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "Week Starting (Monday)",
            "Red kWh",
            "Yellow kWh",
            "Green kWh",
            "Total kWh"
        ])
      
        r = totals["Red"]
        y = totals["Yellow"]
        g = totals["Green"]
        total = r + y + g

        writer.writerow([
                f"{r:.4f}",
                f"{y:.4f}",
                f"{g:.4f}",
                f"{total:.4f}"
            ])

    print(f"Done. {processed} intervals processed, {skipped} skipped.")
    print(f"Output saved to: {output_path}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python ruraflex_processor.py <input_csv> [output_csv]")
        sys.exit(1)

    input_csv = sys.argv[1]

    if len(sys.argv) >= 3:
        output_csv = sys.argv[2]
    else:
        base, ext = os.path.splitext(input_csv)
        output_csv = f"{base}_tariff_summary.csv"

    process(input_csv, output_csv)
