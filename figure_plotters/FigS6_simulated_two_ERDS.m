% ERDS simulation
groups_to_plot = 1;   % controls only
blocks_to_plot = 1;   % 1=What-only task; 2=What; 3=Where

markerAlp = 0.6;
roundNumBeta = 4; % round to the 4th digits

%% Panel A: empirical data
MET.name = 'ERDS'; MET.label = 'ERDS';

figure(60); clf
set(gcf,'Units','normalized','Position',[0,0,0.20,0.32],'Color','w'); % 2-by-2
for g = groups_to_plot   
    group_label = groups.labels(g); 
    
    for t = blocks_to_plot
        if t==1
            dataset_label = 'Costa16';
        elseif t>=2
            dataset_label = 'WhatWhere';
        end
        thisDat = wholeBlockOutput.(dataset_label);
        if t==1
            task_idx = ~thisDat.(group_label).prob1000;     % exclude deterministic task!!
            task_lbl = "WHAT-only";
        elseif t==2
            task_idx = thisDat.(group_label).what;
            task_lbl = "WHAT";
        elseif t==3
            task_idx = thisDat.(group_label).where;
            task_lbl = "WHERE";
        end
        xx = thisDat.(group_label).(MET.name+"_stim")(task_idx);
        yy = thisDat.(group_label).(MET.name+"_loc")(task_idx);

        S1 = scatterhist(xx,yy,'Kernel','off','Direction','out','Color','k','Marker','o','MarkerSize',5,'Location','SouthWest'); %,'NBins',25
        l = lsline; l.LineWidth = 1; l.Color = [.7 .7 .7];
            
        % Spearman
        [r,p] = corr(xx,yy,'rows','pairwise','type','Spearman');
        disp(task_lbl+": Spearman's r = "+r+", p = "+p);
        % Pearson
        [r,p] = corr(xx,yy,'rows','pairwise','type','Pearson');
        disp(task_lbl+": Pearson's r = "+r+", p = "+p);

        % regression (use mean-centered ERDS data)
        D = table;
        D.subject = thisDat.(group_label).subj_idx(task_idx)';
        D.ERDS_stim = xx;
        D.ERDS_act  = yy;
        sub_set = unique(D.subject);        
        numericIdx = varfun(@isnumeric, D, 'OutputFormat', 'uniform');
        for sb = 1:length(sub_set)
            tempD = D(D.subject==sub_set(sb),:);
            tempD{:, numericIdx} = normalize(tempD{:, numericIdx},'center'); % mean-center by subjects
            D(D.subject==sub_set(sb),:) = tempD;
        end
        mdl = fitlme(D, "ERDS_act ~ ERDS_stim + (1|subject)");
        beta_coeff = mdl.Coefficients.Estimate(2);
        pval = mdl.Coefficients.pValue(2);
        text(.05, .05, ["\beta = "+round(beta_coeff*10^roundNumBeta)/10^roundNumBeta,"\it{p} = \rm"+num2str(pval,3)],'Units','normalized','HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',gca_fontsize);

        % paired t-test
        [H,tpv,~,stats] = ttest(xx,yy,'Alpha',.05/3);
        cohensD = computeCohen_d(xx,yy,'paired');
        disp("t("+stats.df+") = "+num2str(stats.tstat,3)+", p = "+num2str(tpv,3)+", Cohen's d = "+cohensD);

        ax = gca;
        ax.XRuler.TickLabelGapOffset = -5;
        ax.XLabel.Position(2) = -.15;
        xlabel(MET.label+"_{Stimulus}");  xlim([0 1]);
        xticks(0:.25:1); xtickangle(0); xticklabels({'0','','0.5','','1'});
        ylabel(MET.label+"_{Action}");  ylim([0 1]);
        yticks(0:.25:1); yticklabels({'0','','0.5','','1'});
        
        ypos = 0;
        if contains(MET.name,"MI"); xlim([0 .5]); ylim([0 .5]); ypos = 0.90; end
        title("Data");
        set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');
    end
