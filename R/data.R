#' State-Level Justifiable Homicide Data (1977-2020)
#'
#' A dataset containing state-level justifiable homicide counts and related
#' variables for analyzing the effects of gun laws on homicide rates across
#' US states from 1977 to 2020.
#'
#' @format A data frame with 2,200 rows and 19 columns:
#' \describe{
#'   \item{id}{Character. Unique identifier combining year and state (e.g., "1977_alabama")}
#'   \item{state}{Character. State name in lowercase}
#'   \item{year}{Numeric. Year of observation (1977-2020)}
#'   \item{jh_tot_zero}{Numeric. Binary indicator for whether total justifiable homicides is zero}
#'   \item{FENC_pol}{Numeric. Police justifiable homicides from FENC (Felony Expanded Non-Culpable) data}
#'   \item{JH_pol}{Numeric. Police justifiable homicides from Supplementary Homicide Reports (SHR)}
#'   \item{JH_cit}{Numeric. Civilian justifiable homicides from SHR}
#'   \item{shall_issue}{Numeric. Binary indicator for Right-to-Carry (RTC) "shall issue" laws (1 = law in effect)}
#'   \item{syg_law}{Numeric. Binary indicator for Stand Your Ground (SYG) laws (1 = law in effect)}
#'   \item{SYGxRTC}{Numeric. Interaction term for states with both SYG and RTC laws active}
#'   \item{unemp_rate}{Numeric. State unemployment rate (percentage)}
#'   \item{poverty_rate}{Numeric. State poverty rate (percentage)}
#'   \item{log_police_rate}{Numeric. Natural logarithm of police per 1,000 population}
#'   \item{log_pop}{Numeric. Natural logarithm of state population}
#'   \item{pct_pop_18_24}{Numeric. Percentage of population aged 18-24}
#'   \item{pct_pop_black}{Numeric. Percentage of population that is Black}
#'   \item{pct_republican}{Numeric. Percentage of votes for Republican presidential candidate}
#'   \item{pct_state_leoka_assaults_pol1000}{Numeric. LEOKA assaults per 1,000 police officers}
#'   \item{pct_state_leoka_assaults_pop1000}{Numeric. LEOKA assaults per 1,000 population}
#' }
#'
#' **Justifiable Homicide Categories:**
#' \itemize{
#'   \item Civilian justifiable homicides: Killings by private citizens deemed legally justified
#'   \item Police justifiable homicides: Killings by law enforcement officers deemed legally justified
#'   \item FENC data provides additional police homicide information for robustness checks
#' }
#'
#' **Gun Law Variables:**
#' \itemize{
#'   \item Stand Your Ground (SYG) laws: Expand the right to use deadly force in self-defense
#'   \item Right-to-Carry (RTC) laws: Allow concealed carry of firearms with permits
#'   \item Binary indicators turn on in the year of law implementation and remain active
#' }
#'
#' **Control Variables:**
#' Economic, demographic, and political controls are included to account for
#' confounding factors that might affect both gun laws and homicide rates.
#' LEOKA (Law Enforcement Officers Killed and Assaulted) data captures police-citizen
#' interactions that may influence justifiable homicide rates.
#'
#' @source
#' \itemize{
#'   \item FBI Supplementary Homicide Reports (SHR)
#'   \item FBI Uniform Crime Reporting Program
#'   \item Bureau of Labor Statistics (unemployment)
#'   \item US Census Bureau (demographics)
#'   \item Election data for political controls
#' }
"jh"

#' City-Level Justifiable Homicide Data (1978-2020)
#'
#' A dataset containing city-level justifiable homicide counts for major US cities
#' from 1978 to 2020, used to examine gun law effects at finer geographic resolution
#' than state-level analysis.
#'
#' @format A data frame with 9,072 rows and 18 columns:
#' \describe{
#'   \item{id}{Character. Unique identifier combining year, state FIPS code, and city name}
#'   \item{year}{Numeric. Year of observation (1978-2020)}
#'   \item{address_city}{Character. City name and state abbreviation (e.g., "CAPE CORAL FL")}
#'   \item{state_name}{Character. Full state name}
#'   \item{state_fips}{Integer. Federal Information Processing Standards state code}
#'   \item{JH_city_pol}{Numeric. Police justifiable homicides in the city}
#'   \item{JH_city_cit}{Numeric. Civilian justifiable homicides in the city}
#'   \item{poverty_rate}{Numeric. City poverty rate (percentage)}
#'   \item{unemp_rate}{Numeric. City unemployment rate (percentage)}
#'   \item{pct_pop_black}{Numeric. Percentage of city population that is Black}
#'   \item{log_pop}{Numeric. Natural logarithm of city population}
#'   \item{log_police_rate}{Numeric. Natural logarithm of police per 1,000 city population}
#'   \item{pct_pop_18_24}{Numeric. Percentage of city population aged 18-24}
#'   \item{state}{Character. State name in lowercase (for merging with state-level data)}
#'   \item{pct_republican}{Numeric. Percentage of state votes for Republican presidential candidate}
#'   \item{shall_issue}{Numeric. Binary indicator for state RTC laws (1 = law in effect)}
#'   \item{syg_law}{Numeric. Binary indicator for state SYG laws (1 = law in effect)}
#'   \item{SYGxRTC}{Numeric. Interaction term for states with both SYG and RTC laws active}
#' }
#'
#' **Key Differences from State Data:**
#' \itemize{
#'   \item Starts in 1978 (one year later than state data)
#'   \item Contains only cities with sufficient reporting coverage
#'   \item Gun law variables are inherited from state-level implementation
#'   \item Some controls (like political variables) remain at state level
#' }
#'
#' **Geographic Coverage:**
#' The dataset includes major cities across all states, with varying numbers of
#' cities per state based on population and reporting consistency. This allows
#' for analysis of within-state variation in gun law effects.
#'
#' **Clustering Considerations:**
#' City-level models typically cluster standard errors at both state and city levels
#' to account for correlation within geographic units and over time.
#'
#' @source
#' \itemize{
#'   \item FBI Supplementary Homicide Reports (SHR) - City-level data
#'   \item FBI Uniform Crime Reporting Program
#'   \item American Community Survey (city demographics)
#'   \item Bureau of Labor Statistics (city unemployment)
#'   \item State-level political and law data merged from corresponding sources
#' }
"jh_city"
