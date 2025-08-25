# load package functions and data ---------------------------------------------
devtools::load_all()

# data with windows -----------------------------------------------------------
jh_state_w <- jh |>
  # check R/utils-event.R
  add_windows()

jh_city_w <- jh_city |>
  add_windows()

## event study  ---------------------------------------------------------------

# window size = 2
fm_strategy2_w2 <- JH_tot ~
  i(rtc_dist_w2, ref = -1) +
    i(syg_dist_w2, ref = -1) +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24

fm_list_strategy2_w2 <- create_formulas(fm_strategy2_w2)
results_strategy2_w2 <- fit_model_all(
  fm_list_strategy2_w2,
  jh_state_w,
  jh_city_w
)

results_strategy2_w2$table03 |>
  fixest::etable(digits = 3)

results_strategy2_w2$table03 |>
  fixest::etable() |>
  plot_window()

# pdf
ggplot2::ggsave(
  "data-raw/pdf/strategy2_w2_table03.pdf",
  width = 8,
  height = 6
)
# tiff
ggplot2::ggsave(
  "data-raw/tiff/strategy2_w2_table03.tiff",
  width = 8,
  height = 6,
  dpi = 300,
  compression = "lzw",
  bg = "white"
)

results_strategy2_w2$table04 |>
  fixest::etable() |>
  plot_window()

# pdf
ggplot2::ggsave(
  "data-raw/pdf/strategy2_w2_table04.pdf",
  width = 8,
  height = 6
)
# tiff
ggplot2::ggsave(
  "data-raw/tiff/strategy2_w2_table04.tiff",
  width = 8,
  height = 6,
  dpi = 300,
  compression = "lzw",
  bg = "white"
)

# window size = 3
fm_strategy2_w3 <- JH_tot ~
  i(rtc_dist_w3, ref = -1) +
    i(syg_dist_w3, ref = -1) +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24

fm_list_strategy2_w3 <- create_formulas(fm_strategy2_w3)
results_strategy2_w3 <- fit_model_all(
  fm_list_strategy2_w3,
  jh_state_w,
  jh_city_w
)

results_strategy2_w3$table03 |>
  fixest::etable() |>
  plot_window()

# pdf
ggplot2::ggsave(
  "data-raw/pdf/strategy2_w3_table03.pdf",
  width = 8,
  height = 6
)
# tiff
ggplot2::ggsave(
  "data-raw/tiff/strategy2_w3_table03.tiff",
  width = 8,
  height = 6,
  dpi = 300,
  compression = "lzw",
  bg = "white"
)

results_strategy2_w3$table04 |>
  fixest::etable() |>
  plot_window()

# pdf
ggplot2::ggsave(
  "data-raw/pdf/strategy2_w3_table04.pdf",
  width = 8,
  height = 6
)
# tiff
ggplot2::ggsave(
  "data-raw/tiff/strategy2_w3_table04.tiff",
  width = 8,
  height = 6,
  dpi = 300,
  compression = "lzw",
  bg = "white"
)
