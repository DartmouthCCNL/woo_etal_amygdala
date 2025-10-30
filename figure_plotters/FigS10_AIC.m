% Mean AIC from session fit

% compile data to plot
[Mods, block_idx] = load_fitted_Params_dist_all_dataset(groups.labels, "initialize_models");

Datasets  = {'Costa16',  'WhatWhere'};
all_tasks = ["What-only","What/Where"];
Bar_cols  = {'k', ones(1,3)*0.7};
Font_cols = {'w','k'};
%% Bar plots
gof_measure = "aic";

figure(100); clf
set(gcf,'Units','normalized','Position',[0,0,0.55,0.32], 'Color','w');
numMods = numel(Mods.(Datasets{1}).(groups.labels(1)));
for g = 1:numel(groups.labels)
    group_label = groups.labels(g);
    SP = subplot(1,numel(groups.labels),g);      
    %% compile data across tasks
    allDat = cell(numMods, numel(Datasets));
    meanDatToPlot = nan(size(allDat));
    McF_R2 = nan(size(allDat));
    for d = 1:numel(Datasets)
        dataset_label = Datasets{d};
        switch dataset_label
            case 'Costa16'            
                task_subset = "what";
                task_labels = "WhatOnly";
            case 'WhatWhere'                
                task_subset = "Combined";
                task_labels = "WhatWhere";
                task_num = 2;
        end
        thisMods = Mods.(dataset_label).(group_label);
        thisMods(6) = []; % remove subject-fit data
        ModsLabels = strings(1,numel(thisMods));
        NumLabels = strings(1,numel(thisMods));
        
        if strcmp(dataset_label,'Costa16')
           stochastic_session_idx =  ~block_idx.(dataset_label).(group_label).deterministic_session;
        else
            stochastic_session_idx =  true(block_idx.WhatWhere.(group_label).sessionNum(end),1);
        end

        for m = 1:numel(thisMods)
            thisMod = thisMods{m};
            if thisMod.sessionfit_exists==0; error(dataset_label+" "+group_label+", model "+m+": Fit doesn't exist"); end
            % select fitting type
            allDat{m,d} = thisMod.SessionFit.(gof_measure).(task_subset)(stochastic_session_idx);
            % multiply by # of blocks?
            % allDat{m,d} = allDat{m,d} .* block_idx.(dataset_label).(group_label).numBlocksPerSess(stochastic_session_idx)';
            
            if any(isinf(allDat{m,d}))
                disp("Inf element found, replacing w/ NaN...");
                allDat{m,d}(isinf(allDat{m,d})) = NaN;
            end
            meanDatToPlot(m,d) = mean(allDat{m,d},'omitnan'); 

            % McFadden R-squared
            McF_R2(m, d) = mean(1 - thisMod.SessionFit.ll.(task_subset)(stochastic_session_idx) / (-log(0.5)*80), 'omitnan');

            ModsLabels(m) = thisMod.label;
            NumLabels(m) = "";
        end

        % if exporting source data
        if 0
            D = array2table(cell2mat(allDat(:,d)')); 
            writetable(D,"Source_Data_AIC"+d+".xlsx",'Sheet',group_label+"("+task_labels+")");
        end
    end      
    
    %% plot bars
    BarStruct = barh(meanDatToPlot,'EdgeColor','none','BarWidth',0.95); hold on;     % plot horizontal bars
    bestToPlot = (min(meanDatToPlot)==meanDatToPlot); 
    [~,idx] = sort(meanDatToPlot,1);
    
    for d = 1:numel(all_tasks)
        BarStruct(d).FaceColor = Bar_cols{d};       
        
        for m = 1:numel(thisMods)
            xtips1 = BarStruct(d).YEndPoints(m) + BarStruct(d).YEndPoints(m)/100;
            ytips1 = BarStruct(d).XEndPoints(m);
            labels1 = "\color{black}"+string(round(BarStruct(d).YData(m),2));
            
            % sig test with baseline model (#1)
            if bestToPlot(m,d)
                fontW = 'normal';
                % labels1 = labels1 + " \color{black}min"; %"\fontsize{14}\color{gray}*";
                % sig test from the second best model
                [H, Pval] = ttest(allDat{idx(2,d),d}-allDat{m,d},0,'tail','right');                
                disp(d+"."+g+": comparison w/ second best: P = "+Pval);
                if Pval < .05                    
                    labels1 = labels1 + "\color{black}*";
                end
            else
                fontW = 'normal';
            end               

            labels1 = labels1 + "\color[rgb]{.5 .5 .5} ("+ string(num2str(McF_R2(m,d),3)) + ")";

            text(xtips1,ytips1,labels1,'VerticalAlignment','middle','FontSize',12,'FontWeight',fontW);
            % legends: task label
            if m==1
                text(1,ytips1-0.02,all_tasks(d),'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',12,'Color',Font_cols{d},'FontWeight','bold');
            end
        end
    end
    ylim([0 numel(ModsLabels)+1]);
    yticks(1: numel(ModsLabels));
    yticklabels([]);
    xlabel(upper(gof_measure));
    if g==1
        yticklabels(ModsLabels);
    else
        yticklabels(NumLabels);
    end
    xtickangle(45);
    SP.XRuler.TickLabelGapOffset = -3;
    set(SP, 'YDir', 'reverse');
    text(0.5, 1.025, group_label,'Units','normalized','FontSize',20,'HorizontalAlignment','center','VerticalAlignment','baseline','Color',groups.colors{g});    
    set(SP,'FontName','Helvetica','FontSize',14,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
end       