# load package functions and data ---------------------------------------------
devtools::load_all()

# data with windows -----------------------------------------------------------

jh_state_w <- jh |>
  add_windows()

jh_city_w <- jh_city |>
  add_windows()

# placebo experiment ----------------------------------------------------------

year_state <- jh_state_w |>
  dplyr::group_by(state) |>
  dplyr::summarise(
    year_syg = dplyr::first(year_syg),
    year_rtc = dplyr::first(year_rtc)
  )

syg_year_state <- year_state |>
  dplyr::filter(!is.na(year_syg)) |>
  dplyr::select(-year_rtc)

rtc_year_state <- year_state |>
  dplyr::filter(!is.na(year_rtc)) |>
  dplyr::select(-year_syg)

set.seed(1)
sim <- purrr::map(
  1:1000,
  \(x) {
    permute_years(
      x,
      permute = TRUE,
      jh_state = jh,
      jh_city = jh_city,
      syg_year_state = syg_year_state,
      rtc_year_state = rtc_year_state
    )
  },
  .progress = TRUE
)

aux_sim <- sim |>
  purrr::list_rbind()

obs_coef <- permute_years(
  ii = 0,
  permute = FALSE,
  jh_state = jh,
  jh_city = jh_city,
  syg_year_state = syg_year_state,
  rtc_year_state = rtc_year_state
)

plot_sim_placebo("table03")
ggplot2::ggsave(
  "data-raw/pdf/placebo_table03.pdf",
  width = 8,
  height = 8
)
