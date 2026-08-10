# Dengue Surveillance Dashboard — Technical Notes

Companion to `index.html`. Three sections, as specified: the boundary file and its join key,
every derived metric with its formula, and the visuals this dataset cannot support.

Source workbook: `Dengue_Master_Data_Entry.xlsx`, extracted 2026-08-10.

---

## 1. Boundary file and join key

| Item | Value |
|---|---|
| File | `data/cambodia_provinces.geojson` |
| Source | geoBoundaries, Cambodia ADM1 |
| Licence | CC BY 4.0 — attribution is wired into the Leaflet control, do not remove it |
| Features | 25 |
| **Join key** | **`properties.name`** |
| Geometry | Simplified with `shapely`: `buffer(0)` → `simplify(0.004, preserve_topology=True)` → islands under 0.0004 deg² dropped → coordinates rounded to 4 dp |
| Size | 76 KB (from 2,259 KB raw) |
| Projection | EPSG:4326, as Leaflet requires |

### Why not Natural Earth

Natural Earth 10m admin-1 carries **24** Cambodian units. Tboung Khmum, split from Kampong Cham
in 2013, is absent. Using it would have silently folded Tboung Khmum's cases into Kampong Cham —
a province that recorded 3,247 cases in 2026. The error would not have been visible on the map.
Any future boundary swap must be checked for a 25-feature count first.

### Name normalisation

The workbook, geoBoundaries and the DHF bulletin all spell provinces differently. `NAME_MAP` in
the source resolves them to one canonical set. Aliases already handled include:

`B.Meanchey`, `Kg.Cham`, `Kg.Chhnang`, `Kg.Speu`, `Kg.Thom`, `K.Pr.Sihaknouk`, `Paillin`,
`Otdar Mean Chey`, `Preah Sihanouk`, `Tbong Khmum`, `Mondulkiri`, `Ratanakiri`, `Stung Treng`.

Add new spellings there, not at the call site. The dashboard validates the join in both directions
at load and reports failures in the Data quality panel rather than dropping provinces quietly:

- `DQ.joinFailures` — province in the case data with no population row
- `DQ.geoUnmatched` — polygon with no case data
- `DQ.dataUnmapped` — case data with no polygon

All three are empty on the current extract.

---

## 2. Derived metrics

### Incidence per 100,000

```
IR = (cases / person_years) × 100,000
```

`person_years` sums each **province-year population once**, never once per month. Summing the
monthly rows would multiply the denominator by 12 and divide the rate by the same, which is the
single most common error in this kind of dashboard. With one year selected, person-years is just
that year's population. With several selected it is the sum across them, and the insight panel
says "person-years" rather than "population" so the figure is not misread as a headcount.

Population source: NIS Population Projection 2020–2033, Table 4.27.1.
**2018 and 2019 are back-extrapolated**, not observed — the projection does not reach them. Each
province was projected backwards on its own growth rate. Rates for those two years carry more
uncertainty than the later ones and the Data quality panel says so.

### Case fatality ratio

```
CFR = (deaths / cases) × 100      suppressed where cases < 20
```

Below 20 cases a single death moves the ratio by whole percentage points. Suppressed cells show
`—` and the reason on hover. Where cases = 0 the ratio is undefined, not zero, and also shows `—`.
Values at or above 1% are marked in the alert colour: high for dengue and worth checking before
anyone quotes it.

### Small-numbers rate suppression

```
rate flagged unstable where cases < 5
```

Flagged provinces render grey on the choropleth, are excluded from the rate ranking, and carry
"insufficient cases for a stable rate". They are **not** excluded from case counts — only from
rates, where a denominator effect can look like transmission. On the current extract no province
falls below this in full-year 2026; it fires on short windows and on the 2021 collapse.

### Endemic channel

```
threshold(month) = mean + 2 × SD   of that calendar month across prior years
```

- Baseline uses **only months that actually reported**. Treating a missing month as zero would
  drag the mean down and manufacture breaches.
- Requires at least 2 baseline years for the national channel.
- Defined on **counts**, not rates, and labelled as such.
- **The observed line is always a single year** — the most recent one selected. A sum across
  several selected years cannot be compared with a single-year threshold; it would breach on
  arithmetic alone. When more than one year is selected the note states which year is drawn.

### Province alert threshold

```
threshold(province) = mean + 2 × SD  of the province's total over the SAME months, across prior years
requires ≥ 3 baseline years in which the province reported EVERY month in that window
```

The window is the months the current year actually holds inside the selected range. Selecting
2018–2026 must not test 2026's Jan–Jul total against full-year baselines, so it does not.
Provinces with too few complete baseline years return "insufficient baseline" rather than a
number. The insight panel reports consecutive months above threshold, because one month above
is noise and four is a signal.

### Choropleth class breaks

Seven classes, **quantile**, recomputed on every filter change from the provinces currently
in scope. Breaks are printed under the legend so a reader can see the map was reclassified and
does not compare colours across two different filter states. Colourblind-safe single-hue teal
ramp; the alert red is reserved exclusively for threshold breach and is used for nothing else.

### Like-for-like comparison

Every year-on-year figure is computed on the **intersection of months present in both years**.
2026 holds Jan–Jul, so a comparison against 2025 uses Jan–Jul 2025, and the window is printed on
every KPI rather than left in a footnote. Where the comparison year lacks a month the current
selection has, the change is **withheld**, not estimated.

