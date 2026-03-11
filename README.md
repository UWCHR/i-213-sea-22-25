# i-213-sea-22-25

Analysis of ICE I-213 data for Seattle Area of Responsibility, 2022-2025. Development of this repository is ongoing.

See UWCHR research memo: https://jsis.washington.edu/humanrights/2026/03/11/new-data-on-pnw-immigration-enforcement-reveal-powerful-surge-in-late-2025/

I-213 forms document a subset of all ICE arrests, and may systematically underrepresent some populations. We recommend caution in interpreting this data without comparison to other sources. Gecoded arrest locations are approximate, they do not represent exact coordinates of the enforcement activity.

Analysis-ready versions of dataset:
- [`geocode/output/sea-i213s-2026-02-13-geocoded.csv`](https://github.com/UWCHR/i-213-sea-22-25/blob/main/geocode/output/sea-i213s-2026-02-13-geocoded.csv) (pipe-delimited CSV)
- [`geocode/output/sea-i213s-2026-02-13.geocoded.xlsx`](https://github.com/UWCHR/i-213-sea-22-25/blob/main/geocode/output/sea-i213s-2026-02-13-geocoded.xlsx) (XLSX)

Summarized annual and quarterly total and per-capita I-213 arrests, 2022-2025, OR and WA:
- [`per-capita/output/annual-arrests-per-capita-wa-or-2022-2025.csv`](https://github.com/UWCHR/i-213-sea-22-25/blob/main/per-capita/output/annual-arrests-per-capita-wa-or-2022-2025.csv) (comma-delimited CSV)
- [`per-capita/output/quarterly-arrests-per-capita-wa-or-2022-2025.csv`](https://github.com/UWCHR/i-213-sea-22-25/blob/main/per-capita/output/quarterly-arrests-per-capita-wa-or-2022-2025.csv) (comma-delimited CSV)

U.S. Census Estimates: https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-total.html

Task execution order:
- `import/input/`: Contains original dataset (with minimal prior processing to drop sensitive and fully-redacted fields)
- `clean/src/clean.R`: Sets up analysis fields, performs cleaning of `apprehension_landmark_descr` and `app_ldmk_other_comment_text` fields
- `expand/src/expand.R`: Summarizes contents of `criminal_charges` and `child_count` fields
- `geocode/src/geocode/R`: Geolocates records using Google Maps API based on `to_geocode`
- `per-capita/src/per-capita.R`: Summarizes annual and quarterly per capita rates of arrest per county in OR, WA
- `analyze/note/`: Descriptive and exploratory analysis notebooks

Columns created in this repo to facilitate analysis:

- "any_convicted": Any charges with status "Convicted" in `criminal_charges` field
- "any_pending": Any charges with status "Pending" in `criminal_charges` field
- "any_dismissed": Any charges with status "Dismissed" in `criminal_charges` field
- "any_overturned": Any charges with status "Overturned" in `criminal_charges` field
- "any_unknown": Any charges with status "IIDS ETL NULL" in `criminal_charges` field
- "criminal_charge_status": Summary of `criminal_charges` field, "Convicted" if any convictions, "Pending" if no convictions and any pending charges, otherwise "None"
- "total_children": Total children in `child_count` field
- "any_usc": Does individual have any U.S. citizen children, based on whether any children with nationality "United States" in `child_count` field
- "apprehension_landmark_descr_clean": Cleaned version of `apprehension_landmark_descr`
- "app_ldmk_other_comment_text_clean": Cleaned version of `app_ldmk_other_comment_text`
- "to_geocode": Value passed to Google Maps API for geocoding; preferring `app_ldmk_other_comment_text_clean` if present, otherwise `apprehension_landmark_descr_clean`
- "lat": Latitude of `to_geocode` via Google Maps API
- "long": Longitude of `to_geocode` via Google Maps API
- "locality": City/town of `to_geocode` via Google Maps API
- "county": County of `to_geocode` via Google Maps API
- "state": State of `to_geocode` via Google Maps API
- "week": Week of `apprehension_date`, starting on Monday 
- "month": Month of `apprehension_date`
- "cy_quarter": Calendar year and quarter of `apprehension_date`
- "fy_quarter": U.S. government fiscal year and quarter of `apprehension_date`
- "fy": U.S. government fiscal year of `apprehension_date`
- "cy": Calendar year of `apprehension_date`
- "days_since_entry": Difference between `entry_date` and `apprehension_date` in days
- "years_since": Difference between `entry_date` and `apprehension_date` in years

Sensitive or fully redacted columns dropped in separate repository:

```
cols_to_sanitize <- c(
	"hair_color_code",
	"eye_color_code",
	"complexion_code",
	"height",
	"weight",
	"birth_city_name")

redacted_cols <- c(
	"officer_name",
	"examining_officer_name",
	"eid_subject_id",
	"ident_fin_text",
	"eid_od_id",
	"last_name",
	"middle_name",
	"first_name",
	"alien_file_nbr",
	"event_nbr",
	"fbi_nbr",
	"birth_date",
	"mother_first_name",
	"mother_middle_name",
	"mother_last_name",
	"father_first_name",
	"father_middle_name",
	"father_last_name",
	"spouse_first_name",
	"spouse_middle_name",
	"spouse_last_name",
	"record_checks",
	"misc_nbrs",
	"scars_marks_tattoos",
	"addresses",
	"record_of_deportable_excludable_alien_narrative"
	)
```

