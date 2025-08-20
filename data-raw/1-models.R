# load package functions and data ---------------------------------------------
devtools::load_all()

## TABLE 03 -------------------------------------------------------------------

# formulas for Table 03
fm_tab3_jh_pol <- JH_pol ~
  shall_issue +
    syg_law +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab3_jh_cit <- JH_cit ~
  shall_issue +
    syg_law +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab3_fenc_pol <- FENC_pol ~
  shall_issue +
    syg_law +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab3_pol_city <- JH_city_pol ~
  shall_issue +
    syg_law +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab3_cit_city <- JH_city_cit ~
  shall_issue +
    syg_law +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

# fit models for Table 03
m_tab3_jh_pol <- fixest::fenegbin(fm_tab3_jh_pol, data = jh, cluster = ~state)
m_tab3_jh_cit <- fixest::fenegbin(fm_tab3_jh_cit, data = jh, cluster = ~state)
m_tab3_fenc_pol <- fixest::fenegbin(
  fm_tab3_fenc_pol,
  data = jh,
  cluster = ~state
)
m_tab3_pol_city <- fixest::fenegbin(
  fm_tab3_pol_city,
  data = jh_city,
  cluster = ~ state + address_city
)
m_tab3_cit_city <- fixest::fenegbin(
  fm_tab3_cit_city,
  data = jh_city,
  cluster = ~ state + address_city
)

# collect models for Table 03
modelos_tab3 <- list(
  m_tab3_jh_pol,
  m_tab3_jh_cit,
  m_tab3_fenc_pol,
  m_tab3_pol_city,
  m_tab3_cit_city
)

# print results for Table 03
fixest::etable(modelos_tab3, digits = 3)

## TABLE 04 -------------------------------------------------------------------

# formulas for Table 04
fm_tab4_jh_pol <- JH_pol ~
  shall_issue +
    syg_law +
    SYGxRTC +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab4_jh_cit <- JH_cit ~
  shall_issue +
    syg_law +
    SYGxRTC +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab4_fenc_pol <- FENC_pol ~
  shall_issue +
    syg_law +
    SYGxRTC +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab4_pol_city <- JH_city_pol ~
  shall_issue +
    syg_law +
    SYGxRTC +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

fm_tab4_cit_city <- JH_city_cit ~
  shall_issue +
    syg_law +
    SYGxRTC +
    unemp_rate +
    log_police_rate +
    pct_pop_black +
    pct_republican +
    poverty_rate +
    log_pop +
    pct_pop_18_24 |
    state + year

# fit models for Table 04
m_tab4_jh_pol <- fixest::fenegbin(fm_tab4_jh_pol, data = jh, cluster = ~state)
m_tab4_jh_cit <- fixest::fenegbin(fm_tab4_jh_cit, data = jh, cluster = ~state)
m_tab4_fenc_pol <- fixest::fenegbin(
  fm_tab4_fenc_pol,
  data = jh,
  cluster = ~state
)
m_tab4_pol_city <- fixest::fenegbin(
  fm_tab4_pol_city,
  data = jh_city,
  cluster = ~ state + address_city
)
m_tab4_cit_city <- fixest::fenegbin(
  fm_tab4_cit_city,
  data = jh_city,
  cluster = ~ state + address_city
)

# collect models for Table 04
modelos_tab4 <- list(
  m_tab4_jh_pol,
  m_tab4_jh_cit,
  m_tab4_fenc_pol,
  m_tab4_pol_city,
  m_tab4_cit_city
)

# print results for Table 04
fixest::etable(modelos_tab4, digits = 3)
