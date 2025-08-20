#' Permute Gun Law Implementation Years for Placebo Testing
#'
#' This function performs placebo testing by randomly permuting the years when
#' Stand Your Ground (SYG) and Right-to-Carry (RTC) laws were implemented across
#' states, then fits regression models to test whether the observed effects could
#' have occurred by chance.
#'
#' @param ii Integer. Iteration number for the permutation (used for tracking
#'   multiple permutation runs).
#' @param permute Logical. If TRUE (default), randomly permutes the law
#'   implementation years across states. If FALSE, uses original years
#'   (useful for baseline comparison).
#' @param jh_state Data frame containing state-level justifiable homicide data
#'   with columns for state, year, and outcome variables.
#' @param jh_city Data frame containing city-level justifiable homicide data
#'  with columns for state, city, year, and outcome variables.
#' @param syg_year_state Data frame containing state-level SYG law implementation
#'  years with columns for state and year.
#' @param rtc_year_state Data frame containing state-level RTC law implementation
#' years with columns for state and year.
#'
#' @return A tibble containing regression coefficients for key law variables
#'   (shall_issue, syg_law, rtc_law, SYGxRTC) from both state and city models,
#'   with an iteration identifier.
#'
#' @details The function:
#'   \itemize{
#'     \item Permutes law implementation years across states (or keeps original if permute=FALSE)
#'     \item Creates binary law indicators based on permuted years
#'     \item Fits multiple regression models to both state and city data
#'     \item Returns coefficients for law variables to assess statistical significance
#'   }
#'
#' @export
permute_years <- function(
  ii,
  permute = TRUE,
  jh_state,
  jh_city,
  syg_year_state,
  rtc_year_state
) {
  # Create permuted (or original) law implementation years for each state
  if (permute) {
    # Randomly shuffle SYG law years across states
    syg_permute <- syg_year_state |>
      dplyr::transmute(state, year_syg_permute = sample(year_syg))

    # Randomly shuffle RTC law years across states
    rtc_permute <- rtc_year_state |>
      dplyr::transmute(state, year_rtc_permute = sample(year_rtc))
  } else {
    # Keep original law years (for baseline comparison)
    syg_permute <- syg_year_state |>
      dplyr::transmute(state, year_syg_permute = year_syg)
    rtc_permute <- rtc_year_state |>
      dplyr::transmute(state, year_rtc_permute = year_rtc)
  }

  # Process state-level data with permuted law years
  jh_state_permute <- jh_state |>
    # Join permuted law implementation years
    dplyr::left_join(syg_permute, "state") |>
    dplyr::left_join(rtc_permute, "state") |>
    dplyr::arrange(state, year) |>
    dplyr::group_by(state) |>
    dplyr::mutate(
      # Create binary SYG law indicator (1 from implementation year onward)
      syg_law = cumsum(year == year_syg_permute),
      syg_law = tidyr::replace_na(syg_law, 0),
      # Create binary RTC law indicator (1 from implementation year onward)
      rtc_law = cumsum(year == year_rtc_permute),
      rtc_law = tidyr::replace_na(rtc_law, 0),
      # Create interaction term for both laws active
      SYGxRTC = syg_law * rtc_law
    ) |>
    dplyr::ungroup()

  # Process city-level data with permuted law years
  jh_city_permute <- jh_city |>
    # Join permuted law implementation years
    dplyr::left_join(syg_permute, "state") |>
    dplyr::left_join(rtc_permute, "state") |>
    # Adjust for city dataset starting in 1978 (not 1977)
    dplyr::mutate(
      year_syg_permute = dplyr::if_else(
        year_syg_permute == 1977,
        1978,
        year_syg_permute
      ),
      year_rtc_permute = dplyr::if_else(
        year_rtc_permute == 1977,
        1978,
        year_rtc_permute
      )
    ) |>
    dplyr::arrange(id) |>
    dplyr::group_by(state, address_city) |>
    dplyr::mutate(
      # Create binary SYG law indicator (binary 0/1 instead of cumulative)
      syg_law = as.numeric(cumsum(year == year_syg_permute) > 0),
      syg_law = tidyr::replace_na(syg_law, 0),
      # Create binary RTC law indicator (cumulative count)
      rtc_law = cumsum(year == year_rtc_permute),
      rtc_law = tidyr::replace_na(rtc_law, 0),
      # Create interaction term for both laws active
      SYGxRTC = syg_law * rtc_law
    ) |>
    dplyr::ungroup()

  # Define regression formula with control variables
  fm <- JH_tot ~
    rtc_law +
      syg_law +
      unemp_rate + # Unemployment rate
      log_police_rate + # Log of police per capita
      pct_pop_black + # Percent Black population
      pct_republican + # Percent Republican voters
      poverty_rate + # Poverty rate
      log_pop + # Log population
      pct_pop_18_24 # Percent population aged 18-24

  # Create formula variations for different model specifications
  fm_list <- create_formulas(fm)

  # Fit models to both state and city datasets
  results <- suppressMessages({
    fit_model_all(fm_list, jh_state_permute, jh_city_permute)
  })

  # Extract and tidy coefficients from state models (table03)
  tab03 <- results$table03 |>
    purrr::map(broom::tidy) |>
    purrr::list_rbind(names_to = "model")

  # Extract and tidy coefficients from city models (table04)
  tab04 <- results$table04 |>
    purrr::map(broom::tidy) |>
    purrr::list_rbind(names_to = "model")

  # Combine results and filter for law-related coefficients only
  list(table03 = tab03, table04 = tab04) |>
    purrr::list_rbind(names_to = "table") |>
    dplyr::filter(
      # Keep only coefficients for law variables
      term %in% c("shall_issue", "syg_law", "rtc_law", "SYGxRTC")
    ) |>
    # Add iteration identifier
    dplyr::mutate(iter = ii, .before = 1)
}

