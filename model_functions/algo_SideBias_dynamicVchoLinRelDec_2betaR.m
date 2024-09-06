function stats_sim = algo_SideBias_dynamicVchoLinRelDec_2betaR(stats_sim,xpar)
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
beta_1      = xpar(2);
SideBiasR   = xpar(3);    % side bias toward right option
aUnrew      = xpar(4);
decay_rate  = xpar(5);

Rho         = xpar(6);        % betaStim = betaDV*R, betaAct = betaDV*(1-R)

updateRate  = xpar(7);   % fit update rate for omegaV
omega0      = xpar(8);       % initial omegaV at trial 1 (indicating stimulus-based bias)

decay_omega = xpar(9);

omegaV      = omega0;    % initial omegaV
%% Simulate trials

T = stats_sim.currTrial;
if stats_sim.currTrial == 1  %if this is the first trial, initialize
    stats_sim.qL(T) = 0.5;      % V_left 
    stats_sim.qR(T) = 0.5;      % V_right
    stats_sim.q1(T) = 0.5;      % V_cir
    stats_sim.q2(T) = 0.5;      % V_sqr
    
    stats_sim.RPE.Stim(T) = NaN; 
    stats_sim.RPE.Loc(T) = NaN; 
    stats_sim.Rel_diff(T) = 0;
    stats_sim.omegaV(T) = omegaV;
    
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR)));      % p(choose Left)
else
    % Update action values (reward from previous trial)
    % Update V_Stimuli
    [stats_sim.q1(T), stats_sim.q2(T), RPE_Stim] = IncomeUpdateStepRates(stats_sim.r(T-1),stats_sim.c(T-1), stats_sim.q1(T-1),stats_sim.q2(T-1),aRew,aUnrew,decay_rate);
    stats_sim.RPE.Stim(T-1,1) = RPE_Stim;
    
    % Update V_Location
    [stats_sim.qL(T), stats_sim.qR(T), RPE_Loc] = IncomeUpdateStepRates(stats_sim.r(T-1),stats_sim.cloc(T-1), stats_sim.qL(T-1),stats_sim.qR(T-1),aRew,aUnrew,decay_rate);
    stats_sim.RPE.Loc(T-1,1) = RPE_Loc;
    
    % Update omegaV based on reliability difference: V_chosen as reliability signal
    deltaRel = RPE_Loc - RPE_Stim;   
            % = V_chosen.Stim - V_chosen.Loc   : ranges [-1, 1], positive if Stim more reliable
    if deltaRel>0
        stats_sim.omegaV(T,1) = stats_sim.omegaV(T-1,1) + updateRate*deltaRel*(1-stats_sim.omegaV(T-1,1)) + decay_omega*(omega0 - stats_sim.omegaV(T-1,1));       % potentiate toward W_Stimulus
    else
        stats_sim.omegaV(T,1) = stats_sim.omegaV(T-1,1) + updateRate*abs(deltaRel)*(0-stats_sim.omegaV(T-1,1)) + decay_omega*(omega0 - stats_sim.omegaV(T-1,1));  % depress toward W_Action   
    end
    stats_sim.Rel_diff(T,1) = deltaRel;

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
    DV_left = vS_left*Rho*stats_sim.omegaV(T) + stats_sim.qL(T)*(1-Rho)*(1-stats_sim.omegaV(T));
    DV_right = vS_right*Rho*stats_sim.omegaV(T) + stats_sim.qR(T)*(1-Rho)*(1-stats_sim.omegaV(T));
    
    % Decision rule: compute p(Left)
    stats_sim.pL(T) = 1/(1+exp(-(-SideBiasR + beta_1*(DV_left-DV_right))));
end
end