Matching months is necessary but not sufficient. A year can report every month and still be
missing provinces, which would make a reporting change read as an epidemiological one. The
insight panel therefore also reports the difference in province-months between the two windows —
175 vs 171 on the default view.

### Missing vs zero vs not yet due

Three distinct states, kept apart everywhere:

| State | Meaning | Rendering |
|---|---|---|
| Reported 0 | The province reported, and recorded no cases | Lightest ramp step, counts as data |
| Not reported | The province owed a report and did not file | Line breaks, heatmap cell hatched |
| Not yet due | The month has not happened | Omitted from the completeness chart, blank heatmap cell |

234 province-months are missing across 2018–2025. Nothing is interpolated anywhere.

---

## 3. What this dataset cannot support

Each row states the exact column that would unlock it.

| Not built | Needed column | Note |
|---|---|---|
| Epidemic curve by epidemiological week | `EpiWeek` (ISO week) on the national sheet | Monthly is the finest resolution available. Aggregating months into weeks is not possible in either direction. |
| Onset-to-report lag | Case-level `DateOnset` and `DateReported` | Needs a line list, not aggregates. |
| Age or severity by province | `Province` on `National_AgeGroup_Entry` | Currently one national row set per year. **Visuals 12 and 13 are locked** and grey out under any province or month filter, with the reason on the panel. |
| Age or severity by month | `Month` on `National_AgeGroup_Entry` | Same sheet, annual only. |
| Sex disaggregation | `Sex` | Absent from every sheet. |
| Outcome or hospitalisation | `Outcome`, `Admitted` | Only aggregate deaths exist. |
| Operational-district layer | OD-level national reporting | `BTB_LineList_Entry` holds 767 Battambang cases with OD detail, but one province is not a national layer. Building an OD map from it would imply national coverage that does not exist. |
| Serotype or lab confirmation | `Serotype`, `LabConfirmed` | Absent. |
| Vector or intervention overlay | Ovitrap index, BG counts, coverage by province-month | Not in this workbook. Highest-value addition, given the Wolbachia programme. |
| 2025 age and severity | Rows for 2025 on `National_AgeGroup_Entry` | `QA_Checklist` expects them; only 4 rows (2026) exist. Adding them enables a year-on-year age comparison. |

---

## 4. Data errors found in the source

Raise these with whoever maintains the workbook.

**1. Pursat population 2023 duplicates 2022.** Both read 454,816. Every other province grows
about 1.5% a year; Pursat's own series implies roughly 461,900 for 2023. It reads as a copied
cell. Any 2023 Pursat incidence figure sits on a denominator that is too low. The dashboard
detects this class of error generically — an unchanged population between consecutive years —
and reports it in the Data quality panel, so a fix at source will clear the warning automatically.

**2. The `EXAMPLE` placeholder row is still in the workbook.** Jun 2026, 815 cases, 1 death, no
population match. Including it inflates the 2026 national total to 41,730 against the true 40,915.
`data/cases.csv` deliberately **retains** this row so the dashboard performs and reports its own
cleaning rather than trusting an upstream filter — the Data quality panel shows "1 template row
dropped". If you delete it at source, that counter goes to zero and nothing else changes.

**3. The Kep population figure in the brief is wrong.** The brief cites roughly 110,000. The
workbook says 43,459 in 2018 rising to 48,876 in 2026. The small-numbers rule the figure was
meant to justify is still correct; the example is not. Kep's 2026 incidence is 356.0 per 100,000
from 174 cases — high, and stable enough to report.

**4. 2021 is a reporting failure, not an epidemiological one.** 1,903 cases against 11,977 in
2020 looks like collapse in transmission. 86 of 300 province-months are missing, Kep filed
nothing at all for twelve months, and the worst month saw 15 of 25 provinces reporting. The
dashboard labels these as probable reporting failure and never draws the missing months as zero.

---

## 5. Running it

Double-click `index.html`. It opens from `file://` and loads the fallback payload in
`data/inline-data.js`.

To exercise the real CSV path — which is what a shared or hosted copy will use:

```bash
cd <folder containing index.html>
python -m http.server 8000
# then open http://localhost:8000
```

Both paths produce identical figures; this was verified by running the aggregation logic headless
against each. The footer states which path loaded.

**Keep the `data/` folder beside `index.html`.** Moving or emailing the HTML on its own will
break it, and the file says so on screen if that happens.

Chart.js 4.4.1, Leaflet 1.9.4, PapaParse 5.4.1 and html2canvas 1.4.1 load from CDN. Without a
connection the page still loads and every number and table renders; charts and the map do not.
To make it fully offline, save those four libraries beside `index.html` and repoint the tags.

---

## 6. Open question

Bilingual Khmer/English labelling was left unspecified in the brief. The dashboard is built
English-first with a single-point hook: a `LANG` constant near the top of the script and a
commented Battambang webfont link in the head.

Khmer strings are deliberately **not filled in**. Surveillance terms — endemic channel, case
fatality, incidence per 100,000, provisional — should be agreed with CNM/NDCP and checked against
Chuon Nath spelling before they appear on a screen a Programme Director reads. Machine-translating
them would put unverified technical vocabulary in front of the Ministry under a CHAI logo.

Specify which elements need Khmer — filter labels only, or chart titles and insight text as well —
and the strings can be drafted with anything uncertain flagged rather than guessed.
