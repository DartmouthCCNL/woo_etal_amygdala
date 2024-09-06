# Contribution of amygdala to dynamic model arbitration

## Overview
This repository contians custom MATLAB codes for generating analysis plots for the following manuscript: _Woo et al. (2024) Contribution of amygdala to dynamic model arbitration._

Requires installation of MATLAB 2021b or higher. Some functionality might not work for earlier version. The following codes have been tested in MATLAB version 2021b and 2022b. See [here](https://www.mathworks.com/help/install/install-products.html) for more instuctions on the installation.

## Directories
* _**dataset**_: contains dataset
  * **_preprocessed_**: contains demo data for control and amygdala-lesioned monkeys.
* **_figure_plotters_**: contains relevant analysis & plotting function for each figure of the manuscript. 
* **_helper_functions_**: contains anlysis helper functions.
* **_model_functions_**: contains RL model scripts for negative log-likelihood estimation (`fun*.m`) and simulation (`algo*.m`).
* **_output_**: contains output MAT files used from behavioral metrics and model fitting results
  * **_model/Costa16_**: contains output data for What-only task (Costa et al., 2016)
  * **_model/WhatWhere_**: contains output data for What/Where task (Rothenhoefer et al., 2017; Taswell et al., 2021)
    * /sessionfit: contains fitted data to each session, such as fitted parameters and log-likelihood info
    * /subjectfit: contains model estimates at the subject-level, used to estimate the rho parameter that measures overall ratio of sensitivity to stimulus-based and action-based learning signals
    * /trajectory_data: contains trajectories of various model-estimates, including effective arbitration weight (\Omega), effective arbitration rates (\psi+ and \psi-)
  * **_model/Combined_**: output data with information from all two tasks combined, used for plotting figures.
* **_sim_functions_**: contain codes for model simulations.
     
## Demo
To reproduce the main analysis figures, clone the repo and run `all_plots_main.m` in the root directory. This loads the saved output files from the directory.

### Data format
Information about a given block is contained in the MATLAB structure named `block_stats`, with the following fields:
* **prob####**: set to `[1; 1]` if the given block has the reward schedule ##/##, and `[0; 0]` otherwise. Indexes acquisiton and reversal phase separately, but note that two are identical within a block.
* **what**: set to `1` if the given block is a What block, `0` otherwise.
* **where**: set to `1` if the given block is a Where block, `0` otherwise.
* **animal_ids**: unique identifier for the monkey that performed the given block.
* **session_date**: Date when the block was performed.
* **session_idx**: Indexes sessions with respect to total session number from all monkeys.
* **r**: array of rewards collected, `1` if rewarded for the trial and `0` if unrewarded.
* **c**: array of chosen stimulus identity, set to `-1` if stimulus A was chosen and `1` if stimulus B was chosen.
* **cloc**: array of chosen action location, set to `-1` if leftward and `1` if rightward saccade was made.
* **block_indices**: cell array containining indices of trials belonging to acquisiton or reversal phase respectively.
* **block_addresses**: 1-by-3 array containing trial indices for start of the block, reversal trial, and end of the block.
* **rewardprob**: contains reward schedule across trials for the correct dimension, i.e., for left/right in Where block or A/B for What block.
* **hr_side**: indicates whether left (-1) or right (1) side was a better rewarding option across trials.
* **hr_shape**: indicates whether stimulus A (-1) or B (1) was a better rewarding option across trials.
* **RT**: contains reaction time for each trial.
   
