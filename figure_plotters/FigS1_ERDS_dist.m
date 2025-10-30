%% Plotting distribution of ERDS
%close all; clc
figure(10); clf
set(gcf,'Units','normalized','Position',[0,0,0.45,0.6], 'Color','w'); 
datasets = fieldnames(wholeBlockOutput);
MarkerTypes = {'^','v'};

MET = struct;
MET.set = ["ERDS_stim","ERDS_loc"]; 
MET.label = "ERDS";
MET.legend = ["ERDS_{Stim}","ERDS_{Action}"];
MET.LineStyles = {'-',':'};
MET.Lim = [0 1];
MET.InsetLims = {[.3 1],[.55 1],[.4 1]};

group_sched_cols = struct;
group_sched_cols.control = {[0 0 0],ones(1,3)*.5,ones(1,3)*.8};
group_sched_cols.amygdala = {[.5, 0 0],[1 0 0],[1 .6 0]};
group_sched_cols.VS = {[0 0 .5],[0 0.1 1],[0 .75 1]};

%% Each row = each group, column = block type
 
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
            
        % plot data lines
        for g = 1:numel(groups.labels)
            SPNum = TaskNum(b)+(g-1)*3;
            SP = subplot(3,3,SPNum);
            SP.Position(2) = .73 - (g-1)*0.31;
            
            group_label = groups.labels(g);  
            GroupStruct = wholeBlockOutput.(dataset_label).(group_label);
            if strcmp(dataset_label,'Costa16')
                dataIdx = ~GroupStruct.prob1000;           % select stochastic task only
            elseif strcmp(dataset_label,'WhatWhere')
                dataIdx = GroupStruct.(task_subsets(b));   % select What or Where
            end
                
            InsetLineData = struct;
            Err = {};
            Sub_set = unique(GroupStruct.subj_idx);
            for m = 1:2
                % for each schedule
                for s = 1:numel(schedules.subsets)
                    schedIdx = GroupStruct.(schedules.subsets(s));
                    AllGroupDat = GroupStruct.(MET.set(m));
                    dataToPlot = AllGroupDat(dataIdx&schedIdx);                                  
    
                    % fit kernel dist
                    pd = fitdist(dataToPlot,'Kernel');
                    x_pd = linspace(0,1);   
                    y_pd = pdf(pd, x_pd);
                    plot(x_pd, y_pd, 'Color', 'k','LineWidth',1.5,'Color',group_sched_cols.(group_label){s},'LineStyle',MET.LineStyles{m}); 
                    hold on;                    

                    % data for inset: select schedule                                    
                    sub_ids = GroupStruct.subj_idx(dataIdx&schedIdx);
                    tempMean = nan(1, length(Sub_set));
                    for subj = 1:length(Sub_set)
                        tempMean(subj) = mean(dataToPlot(Sub_set(subj)==sub_ids));
                    end
                    InsetLineData.Y{m,1}(1,s) = mean(tempMean,'omitnan');
                    InsetLineData.Err{m}(s) = std(tempMean,'omitnan') /sqrt(length(tempMean));

                    mu = mean(tempMean,'omitnan'); 
                    med = median(dataToPlot,'omitnan');
                    M = scatter(mu,0 +(s-1)*.075, 75,group_sched_cols.(group_label){s},'Marker',MarkerTypes{m},'MarkerFaceColor',group_sched_cols.(group_label){s},'MarkerEdgeColor','none');                    
                end
            end
            
            % task label
            if g==1
                text(0.5, 1.05, [task_labels(b)],'Units','normalized','HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',gca_fontsize+2,'FontWeight','bold');
            elseif g==3
                xlabel(MET.label);
            end
            if TaskNum(b)==1
                % ylabel(["prob.","\fontsize{12}(\color[rgb]{"+num2str(groups.colors{g})+"}"+groups.labels(g)+"\color{black})"]);
                ylabel("prob. density");
            end
            xlim(MET.Lim);                         

            % panel label
            text(-.225,1.05,char(SPNum+'a'-1),'Units','normalized','FontWeight','bold','FontSize',24,'FontName','helvetica','VerticalAlignment','bottom');

            % group legend
            % if SPNum==1; legend(MET.legend,'Box','off','Location','northwest'); end
            ax = gca;
            set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir', 'out','Box','off');
            
            % inset
            ax_inset = axes('Position',[SP.Position(1)+(0.125)*SP.Position(3), SP.Position(2)+SP.Position(4)*(0.5), SP.Position(3)*.4, SP.Position(4)*.4],'tickdir','out');
            for m = 1:2
                P = plot(1:3, InsetLineData.Y{m},'Color',groups.colors{g},'LineWidth',1,'LineStyle',MET.LineStyles{m}); % ,'Marker',MarkerTypes{m},'MarkerSize',4
                hold on;
                % if m==1
                %     P.MarkerFaceColor = groups.colors{g};
                % end                
                for s = 1:numel(schedules.subsets)
                    scatter(s, InsetLineData.Y{m}(s),30, 'filled','MarkerFaceColor', group_sched_cols.(group_label){s},'MarkerEdgeColor','none'); 
                    hold on;
                end
                errorbar(1:3,InsetLineData.Y{m},InsetLineData.Err{m},'LineStyle','none','Color',groups.colors{g},'LineWidth',.5,'HandleVisibility','off');

                if TaskNum(b)==1
                    if g==1
                        if m==1; y_fact = 1;
                        else; y_fact = .95; end
                    else
                        if m==1; y_fact = 0.9;
                        else; y_fact = 1; end
                    end
                    text(3.3,InsetLineData.Y{m}(end)*y_fact,MET.legend(m),'Color',groups.colors{g},'FontSize',9,'VerticalAlignment','middle');
                end
            end
            xlim([0.5 3.5]);
            ylim(MET.InsetLims{g}); %ylim(MET.Lim);
            xticklabels(schedules.labels); xtickangle(45);
            set(ax_inset,'FontName','Helvetica','FontSize',10,'FontWeight','normal','LineWidth',1, 'tickdir', 'out','Box','off');
        end
    end
end