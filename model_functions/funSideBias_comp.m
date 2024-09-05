function [negloglike, nlls, pl, V_hist, omegaVs] = funSideBias_comp(xpar,dat)
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
aRew         = xpar(1);
beta1        = xpar(2);
SideBias     = xpar(3);
aUnrew       = xpar(4);
decay_rate   = xpar(5);
omega_static = xpar(6);

nt = size(dat,1);
negloglike = 0;     
nlls = zeros(1,nt);

% choice/reward vector
choice_shape = dat(:,1);
reward = dat(:,2);
choice_location = dat(:,3);
shape_on_right = choice_shape.*choice_location;

% V = struct;     % initialie value func
% V.Right = 0.5;  % value function for location
% V.Left = 0.5;
% V.Cir = 0.5;    % value function for shape
% V.Sqr = 0.5;
vL_right = 0.5;  % value function for location
vL_left = 0.5;
vS_cir = 0.5;    % value function for shape
vS_sqr = 0.5;

% value estimates of all options
V_hist = struct;
V_hist.Stim1 = nan(1,nt);   % Q(cir)
V_hist.Stim2 = nan(1,nt);   % Q(sqr)
V_hist.Loc1 = nan(1,nt);    % Q(left)
V_hist.Loc2 = nan(1,nt);    % Q(right)
% RPE 
V_hist.RPE_stim = nan(1,nt);    % obtain V_cho = R - RPE    
V_hist.RPE_act = nan(1,nt);

% Decision value info
V_hist.DV_left = nan(1,nt); % total DV of left
V_hist.DV_right = nan(1,nt); % total DV of right
V_hist.DV_chosen = nan(1,nt); % total DV of chosen option

% quantities related to arbitration
omegaVs = omega_static*ones(1,nt);  % static omega values

% decision probs
pl = zeros(1,nt);
V_hist.pChosen = nan(1,nt); % predicted model prob. for chosen option 

for k = 1:nt
%% Loop through trials
    % track record of all V's
    V_hist.Stim1(k) = vS_cir;
    V_hist.Stim2(k) = vS_sqr;
    V_hist.Loc1(k)= vL_left;
    V_hist.Loc2(k) = vL_right;
    
    % assign side
    switch shape_on_right(k)
        case -1
            vS_right = vS_cir;
            vS_left = vS_sqr;
        case 1
            vS_right = vS_sqr;
            vS_left = vS_cir;
    end
    q_left = vS_left*omega_static + vL_left*(1 - omega_static);
    q_right = vS_right*omega_static + vL_right*(1 - omega_static);
    
    % obtain final choice probabilities for Left and Right side
    [pleft, pright] = DecisionRuleSideBias2(SideBias,q_left,q_right,beta1);
    pl(k) = pleft;
    V_hist.DV_left(k) = q_left;
    V_hist.DV_right(k) = q_right;
    
    %compare with actual choice to calculate log-likelihood
    [nlls(k), negloglike] = NegLogLike(pleft,pright,choice_location(k),negloglike);
    
    % update value for the performed action:
    % Stimuli value functions
    [vS_cir, vS_sqr, V_hist.RPE_stim(k)] = IncomeUpdateStepRates(reward(k),choice_shape(k),vS_cir,vS_sqr,aRew,aUnrew,decay_rate);
    % Location value functions
    [vL_left, vL_right, V_hist.RPE_act(k)] = IncomeUpdateStepRates(reward(k),choice_location(k),vL_left,vL_right,aRew,aUnrew,decay_rate);
end

end