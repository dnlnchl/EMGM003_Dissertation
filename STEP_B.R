# ============================================================================
# STEP B: RCAm REGIONAL CALIBRATION FROM RICE50+
# ============================================================================
#
# This script extracts the RCAm regional socioeconomic and climate parameters,
# constructs the five-year SSP2 no-damage economic baseline, validates the
# calibration and exports the inputs required by subsequent MATLAB steps.

library(readxl)
library(dplyr)

project_folder <- file.path(Sys.getenv("USERPROFILE"),
                            "OneDrive", "Documents", "University of Exeter",
                            "Term 2", "EMGM003 - Dissertation", "scripts")

data_folder <- file.path(project_folder, "data_ed58")


# ======================= CARBON INTENSITY =======================

ssp_ci <- read_excel(file.path(data_folder, "data_baseline_ssp_cixlsx.xlsx"),
                     col_names = FALSE)

names(ssp_ci) <- c("ssp", "t", "region", "gas", "value")

# Carbon intensity is measured in kgCO2 per 2005 USD.
rcam_ci <- ssp_ci %>% filter(ssp == "SSP2", region == "rcam", gas == "co2") %>%
                      mutate(t = as.numeric(t),
                             carbon_intensity = as.numeric(value),
                             year = 2015 + 5 * (t - 1)) %>%
                      select(t, year, carbon_intensity) %>%
                      arrange(year)

rcam_ci

# ======================= POPULATION =======================

ssp_l <- read_excel(file.path(data_folder, "data_baseline_ssp_l.xlsx"),
                    col_names = FALSE)

names(ssp_l) <- c("ssp", "t", "region", "population")

# Population is measured in millions of people.
rcam_population <- ssp_l %>% filter(ssp == "SSP2", region == "rcam") %>%
                             mutate(t = as.numeric(t),
                                   population = as.numeric(population),
                                   year = 2015 + 5 * (t - 1)) %>%
                             select(t, year, population) %>%
                             arrange(year)

rcam_population


# ======================= RCAm BASELINE GDP PATHWAY =======================

ssp_ykali <- read_excel(file.path(data_folder, "data_baseline_ssp_ykali.xlsx"),
                        col_names = FALSE)

names(ssp_ykali) <- c("ssp", "t", "region", "ykali")

# ykali is baseline GDP used for dynamic calibration.
# Units are trillions of 2005 USD per year.

rcam_ykali <- ssp_ykali %>% filter(ssp == "SSP2", region == "rcam") %>%
                            mutate(t = as.numeric(t),
                                   ykali = as.numeric(ykali),
                                   year = 2015 + 5 * (t - 1)) %>%
                            select(t, year, ykali) %>%
                            arrange(year)

rcam_ykali


# ======================= REGIONAL CLIMATE COEFFICIENTS =======================

climate_coef <- read_excel(file.path(data_folder,
                                     "data_mod_climate_regional_export.xlsx"),
                           col_names = FALSE)

names(climate_coef) <- c("coefficient", "region", "value")

rcam_climate_coef <- climate_coef %>% filter(region == "rcam") %>%
                                      mutate(value = as.numeric(value))

rcam_climate_coef

#extracting the parameters from the table, for the damage function 

#alpha
rcam_alpha_temp <- rcam_climate_coef %>% filter(coefficient == "alpha_temp") %>%
                                         pull(value)
rcam_alpha_temp

#beta
rcam_beta_temp <- rcam_climate_coef %>% filter(coefficient == "beta_temp") %>%
                                        pull(value)
rcam_beta_temp

#baseline
rcam_base_temp <- rcam_climate_coef %>% filter(coefficient == "base_temp") %>%
                                        pull(value)
rcam_base_temp

#r-squared
rcam_r2_temp <- rcam_climate_coef %>% filter(coefficient == "r2_temp") %>%
                                      pull(value)
rcam_r2_temp



# ======================= INITIAL CAPITAL =======================