#' Create Placebo Test Visualization
#'
#' This function creates a histogram plot showing the distribution of coefficients
#' from placebo permutations, with the original coefficient marked as a vertical
#' line to assess statistical significance.
#'
#' @param tab Character. Which table to plot ("table03" for state models,
#'   "table04" for city models).
#'
#' @return A ggplot object showing histograms of permuted coefficients faceted
#'   by model and law term, with original coefficients marked and p-values
#'   calculated based on permutation test.
#'
#' @details The plot shows:
#'   \itemize{
#'     \item Histogram of coefficients from permuted data
#'     \item Vertical dashed line showing original coefficient
#'     \item Shaded area showing more extreme values than original
#'     \item Text showing permutation-based p-value
#'     \item Color coding by original coefficient significance
#'   }
#'
#' @export
plot_sim_placebo <- function(tab) {
  # Calculate proportion of permuted coefficients more extreme than observed
  prop_top <- aux_sim |>
    dplyr::inner_join(obs_coef, c("table", "model", "term")) |>
    dplyr::group_by(table, model, term) |>
    dplyr::summarise(
      estimate = estimate.y[1],
      # Check if original coefficient is significant
      is_significant = dplyr::if_else(
        p.value.y[1] < .05,
        "Yes",
        "No"
      ),
      # Count permutations with smaller/larger coefficients
      menor = sum(estimate.x < estimate.y),
      maior = sum(estimate.x > estimate.y),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      # Calculate two-tailed p-value (proportion more extreme)
      prop = pmin(menor, maior) / 1000,
      prop_maior = maior / 1000
    )

  # Prepare observed coefficients for plotting
  obs_coef_plot <- obs_coef |>
    dplyr::mutate(
      is_significant = dplyr::if_else(
        p.value < .05,
        "Yes",
        "No"
      )
    ) |>
    # Rename terms for cleaner plot labels
    dplyr::mutate(
      term = dplyr::case_when(
        term == "rtc_law" ~ "RTC",
        term == "syg_law" ~ "SYG",
        term == "SYGxRTC" ~ "SYG x RTC"
      )
    ) |>
    # Rename models for cleaner plot labels
    dplyr::mutate(
      model = dplyr::case_when(
        model == 1 ~ "1. JH Civ", # Justifiable Homicide - Civilian
        model == 2 ~ "2. JH Pol", # Justifiable Homicide - Police
        model == 3 ~ "3. FENC Pol", # Felony Expanded Non-Culpable - Police
        model == 4 ~ "4. JH Civ - City", # JH Civilian - City level
        model == 5 ~ "5. JH Pol - City" # JH Police - City level
      )
    )

  # Prepare proportion data for plotting
  prop_top_plot <- prop_top |>
    # Apply same label transformations
    dplyr::mutate(
      term = dplyr::case_when(
        term == "rtc_law" ~ "RTC",
        term == "syg_law" ~ "SYG",
        term == "SYGxRTC" ~ "SYG x RTC"
      )
    ) |>
    dplyr::mutate(
      model = dplyr::case_when(
        model == 1 ~ "1. JH Civ",
        model == 2 ~ "2. JH Pol",
        model == 3 ~ "3. FENC Pol",
        model == 4 ~ "4. JH Civ - City",
        model == 5 ~ "5. JH Pol - City"
      )
    )

  # Create the main plot
  aux_sim |>
    # Apply label transformations to simulation data
    dplyr::mutate(
      term = dplyr::case_when(
        term == "rtc_law" ~ "RTC",
        term == "syg_law" ~ "SYG",
        term == "SYGxRTC" ~ "SYG x RTC"
      )
    ) |>
    dplyr::mutate(
      model = dplyr::case_when(
        model == 1 ~ "1. JH Civ",
        model == 2 ~ "2. JH Pol",
        model == 3 ~ "3. FENC Pol",
        model == 4 ~ "4. JH Civ - City",
        model == 5 ~ "5. JH Pol - City"
      )
    ) |>
    # Filter for requested table (state vs city models)
    dplyr::filter(table == tab) |>
    ggplot2::ggplot(ggplot2::aes(x = estimate)) +
    # Create histogram of permuted coefficients
    ggplot2::geom_histogram(bins = 50) +
    # Separate panels by model and law term
    ggplot2::facet_grid(model ~ term) +
    # Add vertical line for observed coefficient
    ggplot2::geom_vline(
      ggplot2::aes(xintercept = estimate, colour = is_significant),
      data = dplyr::filter(obs_coef_plot, table == tab),
      linetype = 2
    ) +
    # Add shaded area for more extreme values
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = estimate,
        xmax = Inf,
        ymin = 0,
        ymax = Inf,
        fill = is_significant
      ),
      data = dplyr::filter(obs_coef_plot, table == tab),
      alpha = .2
    ) +
    # Add text showing permutation p-value
    ggplot2::geom_text(
      ggplot2::aes(
        x = 0.6,
        y = Inf,
        label = scales::percent(prop, .1),
        colour = is_significant
      ),
      data = dplyr::filter(prop_top_plot, table == tab),
      vjust = 1.2,
      size = 3,
      fontface = "bold"
    ) +
    # Apply clean theme
    ggplot2::theme_minimal() +
    ggplot2::theme(
      strip.background = ggplot2::element_rect(
        fill = "gray90",
        colour = "transparent"
      ),
      legend.position = "bottom"
    ) +
    # Add axis and legend labels
    ggplot2::labs(
      x = "Estimate",
      y = "Frequency",
      colour = "Original coefficient is significant (p < .05)",
      fill = "Original coefficient is significant (p < .05)"
    ) +
    # Set color scheme (gray for non-significant, green for significant)
    ggplot2::scale_colour_manual(
      values = c("gray70", "darkgreen")
    ) +
    ggplot2::scale_fill_manual(
      values = c("gray70", "darkgreen")
    )
}
