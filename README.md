# Category Phi

**Hurricane Risk and Optimal Savings in a Caribbean Regional DICE Model**

This repository contains the code used for my MSc dissertation, *Category Phi: Hurricane Risk and Optimal Savings in a Caribbean Regional DICE Model*.

The project extends DICE-2016R to a regional Caribbean setting using the Rest of Central America (RCAm) calibration from RICE50+. It introduces annual stochastic hurricane risk calibrated using Jamaican hurricane exposure and Atlantic hurricane data, before examining how hurricane risk affects regional savings decisions using a Bellman framework.

## Model Workflow

The model is run sequentially from Step A to Step F.

### `STEP_A.m`
Runs the global DICE-2016R model and generates the fixed global temperature, emissions-control and economic pathways used by the regional model.

### `STEP_B.R`
Extracts and validates the RCAm regional calibration from RICE50+ data. It constructs the regional SSP2 baseline and exports:

- `RCAm_SSP2_baseline.csv`
- `RCAm_fixed_parameters.csv`

The original RICE50+ source workbooks used to construct these files are not included in this repository.

### `STEP_C.m`
Constructs the annual deterministic RCAm economy conditioned on the fixed DICE-2016R climate pathway. It applies regional temperature impacts and determines the regional savings pathway used as the deterministic benchmark.

### `STEP_D.m`
Calibrates the hurricane process using the HURDAT2 Atlantic hurricane database and Jamaican hurricane exposure. It estimates hurricane frequency, category probabilities and category-specific output-equivalent losses.

### `STEP_E.m`
Introduces annual stochastic hurricanes into the RCAm economy. Monte Carlo simulations generate distributions of regional output, capital, consumption and hurricane losses while holding the Step C savings pathway fixed.

### `STEP_F.m`
Solves the annual Bellman savings problem. It compares:

1. the fixed Step C savings pathway;
2. an annual feedback savings policy without hurricane anticipation; and
3. a hurricane-risk-aware annual feedback policy.

The policies are evaluated using separate hurricane histories to examine savings, lower-tail economic outcomes and welfare.

## Supporting Files

The following files support the DICE-2016R implementation:

- `sub_parameters.m`
- `sub_loadguesses.m`
- `utilityobjective.m`
- `nonlcon_utilmax.m`
- `trajectory.m`
- `OutputResults.m`

The hurricane calibration uses:

- `hurdat2-1851-2025-02272026.txt`

## Running the Model

Run the files in the following order:

```text
STEP_A.m
STEP_B.R
STEP_C.m
STEP_D.m
STEP_E.m
STEP_F.m
