library(pacman)

p_load(here, tidyverse, tidylog, lubridate)

file <- "sea-i213s-2026-02-13-geocoded.csv"

df <- read_delim(here('per-capita', 'input', file), delim='|')

# Source for census estimates: https://www.census.gov/data/tables/time-series/demo/popest/2020s-counties-total.html

pop_wa <- read_delim(here::here("per-capita", "input", "co-est2024-pop-53.csv"), delim=',', skip = 3, n_max = 40)

pop_or <- read_delim(here::here("per-capita", "input", "co-est2024-pop-41.csv"), delim=',', skip = 3, n_max = 37)

col_names <- c("geographic_area", "april_1_2020_estimates_base", "pop_2020", "pop_2021", "pop_2022", "pop_2023", "pop_2024")

names(pop_wa) <- col_names

names(pop_or) <- col_names

pop_wa <- pop_wa %>% 
  dplyr::select(col_names)

pop_or <- pop_or %>% 
  dplyr::select(col_names)

pop_wa <- pop_wa %>% 
  mutate(geographic_area = str_replace(geographic_area, "\\.", ""),
         geographic_area = str_replace(geographic_area, ", Washington", ""),
         state = "WA")

pop_or <- pop_or %>% 
  mutate(geographic_area = str_replace(geographic_area, "\\.", ""),
         geographic_area = str_replace(geographic_area, ", Oregon", ""),
         state = "OR")

pop <- rbind(pop_wa, pop_or)

pop_long <- pop %>% 
  dplyr::select(-april_1_2020_estimates_base) %>% 
  pivot_longer(cols = starts_with("pop")) %>% 
  mutate(name = as.numeric(str_replace(name, "pop_", ""))) %>% 
  filter(!geographic_area %in% c("Washington", "Oregon"))

pop_2025 <- pop_long %>% 
  filter(name == 2024)

pop_2025$name <- 2025

pop_long <- rbind(pop_long, pop_2025)

# Annual arrests per capita

dat <- df %>% 
  filter(state %in% c("WA", "OR")) %>% 
  filter(cy >= 2022) %>% 
  group_by(cy, state, county) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  drop_na()

dat_wa <- dat %>% 
  filter(state == "WA") %>% 
  complete(county, cy, fill=list(n=0, state = "WA"))
  
dat_or <- dat %>% 
  filter(state == "OR") %>% 
  complete(county, cy, fill=list(n=0, state = "OR"))

dat <- rbind(dat_wa, dat_or)

annual_arrests_pc <- dat %>% 
  left_join(pop_long, by=c("county" = "geographic_area", "state" = "state", "cy" = "name")) %>% 
  rename(arrests = n,
         pop = value) %>% 
  mutate(arrests_pc = arrests / pop * 100000,
         county_lower = tolower(str_replace(county, " County", "")))

write_delim(annual_arrests_pc, here::here('per-capita', 'output', 'annual-arrests-per-capita-wa-or-2022-2025.csv'), delim = ",", na='')

# Quarterly arrests per capita

dat <- df %>% 
  filter(state %in% c("WA", "OR")) %>% 
  filter(cy >= 2022) %>% 
  group_by(cy_quarter, state, county) %>% 
  summarize(n = n()) %>% 
  ungroup() %>% 
  drop_na() %>% 
  mutate(cy_quarter = factor(cy_quarter))

dat_wa <- dat %>% 
  filter(state == "WA") %>% 
  complete(county, cy_quarter, fill=list(n=0, state = "WA"))
  
dat_or <- dat %>% 
  filter(state == "OR") %>% 
  complete(county, cy_quarter, fill=list(n=0, state = "OR"))

dat_2 <- rbind(dat_wa, dat_or) %>% 
  mutate(cy = as.numeric(substr(as.character(cy_quarter), 0, 4)))

quarterly_arrests_pc <- dat_2 %>% 
  left_join(pop_long, by=c("county" = "geographic_area", "state" = "state", "cy" = "name")) %>% 
  rename(arrests = n,
         pop = value) %>% 
  mutate(arrests_pc = arrests / pop * 100000,
         county_lower = tolower(str_replace(county, " County", "")))

write_delim(quarterly_arrests_pc, here::here('per-capita', 'output', 'quarterly-arrests-per-capita-wa-or-2022-2025.csv'), delim = ",", na='')

#END.

