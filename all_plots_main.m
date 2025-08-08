% Woo et al., 2025
% codes for plotting figures
clearvars; close all; clc
addpath(genpath(pwd));
datasets = {'Costa16','WhatWhere'};
groups.labels = ["control", "amygdala", "VS"]; 

groups.colors = {[0 0 0],[1 0 0],[0,.3,1]};
groups.colors2 = {[0.35,0.35,0.35],[1,.25,0],[0,0,0.8]};
groups.colors3 = {[0.7,0.7,0.7],[1,.5,0],[0,0,0.6]};    

schedules.subsets = ["prob8020","prob7030","prob6040"];
schedules.labels = ["80/20","70/30","60/40"];

% load processed_data
wholeBlockOutput = struct;
totBlockNum = 0;
for d = 1:numel(datasets)
    dataset_label = datasets{d};
    switch dataset_label
        case 'Costa16'
            lesion_groups = ["control", "amygdala", "VS"];  
        case 'WhatWhere'
            lesion_groups = ["control17", "control21", "amygdala", "VS"];  
    end
    % Load RT data
    fname = "output/behavior/" + dataset_label + "_wholeBlock" + "_win10.mat";
    load(fname,'all_output');
    if strcmp(dataset_label,'WhatWhere')
        all_output = rmfield(all_output,{'control17','control21'}); 
    end
    newFields = fieldnames(all_output.control);
    for g = 1:numel(groups.labels)
        for f = 1:numel(newFields)
            wholeBlockOutput.(dataset_label).(groups.labels(g)).(newFields{f}) = all_output.(groups.labels(g)).(newFields{f});
        end
        totBlockNum = totBlockNum + length(wholeBlockOutput.(dataset_label).(groups.labels(g)).subj_idx);
        disp("Total block # for this group:"+length(wholeBlockOutput.(dataset_label).(groups.labels(g)).subj_idx))
        disp(unique(wholeBlockOutput.(dataset_label).(groups.labels(g)).subj_idx));
    end
end

sem = @(x,DIM)std(x,0,DIM)./sqrt(sum(~isnan(x),DIM));
gca_fontsize = 16;
%% Fig.1. Learning curves of all groups

Fig1_pbetter_runavg;

%% Fig.2. Model fit to controls

Fig2_model_controls;

%% Fig.3. Model fit to lesioned groups

Fig3_model_lesions;

%% Fig.4. Simulation of rho and omega_0 values

Fig4_beta_rho;

%% Fig.5. Complex interaction betweeen learning & arbitraiton
% To generate the simulated data, run: sim_functions/simulatePhasePlane.m

Fig5_complex_interactions;

%% Supplementary figures

% Fig.S2. Distributions of conditional entropy of reward-dependent strategy (ERDS)
FigS2_ERDS_dist;

% Fig.S3. Interactions between stimulus-based and action-based learning
FigS3_paired_ERDS_diff;

% Fig.S4. Comparison of reliability signals, V_chosen vs. |RPE|
FigS4_reliability_comparison;

% Fig.S6. Simulated ERDS in What-only task
FigS6_simulated_two_ERDS;

% Fig.S7. Model validation for lesion groups
FigS7_model_validation;

% Fig.S8. Long-term adjustment
FigS8_long_term_adjust;


