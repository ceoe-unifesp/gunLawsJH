#' Add Event Study Time Windows for Gun Law Analysis
#'
#' Creates time distance variables for Stand Your Ground (SYG) and Right-to-Carry
#' (RTC) laws to enable event study analysis with different time windows around
#' law implementation dates.
#'
#' @param da Data frame containing state-level data with binary law indicators
#'   (syg_law, shall_issue) and year information.
#'
#' @return Data frame with additional columns for time distances from law
#'   implementation at different window sizes (1, 2, 3, and 10 years), converted
#'   to factors for regression analysis.
#'
#' @details The function:
#'   \itemize{
#'     \item Identifies first year each law was implemented per state
#'     \item Calculates distance (years) from implementation for each observation
#'     \item Creates windowed versions capping distances at specified limits
#'     \item Converts distance variables to factors for event study regressions
#'   }
#'
#' @export
add_windows <- function(da) {
  da |>
    dplyr::group_by(state) |>
    dplyr::mutate(
      # Find first year SYG law was active (syg_law == 1) in each state
      year_syg = year[syg_law == 1][1],
      # Calculate years from SYG implementation (negative = before, positive = after)
      syg_dist = year_syg - year,

      # Create 1-year window: cap distances at -1 and +1
      syg_dist_w1 = dplyr::case_when(
        is.na(syg_dist) ~ -1, # States without SYG law = reference group
        syg_dist <= -1 ~ -1, # 1+ years before implementation
        syg_dist >= 1 ~ 1, # 1+ years after implementation
        .default = syg_dist # Year of implementation (0)
      ),

      # Create 2-year window: cap distances at -2 and +2
      syg_dist_w2 = dplyr::case_when(
        is.na(syg_dist) ~ -2, # States without SYG law = reference group
        syg_dist <= -2 ~ -2, # 2+ years before implementation
        syg_dist >= 2 ~ 2, # 2+ years after implementation
        .default = syg_dist # Years -1, 0, 1 from implementation
      ),

      # Create 3-year window: cap distances at -3 and +3
      syg_dist_w3 = dplyr::case_when(
        is.na(syg_dist) ~ -3, # States without SYG law = reference group
        syg_dist <= -3 ~ -3, # 3+ years before implementation
        syg_dist >= 3 ~ 3, # 3+ years after implementation
        .default = syg_dist # Years -2 to 2 from implementation
      ),

      # Create 10-year window: cap distances at -10 and +10
      syg_dist_w10 = dplyr::case_when(
        is.na(syg_dist) ~ -10, # States without SYG law = reference group
        syg_dist <= -10 ~ -10, # 10+ years before implementation
        syg_dist >= 10 ~ 10, # 10+ years after implementation
        .default = syg_dist # Years -9 to 9 from implementation
      ),

      # Find first year RTC law was active (shall_issue == 1) in each state
      year_rtc = year[shall_issue == 1][1],
      # Calculate years from RTC implementation
      rtc_dist = year_rtc - year,

      # Create RTC time windows (same logic as SYG above)
      rtc_dist_w1 = dplyr::case_when(
        is.na(rtc_dist) ~ -1, # States without RTC law = reference group
        rtc_dist <= -1 ~ -1, # 1+ years before implementation
        rtc_dist >= 1 ~ 1, # 1+ years after implementation
        .default = rtc_dist # Year of implementation (0)
      ),

      rtc_dist_w2 = dplyr::case_when(
        is.na(rtc_dist) ~ -2, # States without RTC law = reference group
        rtc_dist <= -2 ~ -2, # 2+ years before implementation
        rtc_dist >= 2 ~ 2, # 2+ years after implementation
        .default = rtc_dist # Years -1, 0, 1 from implementation
      ),

      rtc_dist_w3 = dplyr::case_when(
        is.na(rtc_dist) ~ -3, # States without RTC law = reference group
        rtc_dist <= -3 ~ -3, # 3+ years before implementation
        rtc_dist >= 3 ~ 3, # 3+ years after implementation
        .default = rtc_dist # Years -2 to 2 from implementation
      ),

      rtc_dist_w10 = dplyr::case_when(
        is.na(rtc_dist) ~ -10, # States without RTC law = reference group
        rtc_dist <= -10 ~ -10, # 10+ years before implementation
        rtc_dist >= 10 ~ 10, # 10+ years after implementation
        .default = rtc_dist # Years -9 to 9 from implementation
      ),

      # Convert all windowed distance variables to factors for regression
      # (required for fixest::i() function in event study specifications)
      dplyr::across(dplyr::matches("syg_dist_w[0-9]$"), factor),
      dplyr::across(dplyr::matches("rtc_dist_w[0-9]$"), factor),
    ) |>
    dplyr::ungroup()
}

