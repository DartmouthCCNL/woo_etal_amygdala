%%% Data file for this plot is computed from the function 'compute_model_signal', 
%%% attached at the end of this script

model_name = "RL25_omegaV_comp1";
load("output/model/Combined/AvgTraj_"+fitType+"_"+model_name+".mat",'AvgTraj'); 
disp("Output loaded.");

groups_to_plot = 1;

figure(200); clf
set(gcf,'Units','normalized','Position',[0,0,0.6,0.6], 'Color','w');

varSet.task = ["whatOnly","what","where"];
varSet.tasklabel = ["What-Only","What","Where"];
varSet.name = ["Vcho_Stim","Vcho_Act","absRPE_Stim","absRPE_Act"];
varSet.label = ["V_{C,Stim}","V_{C,Act}","|RPE_{Stim}|","|RPE_{Act}|"];
varSet.ylabel = "\color[rgb]{0 .6 0}V_{Cho}\color{black}, |RPE|";
varSet.linetypes = ["-",":","-",":"];
varSet.ylim = [0 .7];
varSet.baseline = 0;
varSet.Colors = {[0 .6 0],[0 .6 0],groups.colors{groups_to_plot},groups.colors{groups_to_plot}};

apply_smooth = 0;

for g = groups_to_plot
    for j = 1:numel(varSet.task)
        for k = 1:numel(schedules.subsets)
            subplot(3,numel(varSet.task),j+(k-1)*3);
            for n = 1:numel(varSet.name)
                MeanToPlot = AvgTraj.(groups.labels(g)).(varSet.task(j)).(schedules.subsets(k)).(varSet.name(n)).Mean;
                SEMToPlot = AvgTraj.(groups.labels(g)).(varSet.task(j)).(schedules.subsets(k)).(varSet.name(n)).sem;
                if apply_smooth
                    MeanToPlot = smooth(MeanToPlot)';
                    SEMToPlot = smooth(SEMToPlot)';
                end
                plotCol =  varSet.Colors{n};
                shadedErrorBar(1:size(MeanToPlot,2), MeanToPlot, SEMToPlot, 'lineProps',{'LineWidth',1.5,'Color',plotCol,'linestyle',varSet.linetypes(n)});
                hold on;
            end        
            
            xline(40.5,"--k",'linewidth',1); xlim([0 80]);  % rev
            xticklabels({'0','20','<\it{rev}>','60','80'}); xtickangle(0);
            
            yticks(0:.1:.7);
            yticklabels({'0','','0.2','','0.4','','0.6'});
            
            yline(varSet.baseline,":k");    % chance level
            ylim(varSet.ylim);            
            text(1,0,[schedules.labels(k)],'Units','normalized','FontSize',gca_fontsize+2,'FontWeight','bold','VerticalAlignment','bottom','HorizontalAlignment','right');
            set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');
            
            if j==1
                ylabel(varSet.ylabel);
                if k==1
                    legend(varSet.label,'box','on','Location','northwest','fontsize',gca_fontsize-6,'NumColumns',4);
                end
            end
            if k==3
                xlabel("Trials"); 
            end
        end
    end
end

