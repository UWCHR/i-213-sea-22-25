library(pacman)

p_load(here, tidyverse, zoo, lubridate, ggplot2, plotly, gghighlight, viridis, readxl, ggmap, tidygeocoder, sf, rnaturalearth)

in_file <- 'sea-i213s-2026-02-13.csv.gz'

df <- read_delim(here('clean', 'input', in_file), delim='|') |>
	mutate(apprehension_date = as.Date(apprehension_date),
         entry_date = as.Date(entry_date),
         occupation_text = str_to_upper(occupation_text),
         app_ldmk_other_comment_text = str_to_upper(app_ldmk_other_comment_text),
         week = floor_date(apprehension_date, "week", week_start = "Monday"),
         month = floor_date(apprehension_date, "month"),
         cy_quarter = as.factor(quarter(apprehension_date, fiscal_start = 1, with_year=TRUE)),
         fy_quarter = as.factor(quarter(apprehension_date, fiscal_start = 10, with_year=TRUE)),
         fy = substr(quarter(apprehension_date, fiscal_start = 10, with_year = TRUE), 0, 4),
         cy = year (apprehension_date),
         days_since_entry = difftime(apprehension_date, entry_date, units="days"),
         years_since_entry = as.numeric(difftime(apprehension_date, entry_date, units="days"))/365.4,
         age_group = cut(age,
                           breaks = c(0, 18, 25, 40, 60, Inf),
                           right = FALSE))

# We ultimately want to geocode records based on coalesced `app_ldmk_other_comment_text`
# and `apprehension_landmark_descr` fields. `app_ldmk_other_comment_text` is typically more precise,
# so we clean this first, and only clean `apprehension_landmark_descr` if missing.
# Where only geographic marker is ICE sub-office, we fill in city/state value for office. 

df_cleaned <- df %>% 
  mutate(
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "\\(B\\)\\(6\\), \\(B\\)\\(7\\)\\(C\\)|UNKNOWN PLACE", NA_character_),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "VANCOUVER, OR", "VANCOUVER, WA"),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "BATLLEGROUND, OR", "BATTLEGROUND, WA"),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "BEAVERTON, CA", "BEAVERTON, WA"),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "HAPPY VILLAGE", "HAPPY VALLEY, OR"),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "LONGIVIEW, OR", "LONGVIEW, WA"),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "HILLSBOROUGH, CA", "HILLSBOROUGH, OR"),
    app_ldmk_other_comment_text_clean =
           str_replace_all(app_ldmk_other_comment_text, "BEAVERTON, CA", "BEAVERTON, OR"),
    ) %>% 
  mutate(
    apprehension_landmark_descr_clean =
      case_when(apprehension_landmark_descr == "FEDERAL DETENTION CENTER (FDC)" & is.na(app_ldmk_other_comment_text) ~ "SEATAC, WA",
                apprehension_landmark_descr == "CLARK COUNTY JAIL" & is.na(app_ldmk_other_comment_text) ~ "VANCOUVER, WA",
                apprehension_landmark_descr == "CLACKAMAS COUNTY JAIL" & is.na(app_ldmk_other_comment_text) ~ "OREGON CITY, OR",
                apprehension_landmark_descr == "SEATTLE FUG OPS" & is.na(app_ldmk_other_comment_text) ~ "SEATTLE, WA",
                apprehension_landmark_descr == "MONROE WASHINGTON STATE REFORMATORY (WSR)" & is.na(app_ldmk_other_comment_text) ~ "MONROE, WA",
                apprehension_landmark_descr == "NORTHWEST DETENTION CENTER DETAINED DOCKET" & is.na(app_ldmk_other_comment_text) ~ "TACOMA, WA",
                TRUE ~ apprehension_landmark_descr),
     apprehension_landmark_descr_clean =
      case_when(
                str_detect(apprehension_landmark_descr, "POO") & is.na(app_ldmk_other_comment_text) ~ "PORTLAND, OR",
                str_detect(apprehension_landmark_descr, "PORTLAND") & is.na(app_ldmk_other_comment_text) ~ "PORTLAND, OR",
                str_detect(apprehension_landmark_descr, "FLD") & is.na(app_ldmk_other_comment_text) ~ "FERNDALE, WA",
                str_detect(apprehension_landmark_descr, "SEA") & is.na(app_ldmk_other_comment_text) ~ "SEATTLE, WA",
                str_detect(apprehension_landmark_descr, "SEATTLE") & is.na(app_ldmk_other_comment_text) ~ "SEATTLE, WA",
                str_detect(apprehension_landmark_descr, "SPO") & is.na(app_ldmk_other_comment_text) ~ "SPOKANE, WA",
                str_detect(apprehension_landmark_descr, "YAK") & is.na(app_ldmk_other_comment_text) ~ "YAKIMA, WA",
                str_detect(apprehension_landmark_descr, "MED") & is.na(app_ldmk_other_comment_text) ~ "MEDFORD, OR",
                str_detect(apprehension_landmark_descr, "EUG") & is.na(app_ldmk_other_comment_text) ~ "EUGENE, OR",
                TRUE ~ apprehension_landmark_descr)
    )


out_file <- 'sea-i213s-2026-02-13.csv.gz'

write_delim(df_cleaned, here('clean', 'output', out_file), delim='|', na='')