#' Fix Formula Parentheses for fixest Compatibility
#'
#' Removes unnecessary parentheses from formula objects to ensure compatibility
#' with fixest package functions, while preserving essential grouping.
#'
#' @param x A formula object that may contain problematic parentheses.
#'
#' @return A cleaned formula object with unnecessary parentheses removed.
#'
#' @export
fix_parentheses <- function(x) {
  x |>
    # Convert formula to character for string manipulation
    deparse() |>
    # Remove problematic parentheses using negative lookbehind/lookahead
    stringr::str_remove_all("(?<!i)\\(|(?<!(state|w[0-9]|-1))\\)") |>
    # Collapse multi-line formulas back to single string
    paste(collapse = "") |>
    # Convert back to formula object
    stats::as.formula()
}

#' Create Formula Lists for Multiple Model Specifications
#'
#' Generates lists of formulas for different outcome variables and model
#' specifications used in gun law analysis, including fixed effects and
#' clustering specifications.
#'
#' @param fm_base Base formula containing predictors to be applied across
#'   all model specifications.
#'
#' @return Named list with two elements (table03, table04), each containing:
#'   \itemize{
#'     \item fm: List of formulas for different outcome variables
#'     \item type: Model type specification ("fenegbin")
#'     \item fm_cluster: List of clustering formulas
#'   }
#'
#' @details Creates formulas for:
#'   \itemize{
#'     \item Model 1: Civilian justifiable homicides (state-level)
#'     \item Model 2: Police justifiable homicides (state-level)
#'     \item Model 3: Police FENC homicides (state-level)
#'     \item Model 4: Civilian justifiable homicides (city-level)
#'     \item Model 5: Police justifiable homicides (city-level)
#'   }
#'
#'   Table04 specifications add SYGxRTC interaction terms.
#'
#' @export
create_formulas <- function(fm_base) {
  # Create formulas for different outcome variables
  fm_cit <- stats::update.formula(fm_base, JH_cit ~ .) # Civilian JH (state)
  fm_pol <- stats::update.formula(fm_base, JH_pol ~ .) # Police JH (state)
  fm_fenc <- stats::update.formula(fm_base, FENC_pol ~ .) # Police FENC (state)
  fm_city_cit <- stats::update.formula(fm_base, JH_city_cit ~ .) # Civilian JH (city)
  fm_city_pol <- stats::update.formula(fm_base, JH_city_pol ~ .) # Police JH (city)

  # Combine all base formulas into list
  fm <- list(fm_cit, fm_pol, fm_fenc, fm_city_cit, fm_city_pol)

  # Add fixed effects for state and year to all formulas
  fm_fe <- purrr::map(fm, \(x) {
    stats::update.formula(x, . ~ . | state + year)
  }) |>
    # Clean parentheses for fixest compatibility
    purrr::map(fix_parentheses)

  # Table 03: Base models with fixed effects
  fm_table03 <- fm_fe

  # Table 04: Add SYG x RTC interaction term to all models
  fm_fe_04 <- purrr::map(fm, \(x) {
    stats::update.formula(x, . ~ . + SYGxRTC | state + year)
  }) |>
    purrr::map(fix_parentheses)
  fm_table04 <- fm_fe_04

  # Define clustering structure for each model
  fm_cluster <- list(
    ~state, # Model 1: Cluster by state
    ~state, # Model 2: Cluster by state
    ~state, # Model 3: Cluster by state
    ~ state + address_city, # Model 4: Cluster by state and city
    ~ state + address_city # Model 5: Cluster by state and city
  )

  # Return structured list for both table specifications
  formula_list <- list(
    table03 = list(fm = fm_table03, type = "fenegbin", fm_cluster = fm_cluster),
    table04 = list(fm = fm_table04, type = "fenegbin", fm_cluster = fm_cluster)
  )
  formula_list
}