%% 
function compute_model_signal(thisModel, datasets)
    AvgTraj = struct;
    fitfun0 = str2func(thisModel.fun);

    %%% loop through each task (dataset)
    for d = 1:numel(datasets)
        dataset_label = datasets{d};    disp("---"+dataset_label+"---");
        switch dataset_label
            case 'Costa16'            
                task_subsets = "what";
            case 'WhatWhere'
                task_subsets = ["what","where"];
        end

        %%% loop through each group
        for g = 1:numel(groups.labels)
            group_label = groups.labels(g);  
            disp(upper(group_label));       
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
                % select block types
                if d==1                        
                    blockType = "what";
                    thisTaskIDX = ~block_idx.(dataset_label).(group_label).prob1000;    % select stochastic task only
                elseif d==2
                    blockType = task_subsets(tt);
                    thisTaskIDX = block_idx.(dataset_label).(group_label).(blockType);
                end
                disp(taskType+" blocks: "+sum(thisTaskIDX));
                
                % loop through each reward schedule
                tempAllSched = struct;
                for ss = 1:numel(schedules.subsets)
                    %% compute trajectory aligned w.r.t. reversal
                    tempAlignedTraj = struct;
                    thisBlockIdx = thisTaskIDX&block_idx.(dataset_label).(group_label).(schedules.subsets(ss));
                    
                    subset_stats = all_stats(thisBlockIdx);
                    disp("  > "+schedules.labels(ss)+": "+length(subset_stats)+" blocks");
                    
                    for b = 1:length(subset_stats)
                        block_stats = subset_stats{b};
                        tempBlock = struct;
                        
                        % four stages index: 20 trials relative to start/reversal/end
                        trialsIdx = (1:80)';
                        trialsIdx(21:40) =  (block_stats.block_addresses(2)-20:block_stats.block_addresses(2)-1)';  % before Rev
                        trialsIdx(41:60) = (block_stats.block_addresses(2):block_stats.block_addresses(2)+19)';     % after Rev
                        
                        if d==1
                            fitpar0 = thisModel.SessionFit.fitpar.(blockType){block_idx.(dataset_label).(group_label).sessionNum(block_stats.absBlockNum)};
                        else
                            fitpar0 = thisModel.SessionFit.fitpar.Combined{block_idx.(dataset_label).(group_label).sessionNum(block_stats.absBlockNum)};
                        end
                        dat0 = [block_stats.c, block_stats.r, block_stats.cloc];
                        [~, ~, ~, ~, omegaVs] = fitfun0(fitpar0, dat0);
                        tempBlock.omegaV = omegaVs(trialsIdx)';
                    
                        chooseBetter = (block_stats.c==block_stats.hr_shape)';
                        stay_Stim = [NaN; block_stats.c(1:end-1)==block_stats.c(2:end)]';
                        stay_Act = [NaN; block_stats.cloc(1:end-1)==block_stats.cloc(2:end)]';
                        
                        winstay_Stim = [NaN, block_stats.r(1:end-1)'&stay_Stim(2:end)];
                        winstay_Act = [NaN, block_stats.r(1:end-1)'&stay_Act(2:end)];
                        
                        loseswitch_Stim = [NaN, ~block_stats.r(1:end-1)'&~stay_Stim(2:end)];
                        loseswitch_Act = [NaN, ~block_stats.r(1:end-1)'&~stay_Act(2:end)];
    
                        % behavior
                        tempBlock.pBetter = chooseBetter(trialsIdx);
                        tempBlock.stay_Stim = stay_Stim(trialsIdx);
                        tempBlock.stay_Act = stay_Act(trialsIdx);
                        tempBlock.deltaStay = tempBlock.stay_Stim - tempBlock.stay_Act;
                        
                        tempBlock.winstay_Stim = winstay_Stim(trialsIdx);
                        tempBlock.winstay_Act = winstay_Act(trialsIdx);
                        tempBlock.deltaWinStay = tempBlock.winstay_Stim - tempBlock.winstay_Act;
                        
                        tempBlock.loseswitch_Stim = loseswitch_Stim(trialsIdx);
                        tempBlock.loseswitch_Act = loseswitch_Act(trialsIdx);
                        tempBlock.deltaLoseSwitch = tempBlock.loseswitch_Stim - tempBlock.loseswitch_Act;
                        
                        % entropy bin
                        prevRew = [NaN; block_stats.r(1:end-1)]';
                        tempBlock.prevRew = prevRew(trialsIdx);
                        
                        tempAlignedTraj = append_to_fields(tempAlignedTraj, {tempBlock});
                        tempAllSched = append_to_fields(tempAllSched, {tempBlock});
                    end         
                    
                    % compute Mean & SEM for each rew schedule
                    tempAvgTraj = struct;
                    varNames = fieldnames(tempAlignedTraj)';    varNames = setdiff(varNames,{'prevRew'});
                    for f = 1:numel(varNames)
                        tempAvgTraj.(varNames{f}).Mean = mean(tempAlignedTraj.(varNames{f}),1,'omitnan');
                        if strcmp(varNames{f}, "deltaStay")
                            tempAvgTraj.(varNames{f}).sem = std(tempAlignedTraj.(varNames{f}),1,'omitnan')./sqrt(sum(~isnan(tempAlignedTraj.(varNames{f}))));
                        else
                            % SE = sqrt(P*Q) for Bernouilli variable
                            tempAvgTraj.(varNames{f}).sem = sqrt(tempAvgTraj.(varNames{f}).Mean.*(1-tempAvgTraj.(varNames{f}).Mean))./sqrt(sum(~isnan(tempAlignedTraj.stay_Stim)));
                        end
                    end
                    AvgTraj.(group_label).(taskType).(schedules.subsets(ss)) = tempAvgTraj;
                end
                
                % compute Mean & SEM for all schedules combined
                tempAvgTraj = struct;
                varNames = fieldnames(tempAllSched)';
                for f = 1:numel(varNames)
                    tempAvgTraj.(varNames{f}).Mean = mean(tempAllSched.(varNames{f}),1,'omitnan');
                    tempAvgTraj.(varNames{f}).sem = sqrt(tempAvgTraj.(varNames{f}).Mean.*(1-tempAvgTraj.(varNames{f}).Mean))./sqrt(sum(~isnan(tempAllSched.stay_Stim)));
                end
                AvgTraj.(group_label).(taskType).Stochastic = tempAvgTraj;
            end
        end
    end
    AvgTraj.selectModlabel = thisModel.label;
end