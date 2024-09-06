%% subfunc: trajectory by reward schedule
function [AvgTraj] = compute_trajectory_by_reward_schedule(fitType, selectMod, group_idx, M, block_idx, AllBlockStats)
    datasets = {'Costa16','WhatWhere'};
    schedules.subsets = ["prob8020","prob7030","prob6040"];
    groups_labels = ["control", "amygdala", "VS"];
    if nargin<4
        disp("Loading output...");
        M = struct;
        block_idx = struct;
        AllBlockStats = struct;
    else
        disp("Computing omega trajectory by reward schedule...")
    end
    [models] = initialize_models(datasets{1}, groups_labels(group_idx(1)), 1, 0);
    
    AvgTraj = struct;
    % loop through each group
    for g = 1:numel(group_idx)
        group_label = groups_labels(group_idx(g));  
        disp(upper(group_label));
        sname = "output/model/Combined/Omega_by_rew/"+fitType+"_"+group_label+"_"+models{selectMod}.name+".mat";

        if ~exist(sname,'file')  
            betaFlag = "";
            if contains(models{selectMod}.name,"SubjectFixedRho")
                betaFlag = "SubjectFixedRho";
            elseif contains(models{selectMod}.name,"2betaR")
                betaFlag = "freeRho";
            end
            tic
            GroupStruct = struct;
            for d = 1:numel(datasets)
                dataset_label = datasets{d};    
                disp("---"+dataset_label+"---");
                switch dataset_label
                    case 'Costa16'            
                        task_subsets = "what";
                    case 'WhatWhere'
                        task_subsets = ["what","where"];
                end
                thisModel = M.(dataset_label).(group_label){selectMod};
                fitfun0 = str2func(thisModel.fun);

                if thisModel.sessionfit_exists==0
                    disp("Model fit doesn't exist");
                    continue; 
                end
                %% loop through block types & schedules
                all_stats = AllBlockStats.(dataset_label).(group_label);
                for b = 1:length(all_stats)
                    all_stats{b}.absBlockNum = b;   % assign absolute block number
                end
                % loop through each block type
                for tt = 1:numel(task_subsets)
                    if d==1
                        taskType = "whatOnly";                        
                    else
                        taskType = task_subsets(tt);
                    end
                    disp("=="+taskType+"==");
                    % loop through each schedule
                    for ss = 1:numel(schedules.subsets)
                        disp(schedules.subsets(ss));
                        % select block types
                        if d==1                        
                            blockType = "what";
                            thisBlocksIDX = block_idx.(dataset_label).(group_label).(schedules.subsets(ss));
                        elseif d==2
                            blockType = task_subsets(tt);
                            thisBlocksIDX = block_idx.(dataset_label).(group_label).(blockType)&block_idx.(dataset_label).(group_label).(schedules.subsets(ss));
                        end
                        subset_stats = all_stats(thisBlocksIDX);
                        tempAlignedTraj = struct;
                        %% loop through each blocks
                        for b = 1:length(subset_stats)
                            block_stats = subset_stats{b};
                            tempBlock = struct;
                            switch fitType
                                case "Block"
                                    fitpar0 = thisModel.fitpar{block_stats.absBlockNum};
                                case "Session"
                                    if d==1
                                        fitpar0 = thisModel.SessionFit.fitpar.(blockType){block_idx.(dataset_label).(group_label).sessionNum(block_stats.absBlockNum)};
                                    else
                                        fitpar0 = thisModel.SessionFit.fitpar.Combined{block_idx.(dataset_label).(group_label).sessionNum(block_stats.absBlockNum)};
                                    end
                            end
                            dat0 = [block_stats.c, block_stats.r, block_stats.cloc];
                            if contains(thisModel.name,"SubjectFixedRho")
                                initVals.Rho = block_stats.SubjectFixed_Rho;
                                [~, ~, ~, ~, omegaVs] = fitfun0(fitpar0, dat0, initVals);
                            else
                                [~, ~, ~, ~, omegaVs] = fitfun0(fitpar0, dat0);
                            end    
                            % four stages index
                            trialsIdx = (1:80)';
                            trialsIdx(21:40) =  (block_stats.block_addresses(2)-20:block_stats.block_addresses(2)-1)';  % before Rev
                            trialsIdx(41:60) = (block_stats.block_addresses(2):block_stats.block_addresses(2)+19)';     % after Rev              
                            tempBlock.omegaV = omegaVs(trialsIdx)';
                            
                            if (betaFlag~="")
                                if strcmp(betaFlag,"SubjectFixedRho")
                                    Rho = block_stats.SubjectFixed_Rho;
                                elseif strcmp(betaFlag,"freeRho")
                                    Rho = fitpar0(strcmp(thisModel.plabels,"\rho"));
                                end
                                OmegaStim = Rho*tempBlock.omegaV;
                                OmegaAct = (1-Rho)*(1-tempBlock.omegaV);
                                tempBlock.EffOmegaV = OmegaStim./(OmegaStim + OmegaAct);
                            end
                            
                            % compile every block as individual data
                            tempAlignedTraj = append_to_fields(tempAlignedTraj, {tempBlock}); 
                        end
                        
                        % compute Mean & SEM for each schedule
                        tempSchedTraj = struct;
                        varNames = fieldnames(tempAlignedTraj)';
                        for f = 1:numel(varNames)
                            tempSchedTraj.(varNames{f}).Mean = mean(tempAlignedTraj.(varNames{f}),1,'omitnan');
                            tempSchedTraj.(varNames{f}).sem = std(tempAlignedTraj.(varNames{f}),1,'omitnan')./sqrt(sum(~isnan(tempAlignedTraj.(varNames{f}))));
                        end     
                        GroupStruct.(taskType).(schedules.subsets(ss)) = tempSchedTraj;
                        fprintf('\n');
                    end
                end
            end
            % save output
            save(sname,'GroupStruct'); disp("Output saved");
            ET = toc;
            disp("Total elapsed time: "+ET/60+" minutes");
            disp(datetime);
        else
            % load existing output
            load(sname,'GroupStruct');
            disp("Saved data loaded: "+sname);
        end        
        AvgTraj.(group_label) = GroupStruct;
    end
end