k_valid_article <- read_excel(file.path(data_folder, "k_valid_article.xlsx"),
                              col_names = FALSE)

names(k_valid_article) <- c("capital_type", "t", "region", "capital")

rcam_capital <- k_valid_article %>% filter(capital_type == "fg",
                                           region == "rcam") %>%
                                    mutate(t = as.numeric(t),
                                           capital = as.numeric(capital),
                                           year = 2015 + 5 * (t - 1)) %>%
                                    select(t, year, capital) %>%
                                    arrange(year)

rcam_capital


# Extract the first-period capital stock.
rcam_initial_capital <- rcam_capital %>% 
  arrange(year) %>% 
  slice(1) %>% 
  pull(capital)
rcam_initial_capital


# ======================= SOCIOECONOMIC DATASET =======================

socecon_valid_weo_mean <- read_excel(file.path(data_folder,
                                               "socecon_valid_weo_mean.xlsx"),
                                     col_names = FALSE)

names(socecon_valid_weo_mean) <- c("indicator", "t", "region", "value")

rcam_socecon <- socecon_valid_weo_mean %>% filter(region == "rcam")
rcam_socecon



# ======================= RCAm SAVINGS RATES =======================

rcam_savings <- socecon_valid_weo_mean %>% filter(indicator == "savings_rate", region == "rcam") %>%
                                           mutate(t = as.numeric(t),
                                                 savings_rate_raw = as.numeric(value),
                                                 savings_rate = savings_rate_raw / 100,
                                                 year = 2015 + 5 * (t - 1)) %>%
                                           select(t, year, savings_rate_raw, savings_rate) %>%
                                           arrange(year)

rcam_savings

#quick sanity check to ensure that savings rate is a percentage
range(rcam_savings$savings_rate_raw, na.rm = TRUE)
range(rcam_savings$savings_rate, na.rm = TRUE)


### RCAm INITIAL SAVINGS RATE ###


# The source model uses the first-period regional savings rate.
rcam_initial_savings_raw <- rcam_savings %>% filter(t == 1) %>%
                                             pull(savings_rate_raw)

# The original model sets values below 1% to 1%.
rcam_initial_savings <- max(rcam_initial_savings_raw, 1) / 100

rcam_initial_savings


# ======================= REGIONAL LABOUR AND CAPITAL SHARES =======================

labour_share <- read_excel(file.path(data_folder, "labour_share.xlsx"),
                           col_names = FALSE)

names(labour_share) <- c("region", "labour_share")

rcam_labour_share <- labour_share %>% filter(region == "rcam") %>%
                                      mutate(labour_share = as.numeric(labour_share))

rcam_labour_share

# Store the raw regional labour-share.
rcam_labour_share_raw <- rcam_labour_share %>% pull(labour_share)

# The regional production function retains the DICE-2016R factor shares
# to maintain structural consistency with the global model.
rcam_labour_share_value <- 0.70
rcam_capital_share_value <- 0.30



# ======================= PPP-TO-MER CONVERSION PARAMETER =======================

ppp2mer <- read_excel(file.path(data_folder, "ppp2mer.xlsx"),
                      col_names = FALSE)

names(ppp2mer) <- c("region", "ppp2mer")

rcam_ppp2mer <- ppp2mer %>% filter(region == "rcam") %>%
                            mutate(ppp2mer = as.numeric(ppp2mer))

rcam_ppp2mer


rcam_ppp2mer_value <- rcam_ppp2mer %>% pull(ppp2mer)

# ppp2mer converts PPP values to MER values.
# Therefore, MER-to-PPP is the inverse.
rcam_mer2ppp_value <- 1 / rcam_ppp2mer_value

rcam_ppp2mer_value
rcam_mer2ppp_value


# ======================= CONVERT GDP AND CAPITAL INTO PPP VALUES =======================

rcam_ykali <- rcam_ykali %>% mutate(ykali_ppp = ykali * rcam_mer2ppp_value)

