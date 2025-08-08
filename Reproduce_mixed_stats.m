%%% Reproduce mixed-effects model results 
% reported in Supplementary Table 3
clearvars; clc;

% load block-wise (or session-wise more model params) data table
load("dataset/Regression_BlockData.mat",'BlockData');

% obtain session-wise data (which are repeated for blocks in a given session)
SessionData = BlockData(BlockData.block_in_sess_ID==1,:);

head(BlockData,30); % example first 30 rows

%% Table 3.1 Comparison of performance of three groups in What-only task
D = BlockData(BlockData.task=="Costa16",:);    % all What-only data

mod_Eq = "pbetter ~ group + (1 + sess_perc + block_in_sess |subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

% planned  contrast: differenc in performance, amyg - VS
C = [0 1 -1]; % contrast weights for amyg - VS
stats = run_contrast(mdl, C);
disp("b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.2 Comparison of performance of three groups in What/Where task
D = BlockData(BlockData.task=="WhatWhere",:);    % What/Where task data

mod_Eq = "pbetter ~  group * blockType + (1 + blockType + sess_perc + block_in_sess|subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

% contrast: amyg - VS
cont_opt = 3;
switch cont_opt
    case 1  
        C = [0 1 -1 0 0 0];  % amyg - VS during What
    case 2
        C = [0 1 -1 0 1 -1]; % amyg - VS during Where    
    case 3
        C = [0 1 0 0 1 0]; % amyg - Cont during Where
    case 4
        C = [0 0 1 0 0 1]; % VS - Cont during Where
end
stats = run_contrast(mdl, C);
disp("Contrast: b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.3 Comparison of effective arbitration rates (Δ𝜓 = 𝜓+ − 𝜓−) in three groups during What-only task
D = BlockData(BlockData.task=="Costa16",:); % all What-only data
D.deltaPsi = D.Psi_plus - D.Psi_minus;

mod_Eq = "deltaPsi ~ group + (1 + sess_perc + block_in_sess |subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

% contrasts: mean of lesioned groups
cont_opt = 3;
switch cont_opt
    case 1
        C = [1 1 0]; % amyg mean
    case 2
        C = [1 0 1]; % VS mean
    case 3
        C = [0 1 -1]; % amyg - VS
end
stats = run_contrast(mdl, C);
disp("Lesion contrast: b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.4 Comparison of effective arbitration rates in three groups during What/Where task
D = BlockData(BlockData.task=="WhatWhere",:); % all What/Where data
D.deltaPsi = D.Psi_plus - D.Psi_minus;

mod_Eq = "deltaPsi ~ group*blockType + (1 + blockType + sess_perc + block_in_sess|subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

for cont_opt = 1:5
    switch cont_opt
        case 1
            C = [1 0 0 1 0 0];  % mean of Controls, Where 
        case 2
            C = [1 1 0 0 0 0];  % mean of Amyg, What
        case 3
            C = [1 1 0 1 1 0];  % mean of Amyg, Where         
        case 4
            C = [1 0 1 0 0 0];  % mean of What block (VS)
        case 5
            C = [1 0 1 1 0 1];  % mean of Where block (VS)  
        case 6            
            C = [0 1 0 0 1 0];  % diff b/w Control & Amyg in Where 
    end
    stats = run_contrast(mdl, C);
    disp(cont_opt+". Contrast b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);
end

%% Table 3.5 Comparison of differentiation in two arbitration rates between groups during What/Where task
D = BlockData(BlockData.task=="WhatWhere",:); % all What/Where data
D.AbsDeltaPsi = abs(D.Psi_plus - D.Psi_minus);

mod_Eq = "AbsDeltaPsi ~ group + (1 + sess_perc + block_in_sess|subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

% contrast
C = [0 1 -1];   % Amyg - VS
stats = run_contrast(mdl, C);
disp("Lesion contrast: b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.6 Comparison of relative sensitivity to stimulus and action value signals (Δ𝛽 = 𝛽stim – 𝛽action) bewteen groups during What-only task
D = SessionData(SessionData.task=="Costa16",:); % What-only task data
D.deltaBeta = D.Beta_Stim - D.Beta_Act;

mod_Eq = "deltaBeta ~ group + (1 + sess_perc|subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

cont_opt = 1;
switch cont_opt
    case 1
        C = [0 1 -1]; % amyg - VS
    case 2
        C = [1 1 0]; % mean of amyg
    case 3
        C = [1 0 1]; % mean of VS    
end
stats = run_contrast(mdl, C);
disp("Contrast b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.7 Comparison of relative senstivity to stimulus and action value signals (Δ𝛽 = 𝛽stim – 𝛽action) bewteen groups during What/Where task
D = SessionData(SessionData.task=="WhatWhere",:); % What/Where task data
D.deltaBeta = D.Beta_Stim - D.Beta_Act;

mod_Eq = "deltaBeta ~ group + (1 + sess_perc |subject)";
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

cont_opt = 1;
switch cont_opt
    case 1
        C = [0 1 -1]; % amyg - VS
    case 2
        C = [1 1 0]; % mean of amyg
    case 3
        C = [1 0 1]; % mean of VS    
end
stats = run_contrast(mdl, C);
disp("Contrast b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.8-10 Comparison of initial effective arbitration weight bewteen groups during What/Where task
D = SessionData(SessionData.task=="WhatWhere",:);
D.deltaOm = D.Omega_0 - D.omega_0;

y_opt = 8;
switch y_opt
    case 8       % initial effective arbitration weight
        mod_Eq = "Omega_0 ~ group + (1+sess_perc|subject)";          
    case 9       % initial baseline arbitration weight
        mod_Eq = "omega_0 ~ group + (1+sess_perc|subject)";           
    case 10       % testing group effect on paired difference
        mod_Eq = "deltaOm ~ group + (1+sess_perc|subject)";
end
mdl = fitlme(D, mod_Eq); 
disp(mdl); 

% contrast analysis:
C = [0 1 -1];   % Amyg - VS
stats = run_contrast(mdl, C);
disp("Amyg - VS contrast: b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);

%% Table 3.11-14 Long-term adjustment during What-only task
D = BlockData(BlockData.task=="Costa16",:);    % all What-only data

y_opt = 4;

switch y_opt
    case 1       
        mod_Eq = "ERDS_Stim ~ group*sess_perc + (1 + sess_perc + block_in_sess|subject)"; % ERDS_stimulus (Fig.S8a)
    case 2      
        mod_Eq = "ERDS_Act ~ group*sess_perc + (1 + sess_perc + block_in_sess|subject)";  % ERDS_Action (Fig.S8b)
    case 3             
        mod_Eq = "medianRT ~ group*sess_perc + (1 + sess_perc + block_in_sess|subject)";  % median RT (Fig.S8c)  
    case 4       
        D = SessionData(SessionData.task=="Costa16",:); % use session data
        mod_Eq = "Omega_0 ~ group*sess_perc + (1 + sess_perc|subject)";   % Omega_0 (Fig.S8d)
end

mdl = fitlme(D, mod_Eq); 
disp(mdl); 

%%% planned contrasts:
for cont_opt = 1:3
    switch cont_opt    
        case 1
            C = [0 0 0 1 1 0];   % slope for Amyg
        case 2
            C = [0 0 0 1 0 1];   % slope for VS
        case 3
            C = [0 0 0 0 1 -1];  % Amyg - VS diff        
    end
    stats = run_contrast(mdl, C, 0);
    disp(cont_opt+". Contrast: b = "+stats.b+", SE = "+stats.SE+", t("+stats.DF+") = "+stats.tstat+", p = "+stats.pval);
    % fprintf('%f \b %f \b %f \b %d \b %f\n',[stats.b, stats.SE, stats.tstat stats.DF stats.pval])
end
