# Gun Laws and Justifiable Homicides: Replication Package

[![R-CMD-check](https://github.com/username/gunLawsJH/workflows/R-CMD-check/badge.svg)](https://github.com/username/gunLawsJH/actions)

## Overview

This R package provides a complete replication package for the paper **"Gun Laws and Justifiable Homicides: Contrasting Impacts on Civilians and Police?"** by Ivan Ribeiro, Julio Trecenti, Nelson Coelho, Jessica Maruyama, Abhay Aneja, and John Donohue.

## How to replicate the analysis

First, download the package from GitHub from the [zip file]() or clone the repository.

Then, open the project in RStudio or your preferred R environment and run the following commands to load all the necessary libraries:

```r
# Install devtools if not already installed
if (!require(devtools)) install.packages("devtools")

devtools::load_all()
```

## Data

The package includes two main datasets:

### State-Level Data (`jh`)
- **Coverage**: 50 US states, 1977-2020 (2,200 observations)
- **Sources**: FBI Supplementary Homicide Reports (SHR), FENC data
- **Variables**: Civilian and police justifiable homicides, gun law indicators, demographic controls

### City-Level Data (`jh_city`)
- **Coverage**: Major US cities, 1978-2020 (9,072 observations)  
- **Sources**: FBI SHR city-level data
- **Purpose**: Robustness checks at finer geographic resolution

## Reproducing the Analysis

The complete analysis can be reproduced by running the R scripts in the `data-raw/` folder in sequence. Each script serves a specific purpose in the replication pipeline:

### Step 1: Data Preparation (`0-data-prep.R`)

**Purpose**: Downloads raw data from external sources and prepares the analysis datasets.

This script:
- Downloads data files from GitHub releases using `piggyback` package:
  - `fatal_encounters.xlsx`: Fatal Encounters (FENC) police killing data
  - `rand_laws_syg_fix.parquet`: RAND Corporation gun law implementation dates
  - `ucr_pjh_state_year.parquet`: FBI UCR state-level justifiable homicide data
  - `ucr_pjh_city_year.parquet`: FBI UCR city-level justifiable homicide data
  - `main_db.csv`: Combined dataset with demographic and economic controls
- Processes and merges all data sources into final analysis datasets
- Creates the `jh` (state-level) and `jh_city` (city-level) datasets
- Saves processed data using `usethis::use_data()` for package inclusion

**To run**:
```r
source("data-raw/0-data-prep.R")
```

**Output**: Creates `jh` and `jh_city` datasets in `data/` folder.

### Step 2: Main Regression Models (`1-models.R`)

**Purpose**: Reproduces Tables 3 and 4 from the paper showing the main regression results.

This script:
- Defines regression formulas for all model specifications
- Fits negative binomial models with state and year fixed effects
- **Table 3**: Models without SYG × RTC interaction term
  - Model 1: Police justifiable homicides (state-level)
  - Model 2: Civilian justifiable homicides (state-level)  
  - Model 3: Police FENC homicides (state-level)
  - Model 4: Police justifiable homicides (city-level)
  - Model 5: Civilian justifiable homicides (city-level)
- **Table 4**: Same models but adding SYG × RTC interaction term
- Uses appropriate clustering (state-level for models 1-3, state+city for models 4-5)

**Key finding**: The interaction term in Table 4 shows a 165% increase in civilian justifiable homicides when both SYG and RTC laws are present.

**To run**:
```r
source("data-raw/1-models.R")
```

**Output**: Prints regression tables to console showing coefficient estimates and standard errors.

### Step 3: Event Study Analysis (`2-event-study.R`)

**Purpose**: Creates event study plots to examine the timing of gun law effects and test for pre-existing trends.

This script:
- Adds time distance variables using `add_windows()` function
- Creates event study specifications using `i(rtc_dist_w2, ref = -1)` syntax
- Tests multiple time windows (2-year and 3-year) around law implementation
- Generates event study plots using `plot_window()` function
- Saves plots as PDF files in `data-raw/pdf/`

**Key insight**: Event studies reveal concerning pre-existing trends before law implementation, suggesting potential confounding factors.

**To run**:
```r
source("data-raw/2-event-study.R")
```

**Output**: 
- Event study plots saved as PDF files
- Console output showing event study regression results
- Visual evidence of pre-trends that complicate causal interpretation

### Step 4: Placebo Permutation Tests (`3-placebo.R`)

**Purpose**: Implements novel placebo tests by randomly permuting law implementation years across states.

This script:
- Extracts actual law implementation years for SYG and RTC laws by state
- Runs 1,000 permutations using `permute_years()` function with randomized law years
- Compares observed effects to distribution of placebo effects
- Creates placebo test visualizations using `plot_sim_placebo()`
- Tests whether observed associations could occur by chance alone

**Key finding**: Permutation tests suggest that observed effects may not reach conventional significance thresholds when accounting for multiple testing.

**To run** (Note: computationally intensive, may take 30+ minutes):
```r
source("data-raw/3-placebo.R")
```

**Output**:
- Placebo test plots showing distribution of random effects vs observed effects
- Statistical evidence for/against significance of main findings

### Running the Complete Analysis

To reproduce all results from the paper:

```r
# Step 1: Prepare data (run once)
source("data-raw/0-data-prep.R")

# Step 2: Main regression results (Tables 3-4)
source("data-raw/1-models.R")

# Step 3: Event study analysis 
source("data-raw/2-event-study.R")

# Step 4: Placebo permutation tests (computationally intensive)
source("data-raw/3-placebo.R")
```

### Alternative: Using Package Functions

Once the package is loaded, you can also reproduce key analyses using the exported functions:

```r
# Load package and data
devtools::load_all()

# Main regression analysis
fm_base <- JH_tot ~ shall_issue + syg_law + unemp_rate + log_police_rate + 
           pct_pop_black + pct_republican + poverty_rate + log_pop + pct_pop_18_24

fm_list <- create_formulas(fm_base)
results <- fit_model_all(fm_list, jh, jh_city)

# Event study with 2-year windows
jh_windowed <- add_windows(jh)
fm_event <- JH_tot ~ i(rtc_dist_w2, ref = -1) + i(syg_dist_w2, ref = -1) + 
            unemp_rate + log_police_rate + pct_pop_black + pct_republican + 
            poverty_rate + log_pop + pct_pop_18_24

event_results <- fit_model_all(create_formulas(fm_event), jh_windowed, jh_city)
plot_window(etable(event_results$table03))

# Single placebo permutation (example)
permute_result <- permute_years(1, permute = TRUE, jh)
```

## Computational Requirements

- **Memory**: Minimum 8GB RAM recommended
- **Time**: 
  - Data preparation: ~1 minute
  - Main models: ~1 minute
  - Event studies: ~1 minute
  - Placebo tests: 15-30 minutes (1,000 permutations)
- **Storage**: ~20MB for raw data files

## License

This replication package is provided under MIT License for academic and research purposes.