rcam_initial_capital_ppp <- rcam_initial_capital * rcam_mer2ppp_value

rcam_ykali
rcam_initial_capital_ppp



# ======================= GENERATE THE RCAm FIXED SAVINGS-RATE PATHWAY =======================

#Economic parameters used by the source model.
dk_rcam <- 0.10
elasmu_rcam <- 1.45
prstp_rcam <- 0.015
timestep_rcam <- 5

#Analytical long-run savings rate.
rcam_optimal_long_run_savings <- ((dk_rcam + 0.004) /
                                  (dk_rcam + 0.004 * elasmu_rcam + prstp_rcam)) *
                                  rcam_capital_share_value

rcam_optimal_long_run_savings

number_of_periods <- nrow(rcam_ykali)

# Linear convergence from the initial savings rate to the long-run rate.
rcam_fixed_savings <- rcam_ykali %>% select(t, year) %>%
                                     arrange(year) %>%
                                     mutate(period = row_number(),
                                           savings_rate = rcam_initial_savings +
                                             (rcam_optimal_long_run_savings -
                                                rcam_initial_savings) *
                                             ((period - 1) /
                                                (number_of_periods - 1))) %>%
                                     select(t, year, savings_rate)

rcam_fixed_savings

range(rcam_fixed_savings$savings_rate)



# ======================= COMBINE THE RCAm BASELINE DATA =======================
rcam_baseline <- rcam_ykali %>% select(t, year, ykali, ykali_ppp) %>%
                                left_join(rcam_population %>%
                                            select(year, population),
                                          by = "year") %>%
                                left_join(rcam_ci %>%
                                            select(year, carbon_intensity),
                                          by = "year") %>%
                                left_join(rcam_fixed_savings %>%
                                            select(year, savings_rate),
                                          by = "year") %>%
                                arrange(year)

rcam_baseline


# ======================= DYNAMIC INVESTMENT AND CAPITAL CALIBRATION =======================

# Baseline investment in trillions of 2005 PPP USD per year.
rcam_baseline$investment <- rcam_baseline$savings_rate * rcam_baseline$ykali_ppp

# Create the capital pathway.
rcam_baseline$capital <- NA_real_
rcam_baseline$capital[1] <- rcam_initial_capital_ppp

# K(t+1) = (1-dk)^dt K(t) + dt I(t)
for (i in 1:(number_of_periods - 1)) {
        rcam_baseline$capital[i + 1] <- ((1 - dk_rcam)^timestep_rcam *
                                           rcam_baseline$capital[i]) +
                                        (timestep_rcam * 
                                           rcam_baseline$investment[i])
      }

rcam_baseline %>% select(year, ykali_ppp, savings_rate, investment, capital)


# ======================= TOTAL FACTOR PRODUCTIVITY =======================

rcam_baseline <- rcam_baseline %>% mutate(tfp = ykali_ppp / 
                                            ((population / 1000)^rcam_labour_share_value *
                                               capital^rcam_capital_share_value))

# The source model gives the final period the previous period's TFP.
rcam_baseline$tfp[number_of_periods] <- rcam_baseline$tfp[number_of_periods - 1]

rcam_baseline %>% select(year, ykali_ppp, population, capital, tfp)


# ======================= CONSUMPTION, PER-CAPITA VALUES AND BASELINE EMISSIONS =======================

rcam_baseline <- rcam_baseline %>% 
  mutate(consumption = ykali_ppp - investment,
         gdp_per_capita = ykali_ppp / population * 1e6,
         consumption_per_capita = consumption / population * 1e6,
         # FIX: Use MER GDP for physical emission scaling
         baseline_co2_emissions = carbon_intensity * ykali)


# ======================= QUICK SANITY CHECKS =======================

# Check for duplicated years.
anyDuplicated(rcam_baseline$year)

# Count missing values in each column.
colSums(is.na(rcam_baseline))

# Check the baseline year range and time spacing.
range(rcam_baseline$year)
unique(diff(rcam_baseline$year))

