# i-213-sea-22-25

Analysis of ICE I-213 data for Seattle Area of Responsibility, 2022-2025.

Note that `geocode/src/geocode.R` requires Google Maps API ("GOOGLEGEOCODE_API_KEY") and may incur data charges depending on volume of API queries. Code is optimized to geocode each unique landmark value once.

Sensitive columns dropped in separate repository:

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