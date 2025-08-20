# Gun Laws and Justifiable Homicides: Replication Package

[![R-CMD-check](https://github.com/ceoe-unifesp/gunLawsJH/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ceoe-unifesp/gunLawsJH/actions/workflows/R-CMD-check.yaml)

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.16907906.svg)](https://doi.org/10.5281/zenodo.16907906)


## Overview

This R package provides a complete replication package for the paper **"Gun Laws and Justifiable Homicides: Contrasting Impacts on Civilians and Police?"** by Ivan Ribeiro, Julio Trecenti, Nelson Coelho, Jessica Maruyama, Abhay Aneja, and John Donohue.

## How to replicate the analysis

First, download the package from GitHub from the [zip file](https://github.com/ceoe-unifesp/gunLawsJH/archive/refs/heads/main.zip) or clone the repository.

Then, open the project in RStudio or your preferred R environment and run the following commands to load all the necessary libraries:

```r
# Install devtools if not already installed
if (!require(devtools)) install.packages("devtools")

devtools::install()
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

### Step 1: Data Preparation (`data-raw/0-data-prep.R`)

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

You don't need to run this script again unless you want to reproduce the data preparation step or update the raw data files.

### Step 2: Main Regression Models (`data-raw/1-models.R`)

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

### Step 3: Event Study Analysis (`data-raw/2-event-study.R`)

**Purpose**: Creates event study plots to examine the timing of gun law effects and test for pre-existing trends.

This script:
- Adds time distance variables using `add_windows()` function
- Creates event study specifications using `i(rtc_dist_w2, ref = -1)` syntax
- Tests multiple time windows (2-year and 3-year) around law implementation
- Generates event study plots using `plot_window()` function
- Saves plots as PDF files in `data-raw/pdf/`

**Output**: 
- Event study plots saved as PDF files
- Console output showing event study regression results
- Visual evidence of pre-trends that complicate causal interpretation

### Step 4: Placebo Permutation Tests (`data-raw/3-placebo.R`)

**Purpose**: Implements novel placebo tests by randomly permuting law implementation years across states.

This script:
- Extracts actual law implementation years for SYG and RTC laws by state
- Runs 1,000 permutations using `permute_years()` function with randomized law years
- Compares observed effects to distribution of placebo effects
- Creates placebo test visualizations using `plot_sim_placebo()`
- Tests whether observed associations could occur by chance alone

**Output**:
- Placebo test plots showing distribution of random effects vs observed effects
- Statistical evidence for/against significance of main findings

## Computational Requirements

- **Memory**: Minimum 8GB RAM recommended
- **Time**: 
  - Data preparation: ~1 minute
  - Main models: ~1 minute
  - Event studies: ~1 minute
  - Placebo tests: 15-30 minutes (1,000 permutations)
- **Storage**: ~20MB for raw data files

## Citation

If you use this replication package in your research, please cite the original paper:

```latex
@software{gunlawsjh_2025_16907906,
  author       = {Julio Trecenti},
  title        = {ceoe-unifesp/gunLawsJH: Replication},
  month        = aug,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {v1.0.0},
  doi          = {10.5281/zenodo.16907906},
  url          = {https://doi.org/10.5281/zenodo.16907906},
}
```

## License

This replication package is provided under MIT License for academic and research purposes.
