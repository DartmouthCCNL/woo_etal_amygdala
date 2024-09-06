function [MeanTraj] = run_paramSet_PhasePlane(thisMod, numSim, RewEnv, player)
    include_arb_rates = 1;      % also include eff. arb rates    
    omega0_set = player.omega0_set;

    % initialize
    CompiledDat(numSim,length(omega0_set)) = struct('chooseBetter',[],'omegaV',[]);
    if include_arb_rates
        CompiledDat(numSim,length(omega0_set)).posDelta_omega = [];
        CompiledDat(numSim,length(omega0_set)).negDelta_omega = [];
    end

    if contains(thisMod.name,'betaR')
        betaRho_flag = 1;
        CompiledDat(numSim,length(omega0_set)).EffOmega = [];
        if include_arb_rates
            CompiledDat(numSim,length(omega0_set)).posDelta_Omega = [];
            CompiledDat(numSim,length(omega0_set)).negDelta_Omega = [];
        end
    else
        betaRho_flag = 0;
    end
    
    %% loop through sim iterations
    tic
    for n = 1:numSim
        % set up unique environment
        BlockEnv = SetUpBlockEnv_WhatWhere(RewEnv.totalL, RewEnv.Probs, RewEnv.blockL, n, RewEnv.Task);
        if mod(n,1000)==0
            disp(n+"/"+numSim);
        end
        
        %% loop through initial w_0 
        parfor q1 = 1:length(omega0_set)
            thisParam = player;
            thisParam.params(strcmp(thisMod.plabels,"\omega_0")) = omega0_set(q1);

            % simulate choice behavior
            simStats = simulateAgentBehavior(thisParam, BlockEnv); 
            chooseBetter = simStats.c==BlockEnv.hr_shape;

            % compute arbitration rates
            omegaVs = simStats.omegaV;
            
            if include_arb_rates
                deltaOmegaV = [diff(omegaVs); NaN];
                plusDeltaOmegaRate = deltaOmegaV./(1-omegaVs); 
                    plusDeltaOmegaRate(plusDeltaOmegaRate<=0) = NaN; % pick increse only; 0 or NaN
                    plusDeltaOmegaRate(plusDeltaOmegaRate>1) = NaN; % null when change is zero
                minusDeltaOmegaRate = deltaOmegaV./(0-omegaVs); 
                    minusDeltaOmegaRate(minusDeltaOmegaRate<=0) = NaN; % pick decrease only; 0 or NaN
                    minusDeltaOmegaRate(minusDeltaOmegaRate>1) = NaN; % null when change is zero
            end 
            % effecive omega (Omega) for beta-rho model
            if betaRho_flag
                Rho = thisParam.params(strcmp(thisMod.plabels,"\rho"));
                EffOmega = Rho*omegaVs./(Rho*omegaVs+(1-Rho)*(1-omegaVs));

                % compute arb rates for EffOmega
                deltaEffOmega = [diff(EffOmega); NaN];
                plusDeltaEffOmegaRate = deltaEffOmega./(1-EffOmega); 
                    plusDeltaEffOmegaRate(plusDeltaEffOmegaRate<=0) = NaN; % pick increse only; 0 or NaN
                    plusDeltaEffOmegaRate(plusDeltaEffOmegaRate>1) = NaN; % null when change is zero
                minusDeltaEffOmegaRate = deltaEffOmega./(0-EffOmega); 
                    minusDeltaEffOmegaRate(minusDeltaEffOmegaRate<=0) = NaN; % pick decrease only; 0 or NaN
                    minusDeltaEffOmegaRate(minusDeltaEffOmegaRate>1) = NaN; % null when change is zero
            end
            % initialize data bin to compile (each struct should be a row vector)
            compileStats = struct;
            compileStats.chooseBetter   = double(chooseBetter)';
            compileStats.omegaV         = omegaVs';
            if betaRho_flag
                compileStats.EffOmega   = EffOmega';
            end

            if include_arb_rates                
                compileStats.posDelta_omega  = plusDeltaOmegaRate';
                compileStats.negDelta_omega  = minusDeltaOmegaRate';
                if betaRho_flag
                    compileStats.posDelta_Omega  = plusDeltaEffOmegaRate';
                    compileStats.negDelta_Omega  = minusDeltaEffOmegaRate';
                end
            end
            CompiledDat(n,q1) = compileStats;
        end
    end 
    fprintf('\n');

    %% compute mean trajectory
    MeanTraj = cell(1,length(omega0_set));
    Fields = fieldnames(CompiledDat);
    for q1 = 1:length(omega0_set)
        MeanTraj{q1} = struct; 
        for f = 1:length(Fields)
            MeanTraj{q1}.(Fields{f}) = mean(reshape([CompiledDat(:,q1).(Fields{f})],RewEnv.totalL,numSim),2,'omitnan');
        end
    end
    
    ET = toc;
    disp("Elapsed time is "+ET/60+" minutes."); 
