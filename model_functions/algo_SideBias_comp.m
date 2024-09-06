function stats_sim = algo_SideBias_comp(stats_sim,xpar)
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
aRew = xpar(1);
beta_DV = xpar(2);
SideBiasR = xpar(3);    % side bias toward right option

aUnrew = xpar(4);
decay_rate = xpar(5);
omegaV = xpar(6);       % fixed omegaV for all trials

%% Simulate trials

T = stats_sim.currTrial;
if stats_sim.currTrial == 1  %if this is the first trial, initialize
    stats_sim.qL(T) = 0.5;      % V_left 
    stats_sim.qR(T) = 0.5;      % V_right
    stats_sim.q1(T) = 0.5;      % V_cir
    stats_sim.q2(T) = 0.5;      % V_sqr
    
    stats_sim.RPE.Stim(T) = NaN; 
    stats_sim.RPE.Loc(T) = NaN; 
%     stats_sim.Rel_diff(T) = 0;
%    stats_sim.omegaV(T) = omegaV;
    
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR)));      % p(choose Left)
else
    % Update action values (reward from previous trial)
    % Update V_Stimuli
    [stats_sim.q1(T), stats_sim.q2(T), RPE_Stim] = IncomeUpdateStepRates(stats_sim.r(T-1),stats_sim.c(T-1), stats_sim.q1(T-1),stats_sim.q2(T-1),aRew,aUnrew,decay_rate);
    stats_sim.RPE.Stim(T-1,1) = RPE_Stim;
    
    % Update V_Location
    [stats_sim.qL(T), stats_sim.qR(T), RPE_Loc] = IncomeUpdateStepRates(stats_sim.r(T-1),stats_sim.cloc(T-1), stats_sim.qL(T-1),stats_sim.qR(T-1),aRew,aUnrew,decay_rate);
    stats_sim.RPE.Loc(T-1,1) = RPE_Loc;
    
    % softmax rule for action selection
    % assign sides
    switch stats_sim.shape_on_right(T)
        case -1
            vS_right = stats_sim.q1(T);  % if Cir is on the right
            vS_left = stats_sim.q2(T);
        case 1
            vS_right = stats_sim.q2(T);  % if Sqr is on the right
            vS_left = stats_sim.q1(T);
    end
    DV_left = vS_left*omegaV + stats_sim.qL(T)*(1-omegaV);
    DV_right = vS_right*omegaV + stats_sim.qR(T)*(1-omegaV);
    
    % Decision rule: compute p(Left)
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR + beta_DV*(DV_left-DV_right))));
end
end