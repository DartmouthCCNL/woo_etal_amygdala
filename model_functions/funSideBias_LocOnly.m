function [negloglike, nlls, pl, V_hist, RPE] = funSideBias_LocOnly(xpar,dat)
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

vL_right = 0.5;  % value function for location
vL_left = 0.5;

V_hist.Loc1 = nan(nt,1);    % V_left
V_hist.Loc2 = nan(nt,1);    % V_right
RPE.Stim = nan(nt,1);
RPE.Loc = nan(nt,1);

choice_shape = dat(:,1);
choice_location = dat(:,3);
% shape_on_right = choice_shape.*choice_location;

pl = zeros(1,nt);
nlls = zeros(1,nt);

for k = 1:nt
%% Loop through trials
    % track record of all V's
    V_hist.Loc1(k)= vL_left;
    V_hist.Loc2(k) = vL_right;
    
    % assign side
    q_left = vL_left;
    q_right = vL_right;
    
    % obtain final choice probabilities for Left and Right side
    [pleft, pright] = DecisionRuleSideBias2(SideBias,q_left,q_right,betaDV);
    pl(k) = pleft;
    
    %compare with actual choice to calculate log-likelihood
    [nlls(k), negloglike] = NegLogLike(pleft,pright,choice_location(k),negloglike);
    
    % update value for the performed action:
    % Location value functions
    [vL_left, vL_right, RPE.Loc(k)] = IncomeUpdateStepRates(dat(k,2),choice_location(k),vL_left,vL_right,alpha,alpha2,decay_rate);
end

end