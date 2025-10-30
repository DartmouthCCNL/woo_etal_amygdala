% Five-fold cross-validation of RL models

% compile data to plot
[Mods, block_idx] = load_fitted_Params_dist_all_dataset(groups.labels, "initialize_models");

Datasets  = {'Costa16',  'WhatWhere'};
all_tasks = ["What-only","What/Where"];
WhatOnly_col = 'k';            
WW_col = ones(1,3)*0.7;                           
fontcols = {'w','k'};

%% CV table
figure(21); clf
set(gcf, 'Units', 'inches', 'Position', [1 1 18 6.5], 'Color','w');

all_test_blocks = [];
for g = 1:numel(groups.labels)
    group_label = groups.labels(g);

    thisMods = Mods.(Datasets{1}).(group_label);
    AvgLL = nan(numel(thisMods), length(all_tasks)); SumLL = AvgLL;
    allLL = cell(numel(thisMods), length(all_tasks));
    allLLs = nan(numel(thisMods), length(all_tasks));
    McF   = cell(numel(thisMods), length(all_tasks));
    ModsLabels = strings(numel(thisMods),1);

    %% compile CV data
    for d = 1:numel(Datasets)
        dataset_label = Datasets{d};
        switch dataset_label
            case 'Costa16'            
                task_subset = "what"; 
                task_labels = "WhatOnly"; task_num = 1;
            case 'WhatWhere'
                task_subset = "Combined";
                task_labels = "WhatWhere"; task_num = 2;
        end     
        %%
        thisMods = Mods.(dataset_label).(group_label);
        thisMods(6) = []; % remove subject-fit data
        for m = 1:numel(thisMods)            
            thisMod   = thisMods{m};
            assert(thisMod.allCV50_exists, d+"."+group_label+": Model "+m+" CV data doesn't exist")            
            thisCVdat = thisMod.allCV;
            subject_set = unique(thisCVdat.animal_ids);                        
            
            allLL{m, d} = cell2mat(thisCVdat.LL_all);
            McF{m, d} = 1 - cell2mat(thisCVdat.LL_all) / (-log(0.5)*80);
            
            % averaged within each subject
            tempAvg = []; tempSum = [];
            for k = 1:length(subject_set)
                thisSub = thisCVdat.LL_all(subject_set(k)==thisCVdat.animal_ids);
                if m==1
                    disp(g+"-"+k+". total test blocks = "+length(thisSub{1})); 
                    all_test_blocks = [all_test_blocks, length(thisSub{1})];
                end
                tempAvg = [tempAvg; mean(cell2mat(thisSub),'omitnan')];
                tempSum = [tempSum; sum(cell2mat(thisSub),'omitnan')];
            end
            AvgLL(m, d) = mean(tempAvg);
            SumLL(m, d) = mean(tempSum);
            allLLs(m, d) = mean(allLL{m, d}, 'omitnan');   
            McF{m, d}   = mean(McF{m, d}, 'omitnan');
        end

        % if exporting source data
        if 0
            D = array2table(cell2mat(allLL(:,d)')); 
            ids = (repelem(thisCVdat.animal_ids', cellfun(@numel, thisCVdat.LL_all)));
            if dataset_label=="WhatWhere"
                if group_label=="amygdala"                
                    ids(ids=="BB1") = "Be";
                    ids(ids=="BB2") = "En";
                    ids(ids=="BB3") = "MJ";
                    ids(ids=="BB4") = "Zi";                                
                end            
                ids(ids=="BB1") = "Go";
                ids(ids=="BB2") = "Ro";
                ids(ids=="BB3") = "Un";
                ids(ids=="BB4") = "Wa";
                ids(ids=="BB5") = "Vo";
                ids(ids=="BB6") = "Fo";
                ids(ids=="BB7") = "Gr";
                ids(ids=="BB8") = "Al";
                ids(ids=="BBB5") = "Un";
                ids(ids=="BBB6") = "Go";
                ids(ids=="BBB7") = "Ro";
                ids(ids=="BBB8") = "Wa";
                ids(ids=="BBB9") = "Vo";
                ids(ids=="BBB10") = "Bl";
            end
            D.Subject = ids;
            writetable(D,"Source_Data_CV.xlsx",'Sheet',group_label+"("+task_labels+")");
        end
    end   
    McF   = cell2mat(McF);

    %% Plot bars
    SP = subplot(1,numel(groups.labels),g);

    DatToUse = allLLs;       % average across all instances
    BarStruct = barh(DatToUse,'EdgeColor','none','BarWidth',0.95); hold on;     % plot horizontal bars
    for m = 1:numel(thisMods)
        ModsLabels(m) = Mods.(Datasets{1}).(group_label){m}.label; 
    end 
    bestToPlot = (min(DatToUse)==DatToUse);
    for i = 1:numel(Datasets)
        if contains(all_tasks(i),"only")
            BarStruct(i).FaceColor = WhatOnly_col;
        elseif strcmp(all_tasks(i),"What/Where")
            BarStruct(i).FaceColor = WW_col;
        end
        for m = 1:numel(thisMods)
            xtips1 = BarStruct(i).YEndPoints(m) + 0.1; %BarStruct(i).YEndPoints(m)/25;
            ytips1 = BarStruct(i).XEndPoints(m);
            this_LL  = BarStruct(i).YData(m);
            this_accu = exp(-this_LL/80);
            labels1 = string(round(this_LL, 2));
            if bestToPlot(m,i)
                labels1 = labels1 + "*";
            end
            % also add McFadden's R squared
            McF_R2 = McF(m,i); %1 - this_LL/(-log(0.5)*80);
            labels1 = labels1 + "\color[rgb]{.5 .5 .5} ("+ string(num2str(McF_R2,3)) + ")";
            text(xtips1,ytips1-0.02,labels1,'VerticalAlignment','middle','FontSize',12);
            
            % legends: task label
            if m==1
                text(1,ytips1-0.02,all_tasks(i),'HorizontalAlignment','left','VerticalAlignment','middle','FontSize',12,'Color',fontcols{i},'FontWeight','bold');
            end
        end
    end
    ylim([0.5 numel(thisMods)+.5]);
    yticks(1: numel(thisMods));
    yticklabels([]);
    
    if g==1
        yticklabels(ModsLabels);
    end
    xlim([0 60]); 
    xticks(0:10:60); xticklabels({'0','','20','','40','','60'});
    xlabel("\langle-log likelihood\rangle");    % -LL per CV instance
    if strcmp(groups.labels(g), "control")
        % xlim([0 40]); xticks(0:10:40);
    end
    xtickangle(45);
    set(SP, 'YDir', 'reverse');
    text(0.5, 1.025, group_label,'Units','normalized','FontSize',gca_fontsize+4,'HorizontalAlignment','center','VerticalAlignment','baseline','Color',groups.colors{g});
    set(SP,'FontName','Helvetica','FontSize',14,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
end