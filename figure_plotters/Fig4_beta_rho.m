% load models data
% close all; 
clc

Datasets = {'Costa16','WhatWhere'};

% Select group to plot: % 1=controls, 2=amyg, 3=VS
group_indices = 1:3;      
loaded_groups = groups.labels(group_indices);
comparison_groups = 1:3;

% Select models to load:
initialize_model_fun = "initialize_models";
[M, block_idx, AllBlockStats] = load_fitted_Params_dist_all_dataset(groups.labels, initialize_model_fun);


%% Panel A: fixed value of rho for each monkey
selectMod = 6;
params_to_plot = 6;

figure(41); clf 
set(gcf,'Color','w','Units','normalized','Position',[0.5, 0.5, 0.14, 0.23]);

group_ac = ["cont","\color{red}amyg","\color{blue}VS"];

Mu_s = strings(1,numel(comparison_groups)*2+1);
for d = 1:numel(datasets)
    dataset_label = datasets{d};
    switch dataset_label
        case "Costa16"
            blockType = "what";  panelLbls = "What-only";
        case "WhatWhere"
            blockType = "Combined";  panelLbls = "What/Where";
    end

    for g = 1:numel(comparison_groups)
        group_label = loaded_groups(comparison_groups(g));   
        thisMod = M.(dataset_label).(group_label){selectMod};
        if d==1&&g==1; disp((1:length(thisMod.plabels))'+": "+thisMod.plabels'); end
        thisPars = cell2mat(thisMod.SubjectFit.fitpar.(blockType));
        thisPars = thisPars(:,params_to_plot);

        xPos = g+(d-1)*(numel(comparison_groups)+1);
        Mu_s(xPos) = num2str(mean(thisPars),3);
        bar(xPos,mean(thisPars),'FaceColor',groups.colors{comparison_groups(g)},'EdgeColor','none'); hold on;
        scatter(xPos*ones(size(thisPars)),thisPars,'MarkerFaceColor',groups.colors2{g},'MarkerEdgeColor','k');
        errorbar(xPos,mean(thisPars),std(thisPars),'Color',ones(1,3)*.25);
        if g==1; text(xPos+1,thisMod.ub(params_to_plot), [panelLbls], 'VerticalAlignment','middle','FontSize',gca_fontsize,'HorizontalAlignment','center','Rotation',15); end

        text(xPos, 0.025, Mu_s(xPos), 'fontSize',12, 'Rotation',90, 'Color','w');
    end
end
xticks([1:3,5:7]);
xticklabels([group_ac, group_ac]); xtickangle(40);
ylim([thisMod.lb(params_to_plot),thisMod.ub(params_to_plot)]);
if thisMod.ub(params_to_plot)==100; ylim([0 10]); end
ylabel(thisMod.plabels(params_to_plot)+" (subject-fixed)");
ax = gca;
ax.XRuler.TickLabelGapOffset = -5;
set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');

%% Panel B-C: Comparison of baseline beta_Stim and beta_Act
modNum = 7;

figure(42); clf
set(gcf,'Color','w','Units','normalized','Position',[0.0, 0.0, 0.35, 0.23]);

