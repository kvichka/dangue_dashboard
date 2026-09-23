# Dengue Situation Dashboard — GitHub Pages version

## What's in this folder
```
index.html          the dashboard shell — all HTML/CSS/JS, no embedded data
Data/
  dengue-data.json   all the dashboard's data, as plain JSON
```
`index.html` loads `Data/dengue-data.json` at runtime with `fetch()`. This
only works when the page is served over `http://` or `https://` — opening
`index.html` directly by double-clicking it (`file://...`) will show an
error message on the page, because browsers block `fetch()` of local files
for security reasons. See "Testing locally" below if you want to preview it
before pushing to GitHub.

## Putting this on GitHub Pages

1. **Create a repository** on GitHub (or use an existing one).
2. **Upload both `index.html` and the whole `Data` folder** to the repo,
   keeping them in the same relative position shown above (i.e. `Data/`
   sits next to `index.html`, not inside another folder).
   - Easiest way: on the repo's GitHub page, click **Add file → Upload
     files**, drag in `index.html` and the `Data` folder, then commit.
   - Or with git from the command line, from inside this folder:
     ```
     git init
     git add index.html Data
     git commit -m "Add dengue dashboard"
     git branch -M main
     git remote add origin https://github.com/<your-username>/<your-repo>.git
     git push -u origin main
     ```
3. **Turn on Pages**: in the repo, go to **Settings → Pages**. Under
   "Build and deployment", set **Source** to "Deploy from a branch", pick
   the **main** branch and the **/ (root)** folder, then **Save**.
4. GitHub will build the site (takes 30 seconds to a couple of minutes).
   The same Settings → Pages screen will then show the live URL, something
   like:
   ```
   https://<your-username>.github.io/<your-repo>/
   ```
5. Open that URL — the dashboard should load exactly as it does locally.

## Entering the weekly figures

The dashboard's **W1 Weekly Epidemic Curve** is fed by the
`National_Weekly_Entry` sheet in `Dengue_Master_Data_Entry.xlsx`. Weeks 1-53
of 2026 are already laid out for "All Cambodia", so each time a bulletin lands
you only fill in two cells:

1. Find that week's row and type **Cases** and **Deaths**.
2. **Leave a week blank until it is reported — don't type 0.** A blank reads as
   "not reported yet" and the curve simply ends at the last reported week; a 0
   reads as "reported, and there were no cases" and draws a bar at the floor.
3. Check `QA_Checklist` (the weekly checks are rows 13-16), then run
   `update_data` as usual.

Until the first week is filled in, W1 shows a "no weekly data entered yet"
message instead of an empty axis — that is the expected state, not an error.

The reporting period in the page header updates itself from the data — you
never edit it. Once weekly rows exist it reads "DHF Weekly Report — Week N,
YYYY (week ending D Mon YYYY)" from the newest week entered; with no weekly
rows it falls back to naming the last month the monthly sheet reported, rather
than claiming a week the file can't back up.

### The endemic / epidemic lines on W1

W1 sits directly under N1 and asks the same outbreak question at weekly
resolution. Its **Show:** checkboxes turn three overlays on and off:

- **Deaths** — deaths that week, on the right-hand axis.
- **Endemic (historical mean)** — the average cases for that ISO week across
  earlier years.
- **Epidemic threshold (mean + 2SD)** — the same construction N1 uses. A week
  above it is drawn as a **red bar**.

The two channel lines are computed per ISO week from **earlier years of weekly
entry only**. They are deliberately not derived from N1's monthly baseline —
spreading a monthly average across four or five weeks would invent a weekly
shape the bulletin never reported.

So those two checkboxes start **greyed out**, and stay that way until the sheet
holds at least two earlier years of weekly data (a standard deviation needs two
points). Hover a greyed-out checkbox and it tells you which years it does have.
With only two or three prior years the caption also warns that the band is wide
and unstable; it firms up as more years accumulate.

Province-level weekly rows are optional. The spare rows below the 2026 block
accept a province name instead of "All Cambodia", and W1 will follow the
dashboard's province filter for whichever provinces you fill in; for provinces
with no weekly rows it falls back to the national curve and says so on the
chart. Weeks are ISO weeks (Monday-Sunday) and the dates are pre-filled —
overwrite them if the NDCP bulletin numbers its weeks differently.

Weekly and monthly figures are entered separately and won't always reconcile
exactly, because the bulletin revises earlier weeks as late reports arrive.
The chart says so in its own caption.

## Updating the data later

You don't need to touch `index.html` again for a routine data refresh —
only `Data/dengue-data.json` changes. The `Dengue_Dashboard_Local_Updater`
toolkit (the one with `update_dashboard.py` and your
`Dengue_Master_Data_Entry.xlsx`) can regenerate this same JSON structure if
you ask for a version of the script that writes to `Data/dengue-data.json`
instead of embedding it in the HTML. Once you have the new JSON file,
replace the old one in the `Data` folder on GitHub (upload it again with
the same filename) and commit — Pages will redeploy automatically within a
minute or two.

## Testing locally before pushing

Browsers won't `fetch()` a local file directly, so use a tiny local web
server instead of double-clicking `index.html`:

```
cd path/to/this/folder
python3 -m http.server 8000
```
Then open `http://localhost:8000/` in your browser. (Python 3 is required;
on Windows this is usually already available as `py -m http.server 8000`.)

## External dependencies (loaded via CDN, require internet access)
- Chart.js 4.5.1 — `cdn.jsdelivr.net`
- Leaflet 1.9.4 — `unpkg.com`
- Google Fonts (Inter, Noto Sans Khmer) — `fonts.googleapis.com`

These load automatically whenever the page is opened with an internet
connection — no setup needed, but the dashboard won't render correctly
without internet access at least once per visit (browsers cache these
after the first load).
