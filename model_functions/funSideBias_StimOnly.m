function [negloglike, nlls, pl, V_hist, RPE] = funSideBias_StimOnly(xpar,dat)
% % funDQ_RPE % 
%PURPOSE:   Function for maximum likelihood estimation, called by fit_fun().
%
%INPUT ARGUMENTS
%   xpar:       alpha, beta, alpha2
%   dat:        data
%               dat(:,1) = choice vector
%               dat(:,2) = reward vector
%
%OUTPUT ARGUMENTS
%   negloglike:      the negative log-likelihood to be minimized
%   V_delta   :      struct for storing value estimate difference between two option, d = V_1 - V_2
%                    for Stim & Loc dimensions
%                    Stim_c & Loc_c = V_chosen - V_unchosen   
%   RPE       : RPE for each system

%% 
alpha = xpar(1);
betaDV = xpar(2);
SideBias = xpar(3);

alpha2 = xpar(4);
decay_rate = xpar(5);

nt = size(dat,1);
negloglike = 0;

vS_cir = 0.5;    % value function for shape
vS_sqr = 0.5;

V_hist.Stim1 = nan(nt,1);   % V_cir
V_hist.Stim2 = nan(nt,1);   % V_sqr
RPE.Stim = nan(nt,1);
RPE.Loc = nan(nt,1);

choice_shape = dat(:,1);
choice_location = dat(:,3);
shape_on_right = choice_shape.*choice_location;

pl = zeros(1,nt);
nlls = zeros(1,nt);

for k = 1:nt
%% Loop through trials
    % track record of all V's
    V_hist.Stim1(k) = vS_cir;
    V_hist.Stim2(k) = vS_sqr;

    
    % assign side
    switch shape_on_right(k)
        case -1
            q_right = vS_cir;
            q_left = vS_sqr;
        case 1
            q_right = vS_sqr;
            q_left = vS_cir;
    end
    
    % obtain final choice probabilities for Left and Right side
    [pleft, pright] = DecisionRuleSideBias2(SideBias,q_left,q_right,betaDV);
    pl(k) = pleft;
    
    %compare with actual choice to calculate log-likelihood
    [nlls(k), negloglike] = NegLogLike(pleft,pright,choice_location(k),negloglike);
    
    % update value for the performed action:
    % Stimuli value functions
    [vS_cir, vS_sqr, RPE.Stim(k)] = IncomeUpdateStepRates(dat(k,2),choice_shape(k),vS_cir,vS_sqr,alpha,alpha2,decay_rate);

end

end