for d = 1:2
    subplot(1,2,d);
    disp("=========================="+datasets{d}+"==========================")
    for g = 1:numel(loaded_groups)
        Mod1 = M.(datasets{d}).(loaded_groups(g)){modNum};        
        switch datasets{d}
            case 'Costa16'
                blockTypes = "what";
                panelLbls = "What-only";
                panelNums = 1;
            case 'WhatWhere'
                blockTypes = "Combined";
                panelLbls = "What/Where";
                panelNums = 2;
        end      
        for b = 1:numel(blockTypes)
            param1 = cell2mat(Mod1.SessionFit.fitpar.(blockTypes(b)));
            betaDV = param1(:,strcmp(Mod1.plabels,'\beta_{1}'));            
            beta0Stim = betaDV.*block_idx.(datasets{d}).(loaded_groups(g)).subjectFixedRho';
            beta0Act = betaDV.*(1-block_idx.(datasets{d}).(loaded_groups(g)).subjectFixedRho');
                        
            x1 = beta0Stim;
            x2 = beta0Act;

            xlbl = "\beta_{DV}*\rho - \beta_{DV}*(1-\rho)";                                   
            bar(g*2-1,mean(x1),'EdgeColor',groups.colors{g},'FaceColor',groups.colors{g}); hold on;
            scatter(g*2-1*ones(size(x1)),x1,'MarkerEdgeColor',ones(1,3)*.4,'HandleVisibility','off'); %groups.colors2{g}
            %
            bar(g*2,mean(x2),'EdgeColor',groups.colors{g},'FaceColor','none'); hold on;
            scatter(g*2*ones(size(x2)),x2,'MarkerEdgeColor',ones(1,3)*.4,'HandleVisibility','off');
            
            plot([g*2-1 g*2],[x1,x2],'Color',[.5 .5 .5 .2]);                                                          
        end
    end
    if d==1
        legend(["\beta_{stim} = \beta_{1}*\rho","\beta_{action} = \beta_{1}*(1-\rho)"],'box','off','FontSize',gca_fontsize-2);
    end
    ax = gca;    
    xticks((2:2:6)-.5);
    ylim([0 100]);
    ylabel("inverse temp.")
    xticklabels(["cont","\color{red}amyg","\color{blue}VS"]);
    xtickangle(30);
    ax.XRuler.TickLabelGapOffset = -5;
    title(panelLbls);
    set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
end

%% B-C insets showing paired difference
figure(420); clf
set(gcf,'Color','w','Units','normalized','Position',[0.0, 0.0, 0.18, 0.1]);  % 27'

for d = 1:2
    subplot(1,2,d);
    disp("=========================="+datasets{d}+"==========================")
    violinDat = struct;
    for g = 1:numel(loaded_groups)
        Mod1 = M.(datasets{d}).(loaded_groups(g)){modNum};        
        switch datasets{d}
            case 'Costa16'
                blockTypes = "what";
                panelLbls = "WHAT-only";
                panelNums = 1;
            case 'WhatWhere'
                blockTypes = "Combined";
                panelLbls = "WHAT+WHERE";
                panelNums = 2;
        end      
        
        for b = 1:numel(blockTypes)
            param1 = cell2mat(Mod1.SessionFit.fitpar.(blockTypes(b)));
            betaDV = param1(:,strcmp(Mod1.plabels,'\beta_{1}'));            
            beta0Stim = betaDV.*block_idx.(datasets{d}).(loaded_groups(g)).subjectFixedRho';
            beta0Act = betaDV.*(1-block_idx.(datasets{d}).(loaded_groups(g)).subjectFixedRho');
                        
            x1 = beta0Stim;
            x2 = beta0Act;                                                         
            violinDat.(loaded_groups(g)) = x1 - x2;
        end
    end
    violins = violinplot(violinDat);
    for g = 1:numel(loaded_groups)         
        group_label = loaded_groups(g);
        violins(g).ViolinColor = groups.colors{g};
        violins(g).ViolinAlpha = 0.1;           
        % sig-test b/w groups              
        if g==numel(loaded_groups)
            group_comp = loaded_groups(1);
            g_comp = 1.2;
        else
            group_comp = loaded_groups(g+1);
            g_comp = g+1;
        end       
        [pval, cohenD, ast, Tstats] = two_sample_T_test(violinDat.(group_label), violinDat.(group_comp), 1);
        stat_par = " t("+Tstats.df+") = "+Tstats.tstat+", "+ast+"p = "+num2str(pval,3)+", Cohen's d = "+cohenD;

        disp(group_label+" vs. "+group_comp+":");
        disp("z = "+stats.zval);    
        disp(stat_nonpar);
        disp(stat_par);
    end        

    xticklabels([]);
    ylim([-20 20]);
    yline(0,":k");
    ylabel("\Delta\beta");
    set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
end