%% Plotting distribution of paried difference
close all; clc

figure;
set(gcf,'Units','normalized','Position',[0,0,0.55,0.55], 'Color','w');

MET.Met1_name = 'ERDS_stim';  MET.Met1_label = 'ERDS_{Stim}';
MET.Met2_name = 'ERDS_loc';  MET.Met2_label = 'ERDS_{Action}';
MET.diff_label = "\leftarrow\it{stim-based     action-based}\rm\rightarrow";
X_range = [-1, 1];

MarkerTypes = {'^','<','>'};
all_tasks = ["What-only","What","Where"];
allSchedDat = cell(numel(groups.labels),3);    
for d = 1:numel(datasets)
    dataset_label = datasets{d};
    switch dataset_label
        case 'Costa16'
            task_subsets = "what";
            task_labels = "What-only";
            TaskNum = 1;
        case 'WhatWhere'
            task_subsets = ["what","where"];
            task_labels = ["What","Where"];
            TaskNum = [2,3];
    end

    % loop through block-type
    for b = 1:numel(task_subsets) 
        % compare all schedule data
        for s = 1:numel(schedules.subsets)
            SPNum = TaskNum(b)+(s-1)*3;
            SP = subplot(3,3,SPNum);
            
            % plot data lines
            for g = 1:numel(groups.labels)
                group_label = groups.labels(g);  
                GroupDat = wholeBlockOutput.(dataset_label).(group_label);
                dataToPlot = GroupDat.(MET.Met1_name) - GroupDat.(MET.Met2_name);
                if strcmp(dataset_label,'Costa16')
                    dataIdx = ~GroupDat.prob1000;           % select stochastic task only
                elseif strcmp(dataset_label,'WhatWhere')
                    dataIdx = GroupDat.(task_subsets(b));   % select What or Where
                end
                % sig-test for all schedule data first
                if s==1
                    allSchedDat{g, TaskNum(b)} = dataToPlot(dataIdx);
                end
                schedIdx = GroupDat.(schedules.subsets(s));
                dataToPlot = dataToPlot(dataIdx&schedIdx);                     

                % fit kernel dist
                pd = fitdist(dataToPlot,'Kernel');
                x_pd = linspace(X_range(1), X_range(2));   
                y_pd = pdf(pd, x_pd);
                plot(x_pd, y_pd, 'Color', 'k','LineWidth',1.5,'Color',groups.colors{g}); 
                hold on;
                mu = mean(dataToPlot); 
                med = median(dataToPlot);
                scatter(mu,0,25,groups.colors{g},'Marker',MarkerTypes{g},'MarkerFaceColor',groups.colors{g},'LineWidth',1,'HandleVisibility','off');
                
                % t-test from zero
                [H, pval] = ttest(dataToPlot,0.0,'Alpha',0.001);
                cohens_d = mean(dataToPlot,'omitnan')/std(dataToPlot,'omitnan');
                if H
                    astT = "\fontsize{16}*";
                else
                    astT = "";
                end
                text(mu*1.1+0.075*sign(mu), pdf(pd, mu)*1.12, [num2str(cohens_d,3)+astT], 'FontSize', 12, 'Color',groups.colors{g},'HorizontalAlignment','center');            end
            
            % task label
            text(0.5, 1., [task_labels(b)+", "+schedules.labels(s)],'Units','normalized','HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',gca_fontsize+4,'FontWeight','bold');
            if TaskNum(b)==1
                ylabel("prob. density");
            end
            
            % default value (0)
            ax = gca;
            if ~exist('dotted_vert_val','var')
                dotted_vert_val = 0.0;
            end
            xline(dotted_vert_val, ":k",'LineWidth',1,'HandleVisibility','off');

            % group legend
            if SPNum==1
               legend(groups.labels,'Box','off','Location','northeast'); 
            end
            set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir', 'out','Box','off');
        end
        xlabel([MET.Met1_label+" – "+MET.Met2_label, "\fontsize{14}"+MET.diff_label]);
        
        % group main effet
        disp(task_labels(b)+"=====================");
        [pval, cohenD, ast] = two_sample_T_test(allSchedDat{1,TaskNum(b)}, allSchedDat{2,TaskNum(b)}, 1, 'both');
        disp("Control vs. Amyg: "+ast+"d = "+num2str(cohenD,3)+", p = "+num2str(pval,3));
        [pval, cohenD, ast] = two_sample_T_test(allSchedDat{1,TaskNum(b)}, allSchedDat{3,TaskNum(b)}, 1, 'both');
        disp("Control vs. VS: "+ast+"d = "+num2str(cohenD,3)+", p = "+num2str(pval,3));
        [pval, cohenD, ast] = two_sample_T_test(allSchedDat{2,TaskNum(b)}, allSchedDat{3,TaskNum(b)}, 1, 'both');
        disp("Amyg vs. VS: "+ast+"d = "+num2str(cohenD,3)+", p = "+num2str(pval,3));
    end
    fprintf('\n\n');
end

% block type main effect: within each group
for g = 1:numel(groups.labels)
    disp(">>> "+groups.labels(g)+": "+MET.Met1_label+" – "+MET.Met2_label+" (paired T-test)"); 
    for t = 1:numel(all_tasks)
        [~, pval, ~, stats] = ttest(allSchedDat{g,t},0); cohenD = mean(allSchedDat{g,t},'omitnan')/nanstd(allSchedDat{g,t});
        disp("  "+all_tasks(t)+": d = "+num2str(cohenD,3)+", t("+stats.df+") = "+stats.tstat+", p = "+num2str(pval,3));
    end
    fprintf('\n');
end
fprintf('\n');