end    
S1(2).Position(4) = 0.1303;

%% Panels B-D: model simuation
models_to_plot = [1, 3, 5];
numSim = 100;         % # of simulation per parameter set
[M, block_idx] = load_fitted_Params_dist_all_dataset(groups.labels, "initialize_models");

for m = 1:length(models_to_plot)
    figure(60+m); clf
    set(gcf,'Units','normalized','Position',[0,0,0.20,0.32],'Color','w'); % 2-by-2
        
    for d = 1
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
            % loop through each group
            for g = groups_to_plot
                group_label = groups.labels(g);
                thisModel = M.(dataset_label).(group_label){models_to_plot(m)};
                sname = "output/model/"+dataset_label+"/simulated/"+group_label+"/"+fitType+"_simulated_metrics_nn"+numSim+"_"+thisModel.name+".mat";
                load(sname, 'modSimStruct');
                blockIDX = wholeBlockOutput.(dataset_label).(group_label).(task_subsets(b));

                % exclude deterministic schedule for What-only task
                if strcmp(task_labels(b),"What-only")
                    blockIDX = blockIDX & ~wholeBlockOutput.(dataset_label).(group_label).prob1000;
                end
                xx = modSimStruct.ERDS_stim(blockIDX);
                yy = modSimStruct.ERDS_loc(blockIDX);

                modelCol = groups.colors{g};
                S1 = scatterhist(xx,yy,'Kernel','off','Direction','out','Color','k','Marker','+','MarkerSize',5,'Location','SouthWest'); %,'NBins',25
                l = lsline; l.LineWidth = 1; l.Color = [.7 .7 .7];
                hold on;

                % rank correlation
                [rho, pval] = corr(xx,yy,'type','Spearman');
                disp(task_lbl+": Spearman's r = "+rho+", p = "+pval);
                % Pearson
                [r,p] = corr(xx,yy,'rows','pairwise','type','Pearson');
                disp(task_lbl+": Pearson's r = "+r+", p = "+p);
                
                % regression
                D = table;
                D.subject = thisDat.(group_label).subj_idx(task_idx)';
                D.ERDS_stim = xx;
                D.ERDS_act  = yy;
                sub_set = unique(D.subject);        
                numericIdx = varfun(@isnumeric, D, 'OutputFormat', 'uniform');
                for sb = 1:length(sub_set)
                    tempD = D(D.subject==sub_set(sb),:);
                    tempD{:, numericIdx} = normalize(tempD{:, numericIdx},'center'); % mean-center by subjects
                    D(D.subject==sub_set(sb),:) = tempD;
                end
                mdl = fitlme(D, "ERDS_act ~ ERDS_stim + (1|subject)");
                beta_coeff = mdl.Coefficients.Estimate(2);
                pval = mdl.Coefficients.pValue(2);
                text(.05, .05, ["\beta = "+round(beta_coeff*10^roundNumBeta)/10^roundNumBeta,"\it{p} = \rm"+num2str(pval,3)],'Units','normalized','HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',gca_fontsize);

                % paired t-test
                [H,tpv,~,stats] = ttest(xx,yy,'Alpha',.05/3);
                cohensD = computeCohen_d(xx,yy,'paired');
                disp("t("+stats.df+") = "+num2str(stats.tstat,3)+", p = "+num2str(tpv,3)+", Cohen's d = "+cohensD);

                % model label
                title("Simulation: "+M.Costa16.(group_label){models_to_plot(m)}.label);

                ax = gca;
                ax.XRuler.TickLabelGapOffset = -3;
                ax.XLabel.Position(2) = -.15;

                xlabel("ERDS_{Stimulus}");
                ylabel("ERDS_{Action}");

                xlim([0 1]);
                xticks(0:.25:1); xtickangle(0); xticklabels({'0','','0.5','','1'});
                ylim([0 1]);
                yticks(0:.25:1); yticklabels({'0','','0.5','','1'});
                set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir', 'out','Box','off');
            end
        end
    end
    fprintf('\n\n');
end