library(pacman)

p_load(here, tidyverse, tidylog, lubridate, jsonlite)

in_file <- 'sea-i213s-2026-02-13.csv.gz'

df <- read_delim(here('expand', 'input', in_file), delim='|')

df$row_id <- 1:nrow(df)

expanded_criminal_charges <- df |>
  dplyr::select(row_id, criminal_charges) |>
  filter(!is.na(criminal_charges)) |>
  mutate(dat = map(criminal_charges, fromJSON)) |> # Convert JSON string to R list-column
  unnest_longer(dat) |>                   # Expand list-column to new rows
  unnest_wider(dat) %>% 
  group_by(row_id) %>% 
  mutate(charge_count = row_number(),
         total_charges = n(),
         charge_date = ymd(CHARGE_DATE)) %>% 
  ungroup()

condensed_criminal_charges <- expanded_criminal_charges %>% 
  group_by(row_id) %>% 
  summarize(any_convicted = any(CHARGE_STATUS == "Convicted"),
            any_pending = any(CHARGE_STATUS == "Pending"),
            any_dismissed = any(CHARGE_STATUS == "Dismissed"),
            any_overtunred = any(CHARGE_STATUS == "Overturned"),
            any_unknown = any(CHARGE_STATUS == "IIDS ETL NULL"))

df_out <- df %>% 
left_join(condensed_criminal_charges, by = "row_id") %>% 
mutate(across(starts_with("any"), ~replace_na(.x, FALSE)),
     criminal_charge_status = case_when(any_convicted == TRUE ~ "Conviction",
                                        any_pending == TRUE ~ "Pending",
                                        TRUE ~ "None"))

stopifnot(nrow(df_out) == nrow(df))

expanded_child_count <- df |>
  dplyr::select(row_id, child_count) |>
  filter(!is.na(child_count)) |>
  mutate(dat = map(child_count, fromJSON)) |> # Convert JSON string to R list-column
  unnest_longer(dat) |>                   # Expand list-column to new rows
  unnest_wider(dat) %>% 
  ungroup()

condensed_child_count <- expanded_child_count %>% 
  group_by(row_id) %>% 
  summarize(total_children = sum(CHILD_COUNT),
            any_usc = any(CITIZENSHIP == "UNITED STATES"),
            )

df_out <- df_out %>% 
  left_join(condensed_child_count, by = "row_id") %>% 
  mutate(across(starts_with("any"), ~replace_na(.x, FALSE))) %>% 
  replace_na(list("total_children" = 0))

stopifnot(nrow(df_out) == nrow(df))

# # We don't do anything with `admin_charges` currently
#
# expanded_admin_charges <- df |>
#   dplyr::select(row_id, admin_charges) |>
#   filter(!is.na(admin_charges)) |>
#   mutate(dat = map(admin_charges, fromJSON)) |> # Convert JSON string to R list-column
#   unnest_longer(dat) |>                   # Expand list-column to new rows
#   unnest_wider(dat) %>% 
#   group_by(row_id) %>% 
#   mutate(charge_count = row_number(),
#          total_charges = n()) %>% 
#   ungroup()

df_out <- df_out %>%
	dplyr::select(-row_id)

out_file <- "sea-i213s-2026-02-13.csv"

write_delim(df_out, here::here("expand", "output", out_file), delim='|', na='')

