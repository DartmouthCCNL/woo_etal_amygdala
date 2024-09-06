function stats_sim = algo_SideBias_LocOnly(stats_sim,xpar)
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
    stats_sim.qL(T) = 0.5;      % V_cir
    stats_sim.qR(T) = 0.5;      % V_sqr
    
    stats_sim.RPE.Loc(T) = NaN; 
    
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR)));      % p(choose Left)
else
    % Update action values (reward from previous trial)    
    % Update V_Location
    [stats_sim.qL(T), stats_sim.qR(T), RPE_Loc] = IncomeUpdateStepRates(stats_sim.r(T-1),stats_sim.cloc(T-1), stats_sim.qL(T-1),stats_sim.qR(T-1),aRew,aUnrew,decay_rate);
    stats_sim.RPE.Loc(T-1,1) = RPE_Loc;
    
    % softmax rule for action selection    
    % Decision rule: compute p(Left)
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR + beta_DV*(stats_sim.qL(T)-stats_sim.qR(T)))));
end
end