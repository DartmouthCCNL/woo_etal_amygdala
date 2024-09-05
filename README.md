# Contribution of amygdala to dynamic model arbitration

## Overview
This repository contians custom MATLAB codes for generating analysis plots for the following manuscript: _Woo et al. (2024) Contribution of amygdala to dynamic model arbitration._

Requires installation of [MATLAB](https://www.mathworks.com/downloads/) 2021b or higher. Some functionality might not work for earlier version. The following codes have been tested in MATLAB version 2021b and 2022b.

## Directories
* **_figure_plotters_**: contains plotting function for each figure.
* **_helper_functions_**: contains anlysis helper functions.
* **_model_functions_**: contains RL model scripts for negative log-likelihood estimation
* **_output_**: contains output MAT files used from behavioral metrics and model fitting results
  * **_model/Costa16_**: contains output data for What-only task (Costa et al., 2016)
  * **_model/WhatWhere_**: contains output data for What/Where task (Rothenhoefer et al., 2017; Taswell et al., 2021)

## Demo
To reproduce the main analysis figures, clone the repo and run `all_plots_main.m` in the root directory.