# Check the main variable ranges.
range(rcam_baseline$savings_rate)
range(rcam_baseline$investment)
range(rcam_baseline$capital) #Why is this NA, oh because we only have intiial capital
range(rcam_baseline$tfp)
range(rcam_baseline$consumption)
range(rcam_baseline$gdp_per_capita)
range(rcam_baseline$consumption_per_capita)
range(rcam_baseline$baseline_co2_emissions)

head(rcam_baseline)
tail(rcam_baseline)


# ======================= STORE THE FIXED RCAm PARAMETERS =======================

rcam_parameters <- list(initial_capital_raw = rcam_initial_capital,
                        initial_capital_ppp = rcam_initial_capital_ppp,
                        initial_savings = rcam_initial_savings,
                        optimal_long_run_savings = rcam_optimal_long_run_savings,
                        labour_share = rcam_labour_share_value,
                        capital_share = rcam_capital_share_value,
                        depreciation_rate = dk_rcam,
                        elasticity_marginal_utility = elasmu_rcam,
                        pure_rate_time_preference = prstp_rcam,
                        timestep = timestep_rcam,
                        alpha_temp = rcam_alpha_temp,
                        beta_temp = rcam_beta_temp,
                        base_temp = rcam_base_temp,
                        r2_temp = rcam_r2_temp,
                        ppp2mer = rcam_ppp2mer_value,
                        mer2ppp = rcam_mer2ppp_value)

rcam_parameters


# ======================= FIXED-PARAMETER TABLE =======================

rcam_parameters_df <- data.frame(
  parameter = c("initial_capital_raw", "initial_capital_ppp",
                "initial_savings", "optimal_long_run_savings",
                "labour_share", "capital_share",
                "depreciation_rate", "elasticity_marginal_utility",
                "pure_rate_time_preference", "timestep",
                "alpha_temp", "beta_temp", "base_temp", "r2_temp",
                "ppp2mer", "mer2ppp"),
  
  value = c(rcam_initial_capital, rcam_initial_capital_ppp,
            rcam_initial_savings, rcam_optimal_long_run_savings,
            rcam_labour_share_value, rcam_capital_share_value,
            dk_rcam, elasmu_rcam, prstp_rcam,
            timestep_rcam, rcam_alpha_temp, rcam_beta_temp,
            rcam_base_temp, rcam_r2_temp,
            rcam_ppp2mer_value, rcam_mer2ppp_value)
)


# ======================= EXPORT THE CSV FILES =======================

baseline_file <- file.path(project_folder, "RCAm_SSP2_baseline.csv")
parameters_file <- file.path(project_folder, "RCAm_fixed_parameters.csv")

write.csv(rcam_baseline, baseline_file, row.names = FALSE, na = "")
write.csv(rcam_parameters_df, parameters_file, row.names = FALSE, na = "")

# ============================================================
# DETAILED RCAm CALIBRATION CHECKS
# ============================================================

# [still not sure if this is important enough to include in the actual diss]

cat("\n===== 1. STRUCTURAL CHECKS =====\n")

cat("Number of periods:", nrow(rcam_baseline), "\n")
cat("First year:", min(rcam_baseline$year), "\n")
cat("Last year:", max(rcam_baseline$year), "\n")
cat("Duplicated years:", anyDuplicated(rcam_baseline$year), "\n")
cat("Year intervals:", unique(diff(rcam_baseline$year)), "\n")

cat("\nMissing values by variable:\n")
print(colSums(is.na(rcam_baseline)))


# ============================================================
# SAVINGS-RATE CHECKS
# ============================================================

cat("\n===== 2. SAVINGS-RATE CHECKS =====\n")

cat("Initial savings rate:", rcam_initial_savings, "\n")
cat("Calculated long-run savings rate:", rcam_optimal_long_run_savings, "\n")
cat("First pathway value:", rcam_fixed_savings$savings_rate[1], "\n")
cat("Final pathway value:", tail(rcam_fixed_savings$savings_rate, 1), "\n")