#' Fit All Model Specifications
#'
#' Fits negative binomial regression models with fixed effects for all
#' formula specifications using appropriate datasets (state vs city level)
#' and clustering structures.
#'
#' @param formula_list List of formula specifications created by create_formulas(),
#'   containing formulas, model types, and clustering specifications.
#' @param da_state Data frame containing state-level justifiable homicide data.
#' @param da_city Data frame containing city-level justifiable homicide data.
#'
#' @return Named list with fitted model objects for each table specification
#'   (table03, table04), each containing a list of 5 fitted models.
#'
#' @details For each formula specification:
#'   \itemize{
#'     \item Models 1-3: Fit using state-level data with state clustering
#'     \item Models 4-5: Fit using city-level data with state+city clustering
#'     \item All models use fixest::fenegbin() for negative binomial regression
#'     \item Progress bar displayed during fitting process
#'   }
#'
#' @export
fit_model_all <- function(formula_list, da_state, da_city) {
  purrr::map(
    formula_list,
    \(x) {
      # Fit each formula with its corresponding clustering specification
      res <- purrr::map2(x$fm, x$fm_cluster, \(fm, fm_cluster) {
        # Determine dataset based on clustering specification
        if (!stringr::str_detect(deparse(fm_cluster), "city")) {
          # Use state data for models without city clustering
          fixest::fenegbin(fm, data = da_state, cluster = fm_cluster)
        } else {
          # Use city data for models with city-level clustering
          fixest::fenegbin(fm, data = da_city, cluster = fm_cluster)
        }
      })
      res
    },
    .progress = TRUE # Show progress bar during model fitting
  )
}

