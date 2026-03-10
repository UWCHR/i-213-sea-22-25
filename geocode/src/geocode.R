library(pacman)

p_load(here, tidyverse, tidylog, lubridate, ggmap, tidygeocoder)

in_file <- 'sea-i213s-2026-02-13.csv'

df <- read_delim(here('geocode', 'input', in_file), delim='|')

ggkey = Sys.getenv("GOOGLEGEOCODE_API_KEY")
register_google(key = ggkey)

df <- df |>
	mutate(
	   to_geocode =
           case_when(
             is.na(app_ldmk_other_comment_text_clean) ~ apprehension_landmark_descr_clean,
             TRUE ~ app_ldmk_other_comment_text_clean),
         )

stopifnot(!"VANCOUVER, OR" %in% df$to_geocode)

ldmks <- df %>% 
  distinct(to_geocode)

### Google Maps geocode
geo <- geo(ldmks$to_geocode, method='google', full_results=TRUE)

out_file <- "sea-i213s-2026-02-13-raw-geo.rds"

saveRDS(geo, here::here("geocode", "output", out_file))

### Extract selected address components
geo_clean <- geo %>%
  filter(!is.na(lat),
         'partial_match' != TRUE) %>% 
  distinct()

address_components_tbl <- tibble()

for (i in 1:nrow(geo_clean)) {
  
  address_components <- pluck(geo_clean, "address_components", i)
  
  address_components <- address_components %>%
    unnest(cols=c('types'))

  address_components$address <- unlist(geo_clean[i, 'address'])
  
  if (is.null(address_components)) {
    next
  }
  
  address_components_tbl <- rbind(address_components_tbl, address_components)
}

locality_tbl <- address_components_tbl %>% 
  filter(types == 'locality') %>% 
  dplyr::select('address', 'short_name') %>% 
  rename(locality = short_name)

counties_tbl <- address_components_tbl %>% 
  filter(types == 'administrative_area_level_2') %>% 
  dplyr::select('address', 'short_name') %>% 
  rename(county = short_name)

states_tbl <- address_components_tbl %>% 
  filter(types == 'administrative_area_level_1') %>% 
  dplyr::select('address', 'short_name') %>% 
  rename(state = short_name)

geo_clean <- left_join(geo_clean, locality_tbl, by='address')

geo_clean <- left_join(geo_clean, counties_tbl, by='address')

geo_clean <- left_join(geo_clean, states_tbl, by='address')

geo_clean_subset <- geo_clean %>% 
  dplyr::select(lat, long, address, locality, county, state)

df_out <- df %>% 
  left_join(geo_clean_subset, by = c("to_geocode" = "address"))

stopifnot(nrow(df_out) == nrow(df))

out_file <- "sea-i213s-2026-02-13-geocoded.csv"

write_delim(df_out, here::here("geocode", "output", out_file), delim = "|", na = "")