savings_initial_error <- abs(rcam_fixed_savings$savings_rate[1] -
                               rcam_initial_savings)

savings_final_error <- abs(tail(rcam_fixed_savings$savings_rate, 1) -
                             rcam_optimal_long_run_savings)

cat("Initial savings-rate error:", savings_initial_error, "\n")
cat("Final savings-rate error:", savings_final_error, "\n")
cat("Savings pathway always between 0 and 1:",
    all(rcam_fixed_savings$savings_rate >= 0 &
          rcam_fixed_savings$savings_rate <= 1), "\n")


# ============================================================
# ACCOUNTING-IDENTITY CHECKS
# ============================================================

cat("\n===== 3. ACCOUNTING-IDENTITY CHECKS =====\n")

# Investment should equal savings rate multiplied by GDP.
investment_error <- max(abs(rcam_baseline$investment -
                              rcam_baseline$savings_rate *
                              rcam_baseline$ykali_ppp))

# Consumption plus investment should equal baseline GDP.
output_identity_error <- max(abs(rcam_baseline$consumption +
                                   rcam_baseline$investment -
                                   rcam_baseline$ykali_ppp))

cat("Maximum investment-equation error:", investment_error, "\n")
cat("Maximum output-accounting error:", output_identity_error, "\n")


# ============================================================
# CAPITAL-TRANSITION CHECK
# ============================================================

cat("\n===== 4. CAPITAL-TRANSITION CHECK =====\n")

capital_expected <- ((1 - dk_rcam)^timestep_rcam *
                       rcam_baseline$capital[1:(number_of_periods - 1)]) +
  (timestep_rcam *
     rcam_baseline$investment[1:(number_of_periods - 1)])

capital_actual <- rcam_baseline$capital[2:number_of_periods]

capital_transition_error <- max(abs(capital_actual - capital_expected))

cat("Maximum capital-transition error:", capital_transition_error, "\n")


# ============================================================
# COBB-DOUGLAS / TFP CHECK
# ============================================================

cat("\n===== 5. COBB-DOUGLAS RECONSTRUCTION CHECK =====\n")

gdp_reconstructed <- rcam_baseline$tfp *
  (rcam_baseline$population / 1000)^rcam_labour_share_value *
  rcam_baseline$capital^rcam_capital_share_value

# Exclude the final period because the source model copies the previous
# period's TFP into the last period.
gdp_reconstruction_error <- max(abs(
  gdp_reconstructed[1:(number_of_periods - 1)] -
    rcam_baseline$ykali_ppp[1:(number_of_periods - 1)]
))

gdp_reconstruction_error_pct <- max(abs(
  (gdp_reconstructed[1:(number_of_periods - 1)] -
     rcam_baseline$ykali_ppp[1:(number_of_periods - 1)]) /
    rcam_baseline$ykali_ppp[1:(number_of_periods - 1)] * 100
))

cat("Maximum GDP reconstruction error:", gdp_reconstruction_error, "\n")
cat("Maximum GDP reconstruction error (%):",
    gdp_reconstruction_error_pct, "\n")


# ============================================================
# PPP-CONVERSION CHECKS
# ============================================================

cat("\n===== 6. PPP-CONVERSION CHECKS =====\n")

gdp_ppp_error <- max(abs(rcam_ykali$ykali_ppp -
                           rcam_ykali$ykali * rcam_mer2ppp_value))

capital_ppp_error <- abs(rcam_initial_capital_ppp -
                           rcam_initial_capital * rcam_mer2ppp_value)

cat("GDP PPP-conversion error:", gdp_ppp_error, "\n")
cat("Capital PPP-conversion error:", capital_ppp_error, "\n")
cat("PPP-to-MER factor:", rcam_ppp2mer_value, "\n")
cat("MER-to-PPP factor:", rcam_mer2ppp_value, "\n")
cat("Product of conversion factors:",
    rcam_ppp2mer_value * rcam_mer2ppp_value, "\n")


