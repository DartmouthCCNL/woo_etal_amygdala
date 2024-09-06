function stats_sim = algo_SideBias_StimOnly(stats_sim,xpar)
% % funDQ_RPE % 
%PURPOSE:   Function for maximum likelihood estimation, called by fit_fun().
%
%INPUT ARGUMENTS
%   stats:  stats of the game thus far
%   params: parameters that define the player's strategy
%
%OUTPUT ARGUMENTS
%   stats:  updated with player's probability to choose left for next step

%% 
aRew        = xpar(1);
beta_DV     = xpar(2);
SideBiasR   = xpar(3);    % side bias toward right option
aUnrew      = xpar(4);
decay_rate  = xpar(5);

%% Simulate trials

T = stats_sim.currTrial;
if stats_sim.currTrial == 1  %if this is the first trial, initialize
    stats_sim.q1(T) = 0.5;      % V_cir
    stats_sim.q2(T) = 0.5;      % V_sqr
    
    stats_sim.RPE.Stim(T) = NaN; 
    
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR)));      % p(choose Left)
else
    % Update action values (reward from previous trial)
    % Update V_Stimuli
    [stats_sim.q1(T), stats_sim.q2(T), RPE_Stim] = IncomeUpdateStepRates(stats_sim.r(T-1),stats_sim.c(T-1), stats_sim.q1(T-1),stats_sim.q2(T-1),aRew,aUnrew,decay_rate);
    stats_sim.RPE.Stim(T-1,1) = RPE_Stim;
    
    % softmax rule for action selection
    % assign sides
    switch stats_sim.shape_on_right(T)
        case -1
            DV_right = stats_sim.q1(T);  % if Cir is on the right
            DV_left = stats_sim.q2(T);
        case 1
            DV_right = stats_sim.q2(T);  % if Sqr is on the right
            DV_left = stats_sim.q1(T);
    end
    
    % Decision rule: compute p(Left)
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR + beta_DV*(DV_left-DV_right))));
end
end