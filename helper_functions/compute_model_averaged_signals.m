%% subfunction: compute averaged signals (Dynamic model only)
function [AvgTraj] = compute_model_averaged_signals(fitType, selectMod, loaded_groups, comparison_groups, M, block_idx, AllBlockStats, overwrite_file)    
    datasets = {'Costa16','WhatWhere'};
    AvgTraj = struct;

    for d = 1:numel(datasets)
        dataset_label = datasets{d};    disp("---"+dataset_label+"---");
        switch dataset_label
            case 'Costa16'            
                task_subsets = "what";
            case 'WhatWhere'
                task_subsets = ["what","where"];
        end
        
        % loop through each group
        for g = 1:numel(comparison_groups)
            group_label = loaded_groups(comparison_groups(g));  
            disp(upper(group_label));
            thisModel = M.(dataset_label).(group_label){selectMod};
            fitfun0 = str2func(thisModel.fun);
            if contains(fitType,"Session")&&~thisModel.sessionfit_exists
                disp("Model session fit doesn't exist");
                continue;
            end
            
            BetaDVidx = strcmp(thisModel.plabels,"\beta_{1}");
            BetaStim_idx = BetaDVidx;
            BetaAct_idx = BetaDVidx;
            if sum(BetaDVidx)==0
                error("Inv. temp. parameter not identified"); 
            end
            if contains(thisModel.name,"SubjectFixedRho")
                betaFlag = "SubjectFixedRho";
            end
            
            if contains(thisModel.name,"2beta")||contains(thisModel.name,"dynamicRho")||contains(thisModel.name,"SubjectFixedRho")
                twoBeta_flag = 1;
            else
                twoBeta_flag = 0;
                betaFlag = "";
            end

            %% loop through blocks (block types)
            all_stats = AllBlockStats.(dataset_label).(group_label);
            for b = 1:length(all_stats)
                all_stats{b}.absBlockNum = b;   % assign absolute block number
            end

            for tt = 1:numel(task_subsets)
                if d==1
                    taskType = "whatOnly";                        
                else
                    taskType = task_subsets(tt);
                end 
                sname = "output/model/"+dataset_label+"/trajectory_data/"+group_label+"/"+fitType+"_"+group_label+"_"+M.WhatWhere.(loaded_groups(1)){selectMod}.name+"_"+taskType+".mat";
                
                skipped_cnt = 0;
                if overwrite_file||~exist(sname,'file')
                    tic
                    tempAlignedTraj = struct;
                    
                    % select block types
                    if d==1                        
                        blockType = "what";
                        thisTaskIDX = ~block_idx.(dataset_label).(group_label).prob1000;    % select stochastic task only
                    elseif d==2
                        blockType = task_subsets(tt);
                        thisTaskIDX = block_idx.(dataset_label).(group_label).(blockType);
                    end
                    disp("=="+taskType+"==");
                    subset_stats = all_stats(thisTaskIDX);

                    %% loop through each blocks
                    blocks_cnt = 0;
                    for b = 1:length(subset_stats)
                        block_stats = subset_stats{b};  blocks_cnt = blocks_cnt + 1;
                        tempBlock = struct;
                        
                        % choose fitted params to use
                        switch fitType
                            case "Block"
                                fitpar0 = thisModel.fitpar{block_stats.absBlockNum};
                            case "SessionCombined"
                                if d==1
                                    fitpar0 = thisModel.SessionFit.fitpar.(blockType){block_idx.(dataset_label).(group_label).sessionNum(block_stats.absBlockNum)};
                                else
                                    fitpar0 = thisModel.SessionFit.fitpar.Combined{block_idx.(dataset_label).(group_label).sessionNum(block_stats.absBlockNum)};
                                end            
                        end
                        dat0 = [block_stats.c, block_stats.r, block_stats.cloc];
                        if contains(thisModel.name,"SubjectFixedRho")
                            initVals.Rho = block_stats.SubjectFixed_Rho;
                            [~, ~, ~, V_hist, omegaVs, RPE, Rel_diff] = fitfun0(fitpar0, dat0, initVals);
                        else
                            [~, ~, ~, V_hist, omegaVs, RPE, Rel_diff] = fitfun0(fitpar0, dat0);
                        end
                        
                        % obtain rho for this model
                        if twoBeta_flag
                            if strcmp(betaFlag,"freeRho")
                                % version: beta-rho model
                                Rho = fitpar0(RhoIdx);
                                betaDV_sum = fitpar0(BetaDVidx);
                            elseif strcmp(betaFlag,"2freeBeta")
                                % version: two free beta model
                                betaStim = fitpar0(BetaStim_idx);
                                betaAct = fitpar0(BetaAct_idx);
                                betaDV_sum = betaStim + betaAct;
                                Rho = betaStim/(betaStim+betaAct);
                            elseif strcmp(betaFlag,"SubjectFixedRho")
                                % version: fixed rho per subject
                                betaDV_sum = fitpar0(BetaDVidx);
                                Rho = block_stats.SubjectFixed_Rho;
                            end
                        end
   
                        deltaOmegaV = [diff(omegaVs); NaN];
                        plusDeltaOmegaRate = deltaOmegaV; 
                            plusDeltaOmegaRate(plusDeltaOmegaRate<=0) = NaN;        % pick increase only
                            plusDeltaOmegaRate = plusDeltaOmegaRate./(1-omegaVs);
                        minusDeltaOmegaRate = deltaOmegaV;
                            minusDeltaOmegaRate(minusDeltaOmegaRate>=0) = NaN;      % pick decrease only
                            minusDeltaOmegaRate = minusDeltaOmegaRate./(0-omegaVs); 
                            
                        % four stages index
                        trialsIdx = (1:80)';
                        trialsIdx(21:40) =  (block_stats.block_addresses(2)-20:block_stats.block_addresses(2)-1)';  % before Rev
                        trialsIdx(41:60) = (block_stats.block_addresses(2):block_stats.block_addresses(2)+19)';     % after Rev              

                        tempBlock.deltaVcho = RPE.Loc(trialsIdx)' - RPE.Stim(trialsIdx)';
                        tempBlock.deltaAbsRPE = abs(RPE.Loc(trialsIdx))' - abs(RPE.Stim(trialsIdx))';
                        tempBlock.deltaRel = Rel_diff(trialsIdx)';
                        
                        tempBlock.deltaVchoPos = tempBlock.deltaVcho;
                            tempBlock.deltaVchoPos(tempBlock.deltaVchoPos<=0) = NaN;
                        tempBlock.deltaVchoNeg = tempBlock.deltaVcho;
                            tempBlock.deltaVchoNeg(tempBlock.deltaVchoNeg>=0) = NaN;
                            tempBlock.deltaVchoNeg = abs(tempBlock.deltaVchoNeg);
                                                
                        tempBlock.omegaV = omegaVs(trialsIdx)';
                        tempBlock.PotentRate = plusDeltaOmegaRate(trialsIdx)';
                        tempBlock.DepressRate = minusDeltaOmegaRate(trialsIdx)';
                        
                        % multiplied by inv. temp.
                        tempBlock.BetaStim = tempBlock.omegaV*fitpar0(BetaStim_idx);
                        tempBlock.BetaAct  = (1-tempBlock.omegaV)*fitpar0(BetaAct_idx);       
                        
                        % separate beta models
                        if twoBeta_flag
                            tempBlock.BetaStim = betaDV_sum*Rho.*tempBlock.omegaV;  % betaStim = betaDV*rho*omegaV
                            tempBlock.BetaAct  = betaDV_sum*(1-Rho).*(1-tempBlock.omegaV); % betaAct = betaDV*(1-rho)*(1-omegaV)
                            tempBlock.OmegaStim = Rho*tempBlock.omegaV;
                            tempBlock.OmegaAct = (1-Rho)*(1-tempBlock.omegaV);
                            tempBlock.effectiveOmega = tempBlock.OmegaStim./(tempBlock.OmegaStim + tempBlock.OmegaAct); % aligned w.r.t. reversal
                            
                            % compute effective effective rates (CAUTION: start w/ unaligned omegaV!)
                            OmegaStim = Rho*omegaVs;
                            OmegaAct = (1-Rho)*(1-omegaVs);
                            OmegaEff = OmegaStim./(OmegaStim+OmegaAct);
                            deltaOmegaE = [diff(OmegaEff); NaN];
                            
                            plusDeltaOmegaE = deltaOmegaE;
                                plusDeltaOmegaE(plusDeltaOmegaE<=0) = NaN;      % pick increase only
                                plusDeltaOmegaE = plusDeltaOmegaE./(1-OmegaEff);
                            minusDeltaOmegaE = deltaOmegaE;
                                minusDeltaOmegaE(minusDeltaOmegaE>=0) = NaN;    % pick decrease only    
                                minusDeltaOmegaE = minusDeltaOmegaE./(0-OmegaEff);
                                
                            tempBlock.afterRevMean_EffPotentRate = mean(plusDeltaOmegaE(block_stats.block_indices{2}),'omitnan');
                            tempBlock.afterRevMean_EffDepressRate = mean(minusDeltaOmegaE(block_stats.block_indices{2}),'omitnan');
                            %
                            tempBlock.BlockMean_EffPotentRate = mean(plusDeltaOmegaE,'omitnan');
                            tempBlock.BlockMean_EffDepressRate = mean(minusDeltaOmegaE,'omitnan');
                                
                            % align w.r.t. reversal
                            tempBlock.effectiveArbPlus = plusDeltaOmegaE(trialsIdx)';    
                            tempBlock.effectiveArbMinus = minusDeltaOmegaE(trialsIdx)';
                            
                            tempBlock.BetaStimArbRatePlus = tempBlock.PotentRate*betaDV_sum*Rho;
                            tempBlock.BetaStimArbRateMinus = tempBlock.DepressRate*betaDV_sum*Rho;
                            
                            tempBlock.BetaActArbRateMinus = tempBlock.PotentRate*betaDV_sum*(1-Rho);
                            tempBlock.BetaActArbRatePlus = tempBlock.DepressRate*betaDV_sum*(1-Rho);
                        else
                            % common beta baseline; rate is the same
                            tempBlock.BetaArbRatePlus = tempBlock.PotentRate*fitpar0(BetaDVidx);
                            tempBlock.BetaArbRateMinus = tempBlock.DepressRate*fitpar0(BetaDVidx);    
                        end
                       
                        tempBlock.afterRevMean_PotentRate = mean(plusDeltaOmegaRate(block_stats.block_indices{2}),'omitnan');
                        tempBlock.afterRevMean_DepressRate = mean(minusDeltaOmegaRate(block_stats.block_indices{2}),'omitnan');
                        %
                        tempBlock.BlockMean_PotentRate = mean(plusDeltaOmegaRate,'omitnan');
                        tempBlock.BlockMean_DepressRate = mean(minusDeltaOmegaRate,'omitnan');                        

                        % compile every block as individual data
                        tempAlignedTraj = append_to_fields(tempAlignedTraj, {tempBlock}); 
                    end
                    
                    %% compute Mean & SEM
                    tempAvgTraj = struct;
                    varNames = fieldnames(tempAlignedTraj)';
                    for f = 1:numel(varNames)
                        tempAvgTraj.(varNames{f}).Mean = mean(tempAlignedTraj.(varNames{f}),1,'omitnan');
                        tempAvgTraj.(varNames{f}).sem = std(tempAlignedTraj.(varNames{f}),1,'omitnan')./sqrt(sum(~isnan(tempAlignedTraj.(varNames{f}))));
                    end          
                              
                    % save output
                    save(sname,'tempAvgTraj','skipped_cnt'); disp("Output saved: "+sname);
                    ET = toc;
                    disp("Total elapsed time: "+ET/60+" minutes");
                    disp(datetime);
                else
                    % load existing output
                    load(sname,'tempAvgTraj','skipped_cnt');
                    disp("Saved data loaded: "+sname);
                end
                AvgTraj.(group_label).(taskType) = tempAvgTraj;
            end
        end
    end
end