#' Plot Event Study Results
#'
#' Creates event study plots showing coefficient estimates over time windows
#' around gun law implementation, with separate panels for different laws
#' and outcome types.
#'
#' @param tab Regression table object (typically from fixest::etable()) containing
#'   coefficient estimates for event study variables.
#'
#' @return A ggplot2 object showing event study results with:
#'   \itemize{
#'     \item Point estimates and confidence intervals over time
#'     \item Separate panels for RTC vs SYG laws and outcome types
#'     \item Baseline reference line at implementation year - 1
#'     \item Color coding for state vs city models
#'   }
#'
#' @details The plot shows:
#'   \itemize{
#'     \item X-axis: Years before/after law implementation
#'     \item Y-axis: Estimated effect size
#'     \item Reference lines at zero effect and law implementation
#'     \item Error bars showing 95% confidence intervals (±2 standard errors)
#'     \item Facets for different law types and outcome categories
#'   }
#'
#' @export
plot_window <- function(tab) {
  # Process regression table for plotting
  da_plot <- tab |>
    # Convert table to data frame and clean column names
    as.data.frame() |>
    janitor::clean_names() |>
    # Filter for event study variables (rtc_dist or syg_dist)
    dplyr::filter(stringr::str_detect(x, "rtc_|syg_")) |>
    # Pivot to long format for ggplot
    tidyr::pivot_longer(-x) |>
    dplyr::mutate(
      # Extract coefficient estimate from formatted string
      num = readr::parse_number(value),
      # Extract standard error from parentheses
      err = readr::parse_number(stringr::str_extract(value, "\\(.+")),
      # Extract significance stars
      star = stringr::str_extract(value, "\\*+"),
      # Extract time window from variable name (e.g., "= 2" from "rtc_dist_w2 = 2")
      w = as.numeric(stringr::str_extract(x, "(?<== ).*")),
      # Extract law type (RTC or SYG)
      law = toupper(stringr::str_extract(x, "rtc|syg"))
    ) |>
    # Fill in missing time points with zero effects
    tidyr::complete(
      name,
      law,
      w = seq(min(w), max(w)),
      fill = list(num = 0, err = 0)
    ) |>
    dplyr::mutate(
      # Create readable model labels
      model = dplyr::case_when(
        name %in% c("model_1", "model_4") ~ "Civilian", # Civilian JH
        name %in% c("model_2", "model_5") ~ "Police (SHR)", # Police JH from SHR
        name %in% c("model_3") ~ "Police (FENC)" # Police JH from FENC
      ),
      # Set factor levels for consistent ordering
      model = factor(
        model,
        levels = c("Civilian", "Police (SHR)", "Police (FENC)")
      ),
      # Identify data level (State vs City)
      fm = dplyr::case_when(
        name %in% c("model_1", "model_2", "model_3") ~ "State",
        name %in% c("model_4", "model_5") ~ "City"
      ),
      # Create facet labels combining law and outcome type
      facet = glue::glue("{law} - {model}"),
      facet = factor(
        facet,
        levels = c(
          "RTC - Civilian",
          "RTC - Police (SHR)",
          "RTC - Police (FENC)",
          "SYG - Civilian",
          "SYG - Police (SHR)",
          "SYG - Police (FENC)"
        )
      )
    ) |>
    # Replace missing significance indicators
    dplyr::mutate(star = tidyr::replace_na(star, "-")) |>
    dplyr::select(-x, -value)

  # Create custom x-axis labels
  limites <- sort(unique(da_plot$w))
  xlabs <- limites
  # Label extreme values to indicate truncation
  xlabs[1] <- paste0(xlabs[1], "\nor before")
  xlabs[length(xlabs)] <- paste0(xlabs[length(xlabs)], "\nor after")

  # Create the event study plot
  da_plot |>
    ggplot2::ggplot() +
    ggplot2::aes(
      x = w, # Time relative to law implementation
      y = num, # Coefficient estimate
      colour = fm # Color by data level (State vs City)
    ) +
    # Add reference line at zero effect
    ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = 2) +
    # Plot point estimates
    ggplot2::geom_point() +
    # Connect points with lines
    ggplot2::geom_line() +
    # Add vertical line at baseline period (year before implementation)
    ggplot2::geom_vline(xintercept = -0.5, colour = "black", linetype = 3) +
    # Add 95% confidence intervals (±2 standard errors)
    ggplot2::geom_errorbar(
      ggplot2::aes(ymin = num - err * 2, ymax = num + err * 2),
      width = 0.1
    ) +
    # Create separate panels for each law-outcome combination
    ggplot2::facet_wrap(~facet) +
    # Set color scheme for state vs city models
    ggplot2::scale_colour_manual(values = c("darkblue", "seagreen4")) +
    # Customize x-axis with truncation labels
    ggplot2::scale_x_continuous(
      breaks = limites,
      labels = xlabs,
      expand = c(.1, .1)
    ) +
    # Apply clean theme
    ggplot2::theme_minimal() +
    # Add informative labels
    ggplot2::labs(
      x = "Years Before / After Law",
      y = "Effect",
      colour = "",
      caption = "Baseline: Law Year - 1" # Clarify reference period
    ) +
    ggplot2::theme(
      # Style facet labels
      strip.background = ggplot2::element_rect(
        fill = "gray90",
        colour = "transparent"
      ),
      legend.position = "bottom",
      # Remove minor grid lines for cleaner appearance
      panel.grid.minor.y = ggplot2::element_blank(),
      panel.grid.minor.x = ggplot2::element_blank()
    )
}