# ============================================================
# POSITIVITY AND FINITE-VALUE CHECKS
# ============================================================

cat("\n===== 7. POSITIVITY AND FINITE-VALUE CHECKS =====\n")

numeric_variables <- rcam_baseline %>%
  select(ykali_ppp, population, carbon_intensity, savings_rate,
         investment, capital, tfp, consumption,
         gdp_per_capita, consumption_per_capita,
         baseline_co2_emissions)

cat("All values finite:",
    all(sapply(numeric_variables, function(x) all(is.finite(x)))), "\n")

cat("All GDP values positive:", all(rcam_baseline$ykali_ppp > 0), "\n")
cat("All population values positive:", all(rcam_baseline$population > 0), "\n")
cat("All capital values positive:", all(rcam_baseline$capital > 0), "\n")
cat("All TFP values positive:", all(rcam_baseline$tfp > 0), "\n")
cat("All consumption values positive:", all(rcam_baseline$consumption > 0), "\n")
cat("All emissions values non-negative:",
    all(rcam_baseline$baseline_co2_emissions >= 0), "\n")


# ============================================================
# VARIABLE RANGES
# ============================================================

cat("\n===== 8. VARIABLE RANGES =====\n")

check_ranges <- data.frame(
  variable = c("GDP", "Population", "Savings rate", "Investment",
               "Capital", "TFP", "Consumption", "GDP per capita",
               "Consumption per capita", "CO2 emissions"),
  minimum = c(min(rcam_baseline$ykali_ppp),
              min(rcam_baseline$population),
              min(rcam_baseline$savings_rate),
              min(rcam_baseline$investment),
              min(rcam_baseline$capital),
              min(rcam_baseline$tfp),
              min(rcam_baseline$consumption),
              min(rcam_baseline$gdp_per_capita),
              min(rcam_baseline$consumption_per_capita),
              min(rcam_baseline$baseline_co2_emissions)),
  maximum = c(max(rcam_baseline$ykali_ppp),
              max(rcam_baseline$population),
              max(rcam_baseline$savings_rate),
              max(rcam_baseline$investment),
              max(rcam_baseline$capital),
              max(rcam_baseline$tfp),
              max(rcam_baseline$consumption),
              max(rcam_baseline$gdp_per_capita),
              max(rcam_baseline$consumption_per_capita),
              max(rcam_baseline$baseline_co2_emissions))
)

print(check_ranges)


# ============================================================
# FINAL PASS / FAIL SUMMARY
# ============================================================

cat("\n===== 9. FINAL CHECK SUMMARY =====\n")

checks_passed <- data.frame(
  check = c("No duplicated years",
            "No missing values",
            "Five-year intervals",
            "Savings starts correctly",
            "Savings ends correctly",
            "Investment identity",
            "Output identity",
            "Capital transition",
            "GDP reconstructed from TFP",
            "PPP conversion",
            "All values finite",
            "Positive GDP",
            "Positive capital",
            "Positive consumption"),
  passed = c(anyDuplicated(rcam_baseline$year) == 0,
             all(colSums(is.na(rcam_baseline)) == 0),
             identical(unique(diff(rcam_baseline$year)), 5),
             savings_initial_error < 1e-10,
             savings_final_error < 1e-10,
             investment_error < 1e-10,
             output_identity_error < 1e-10,
             capital_transition_error < 1e-10,
             gdp_reconstruction_error < 1e-10,
             gdp_ppp_error < 1e-10 && capital_ppp_error < 1e-10,
             all(sapply(numeric_variables, function(x) all(is.finite(x)))),
             all(rcam_baseline$ykali_ppp > 0),
             all(rcam_baseline$capital > 0),
             all(rcam_baseline$consumption > 0))
)

print(checks_passed)

cat("\nNumber of checks passed:",
    sum(checks_passed$passed), "of", nrow(checks_passed), "\n")
