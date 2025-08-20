# download and save the data --------------------------------------------------
fs::dir_create(here::here("data-raw/xlsx/"))
fs::dir_create(here::here("data-raw/parquet/"))
fs::dir_create(here::here("data-raw/csv/"))

# Fatal Encounters (FENC) data
piggyback::pb_download(
  file = "fatal_encounters.xlsx",
  dest = here::here("data-raw/xlsx/"),
  tag = "data"
)
# RAND laws data
piggyback::pb_download(
  file = "rand_laws_syg_fix.parquet",
  dest = here::here("data-raw/parquet/"),
  tag = "data",
)
# UCR data
piggyback::pb_download(
  file = "ucr_pjh_state_year.parquet",
  dest = here::here("data-raw/parquet/"),
  tag = "data"
)
# UCR city-level data
piggyback::pb_download(
  file = "ucr_pjh_city_year.parquet",
  dest = here::here("data-raw/parquet/"),
  tag = "data"
)
# Main DB
piggyback::pb_download(
  file = "main_db.csv",
  dest = here::here("data-raw/csv/"),
  tag = "data"
)

# read and prepare data ------------------------------------------------------
# Fatal Encounters (FENC) data
fe <- readxl::read_excel(
  here::here("data-raw/xlsx/fatal_encounters.xlsx"),
  guess_max = 80000
) |>
  janitor::clean_names()

# get state fips
aux_state_fips <- usmap::us_map("states") |>
  tibble::as_tibble() |>
  dplyr::transmute(
    state = abbr,
    state_fips = as.numeric(fips)
  )

# FENC counts
count_fe <- fe |>
  dplyr::mutate(
    gunshot = as.numeric(highest_level_of_force == "Gunshot")
  ) |>
  dplyr::mutate(
    year = lubridate::year(date_of_injury_resulting_in_death_month_day_year)
  ) |>
  dplyr::group_by(state, year) |>
  dplyr::summarise(
    FENC_pol = dplyr::n(),
    FENC_pol_firearm = sum(gunshot, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::inner_join(aux_state_fips, "state") |>
  dplyr::select(-state)

# main db from 1976-2020
main_db <- here::here("data-raw/csv/main_db.csv") |>
  readr::read_csv() |>
  dplyr::mutate(id = paste(year, state, sep = "_"), .before = 1)

# Syg laws data with fixes
syg_fix <- here::here("data-raw/parquet/rand_laws_syg_fix.parquet") |>
  arrow::read_parquet() |>
  dplyr::select(state, year, syg_binary)

# data from UCR (dropbox + fbi data explorer)
jh_ucr <- arrow::read_parquet(
  here::here("data-raw/parquet/ucr_pjh_state_year.parquet")
)

# same JH, but for city-level (big cities) data
jh_ucr_city <- arrow::read_parquet(
  here::here("data-raw/parquet/ucr_pjh_city_year.parquet")
)

# join UCR with main db
main_db <- main_db |>
  dplyr::left_join(
    jh_ucr |>
      dplyr::transmute(
        id,
        jh_cit = jh_cit,
        jh_pol = jh_pol,
        jh_tot = jh_cit + jh_pol,
        jh_pol_firearm = jh_pol_firearm,
        jh_cit_firearm = jh_cit_firearm,
        jh_tot_firearm = jh_cit_firearm + jh_pol_firearm,
        jh_pol_bigcity = jh_pol_bigcity,
        jh_cit_bigcity = jh_cit_bigcity,
        jh_tot_bigcity = jh_cit_bigcity + jh_pol_bigcity,
        jh_pol_bigcity_firearm = jh_pol_bigcity_firearm,
        jh_cit_bigcity_firearm = jh_cit_bigcity_firearm,
        jh_tot_bigcity_firearm = jh_cit_bigcity_firearm + jh_pol_bigcity_firearm
      ),
    "id"
  ) |>
  dplyr::left_join(count_fe, c("state_fips", "year")) |>
  dplyr::left_join(syg_fix, c("state", "year")) |>
  dplyr::mutate(syg_binary = syg_binary.y)

# joining old covariates and renaming for consistency with past code
jh <- main_db |>
  dplyr::transmute(
    id,
    state,
    year,
    jh_tot_zero = as.numeric(is.na(jh_tot)),
    # dependent variables
    FENC_pol = FENC_pol_firearm,
    JH_pol = jh_pol_firearm,
    JH_cit = jh_cit_firearm,
    shall_issue = rtc_binary,
    syg_law = syg_binary,
    SYGxRTC = rtc_binary * syg_binary,
    # socioeconomic
    unemp_rate = pct_unemp,
    poverty_rate = pct_poverty,
    # crime and law enforcement
    log_police_rate = log(pct_pol_officers_1000),
    # demographics
    log_pop = log10(pop),
    pct_pop_18_24 = pct_pop_18_24,
    # new variables:
    pct_pop_black,
    pct_republican,
    pct_state_leoka_assaults_pol1000 = pct_state_leoka_assaults_total_pol1000,
    pct_state_leoka_assaults_pop1000 = pct_state_leoka_assaults_total_pop1000
  ) |>
  tidyr::replace_na(
    list(
      JH_tot_para_filtrar_zero = 0,
      JH_pol_firearm = 0,
      JH_cit_firearm = 0,
      JH_pol_bigcity_firearm = 0,
      JH_cit_bigcity_firearm = 0
    ),
  ) |>
  dplyr::mutate(
    JH_pol = tidyr::replace_na(JH_pol, 0),
    JH_cit = tidyr::replace_na(JH_cit, 0)
  ) |>
  dplyr::arrange(id)

# city-level data
jh_city <- jh_ucr_city |>
  dplyr::mutate(state = tolower(state_name)) |>
  dplyr::inner_join(
    dplyr::select(main_db, state, year, pct_republican, rtc_binary, syg_binary),
    c("state", "year")
  ) |>
  dplyr::mutate(
    SYGxRTC = rtc_binary * syg_binary,
  ) |>
  dplyr::rename(
    shall_issue = rtc_binary,
    syg_law = syg_binary,
    poverty_rate = city_poverty_rate,
    log_police_rate = city_log_police_rate,
    log_pop = city_log_pop,
    pct_pop_18_24 = city_pct_pop_18_24,
    unemp_rate = city_unemp_rate,
    pct_pop_black = city_pct_pop_black,
    JH_city_pol = jh_pol_firearm,
    JH_city_cit = jh_cit_firearm
  ) |>
  dplyr::distinct(id, .keep_all = TRUE) |>
  dplyr::arrange(id)

# save model data -------------------------------------------------------------
usethis::use_data(jh, overwrite = TRUE)
usethis::use_data(jh_city, overwrite = TRUE)