end

%% subfunction: set up random block environment (What/Where task)
function BlockEnv = SetUpBlockEnv_WhatWhere(totalL, Probs, blockL, randSeed, blockType)
    if ~exist('blockType','var')
        blockType = 'WHAT';
    end
    %% set up block env
    HRprob = max(Probs);
    LRprob = min(Probs);
    initialBetterWorse_idx = randperm(2);
    betterInitial = (initialBetterWorse_idx(1)-1)*2 - 1;    % randomly select between [-1, 1]

    % initialize bin
    BlockEnv = struct;
    BlockEnv.rewardprob = nan(totalL, 2);      % reward schedule
    BlockEnv.rewardarray = nan(totalL, 2);     % actual pre-assigned rewards
    BlockEnv.hr_shape = nan(totalL, 1);        % higher-reward stimulus (-1 or 1)
    BlockEnv.hr_side = nan(totalL, 1);         % higher-reward location (-1 or 1)
    
    trial_idx = false(totalL,1);
    block_addresses = 1:blockL:totalL;
    init_better_start = 1:blockL*2:totalL;
    initBetterIdx = trial_idx;
    for j = 1:numel(init_better_start)
        start_id = init_better_start(j);
        end_id = init_better_start(j) + blockL - 1;
        initBetterIdx(start_id:end_id) = true;
    end
    
    % assign pseudorandom location values (-1 or 1) for two stimuli:                
    BlockEnv.shape_on_right = (randi(2,totalL,1)-1.5)*2;
    cir_on_right = (BlockEnv.shape_on_right==-1);
    
    % assign reward prob for two stimuli
    BlockEnv.rewardprob(initBetterIdx,initialBetterWorse_idx(1)) = HRprob;  
    BlockEnv.rewardprob(initBetterIdx,initialBetterWorse_idx(2)) = LRprob;
    BlockEnv.rewardprob(~initBetterIdx,initialBetterWorse_idx(1)) = LRprob;
    BlockEnv.rewardprob(~initBetterIdx,initialBetterWorse_idx(2)) = HRprob;       

    % reward array: assign rewards based on probs
    rng(randSeed);
    for j = 1:numel(block_addresses)
        start_id = block_addresses(j);
        end_id = block_addresses(j) + blockL - 1;
        numTrials = length(start_id:end_id);
        
        rewarded = [round(BlockEnv.rewardprob(start_id,1)*numTrials), round(BlockEnv.rewardprob(start_id,2)*numTrials)];       % number of assigned rewards for each shape during Acq
        omission = numTrials - rewarded;
        
        ra1 = [zeros(omission(1),1); ones(rewarded(1),1)];
        ra1 = ra1(randperm(numTrials));                    % randomly shuffle where the rewards exist for Cir
        ra2 = [zeros(omission(2),1); ones(rewarded(2),1)];
        ra2 = ra2(randperm(numTrials));                    % randomly shuffle where the rewards exist for Sqr
        BlockEnv.rewardarray(start_id:end_id,:) = [ra1, ra2];
    end
    BlockEnv.rewardarrayLR = BlockEnv.rewardarray;

    % determine format of reward array based on block types
    if strcmp(blockType,'WHAT')
        % assign higher reward shape for each trial (What blocks)
        BlockEnv.hr_shape(initBetterIdx) = betterInitial;
        BlockEnv.hr_shape(~initBetterIdx) = -betterInitial;

        % determine location of better/worse stimuli
        BlockEnv.hr_side = BlockEnv.shape_on_right.*BlockEnv.hr_shape;
         
        % assgined rewards for each *side/action*
        BlockEnv.rewardarrayLR(cir_on_right,:) = flip(BlockEnv.rewardarrayLR(cir_on_right,:),2);

    elseif strcmp(blockType,'WHERE')
        % assign higher reward action for each trial (Where blocks)
        BlockEnv.hr_side(initBetterIdx) = betterInitial;
        BlockEnv.hr_side(~initBetterIdx) = -betterInitial;
        
        % determine shapes of the better/worse sides
        BlockEnv.hr_shape = BlockEnv.shape_on_right.*BlockEnv.hr_side;
        
        % assgined rewards for each *stimuli*
        BlockEnv.rewardarray(cir_on_right,:) = flip(BlockEnv.rewardarray(cir_on_right,:),2);
    else
        error('Choose either WHAT or WHERE block types');
    end        
    
    BlockEnv.block_addresses = block_addresses;
    BlockEnv.betterInitial = betterInitial;
end