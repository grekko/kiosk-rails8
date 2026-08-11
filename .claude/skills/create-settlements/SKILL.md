---
name: create-settlements
description: Read a draft monthly report's tally sheet (image or PDF) and create one settlement per client from it. Use when the user says "/create-settlements", "settle the monthly report", "create settlements from the report image", or asks to extract drink counts from a monthly report attachment.
---

# Create settlements from a monthly report sheet

Turns the handwritten tally sheet attached to a monthly report into settlements,
one per client, via `script/api`. Every write is confirmed by the user first.

All API calls go to **production** (`script/api` defaults to
`https://kiosk.grekko.de`). See `docs/api.md`.

## 1. Pick the report

```bash
script/api monthly-reports --state draft
```

Ask the user which one (AskUserQuestion, one option per draft report, newest
first). If there is exactly one draft, still confirm it.

Then check whether it is already settled:

```bash
script/api settlements --monthly-report-id <id>
```

If settlements exist, list the client names and stop unless the user says to
continue — this skill only ever *adds* settlements, so re-running would double-book
those clients. Clients that already have a settlement are skipped in step 5.

## 2. Fetch the attachment

```bash
script/api report-image <id> --output <scratchpad>/report-<id>.<ext>
```

`<scratchpad>` is the session scratchpad directory. The attachment may be a JPEG,
PNG **or PDF** (`image_content_type` in the API payload says which). Read it with
the Read tool — PDFs need `pages: "1"`.

If the report has no attachment, say so and stop.

## 3. Extract the counts

The sheet is a grid: client names down the left, drink columns across the top with
their price printed in the header, handwritten tally marks in the cells.

Read every cell and produce a table of client → drink → count.

**Known failure mode:** single tally marks sitting close to a row border get
attributed to the neighbouring row, or missed entirely. Five-bar gates
(`卌`) are also easy to misread as 4 or 6. Scan each column top to bottom a second
time specifically for lone marks before presenting anything.

## 4. Resolve ids, then get the counts confirmed

Map names against live data — never against a hardcoded table:

```bash
script/api clients
script/api drinks
```

**Drinks:** match the column header against `name`, then verify the header's
printed price equals the drink's `current_settlement_price_in_cents`. Both must
agree. Ambiguous families that the price disambiguates:

- "Fassbrause" → Oettinger Fassbrause Zitrone vs Gaffels Fassbrause Zitrone
- "Mate" → Club-Mate Original vs Mio Mio Mate (0,33L / 0,5L)

If two drinks match name *and* price, ask.

**Clients:** exact name match, except these sheet aliases (verified against
production):

- `Abdi` → `Abdalla`
- `Hannah & Tobi` → `Hannah, Tobias`

Any other name with no exact match — including names hand-added below the printed
table — gets flagged, not guessed. Do not create a client; ask the user.

Now present the extracted table (client, drink, count, resolved ids) plus:

- rows whose marks were ambiguous
- names that did not map
- clients already settled for this report (will be skipped)

Ask the user to confirm or correct. **Corrections replace the count they name; do
not re-read the sheet to argue.** Repeat this step until the user confirms every
count is correct. Never skip ahead to step 5 on an unconfirmed table.

## 5. Create the settlements

Ask explicitly whether to create the settlements. Only on a clear yes:

```bash
script/api create-settlement --client-id <id> --monthly-report-id <report-id> \
                             --generated-at <YYYY-MM-DD> --positions <drink_id>:<amount>,...
```

- One call per client with at least one non-zero count. Clients with an empty row
  get no settlement.
- `--generated-at` defaults to the **date part of the report's `created_at`**
  (that is the existing convention — e.g. report "Februar 2026", created
  2026-03-02, has settlements generated_at 2026-03-02). Show the date in the
  confirmation and let the user override.
- Run the calls one at a time and report failures per client; do not abort the
  remaining clients because one failed.

Afterwards print what was created (client, positions, `price_in_cents`) and the
report's `overall_amount` for a sanity check.

## 6. Stop there

Do **not** complete the settlements, send settlement emails, or complete the
monthly report. Those are separate, explicit asks
(`script/api complete <id>`, `send-email <id>`, `complete-report <id>`).
