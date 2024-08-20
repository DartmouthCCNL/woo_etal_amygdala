
initialize_model_fun = "initialize_models";
[M, block_idx, AllBlockStats] = load_fitted_Params_dist_all_dataset(groups.labels, initialize_model_fun);

selectMod = 7;  % dynamic 1-gamma model w/ Vcho
comparison_groups = 1:3;

[AvgTraj] = compute_model_averaged_signals("SessionCombined", selectMod, groups.labels, comparison_groups, M, block_idx, AllBlockStats, 0);


%% Fig. B-C
group_to_plot = 2:3;

omega_var = "EffOmegaV";    varLabel = "\Omega (effective \omega)";
% omega_var = "omegaV";     varLabel = "\omega_V (dynamic)";

varSet.linstyle = ["-","--",":"];
prob80_cols = {[0 0 0], [.5, 0 0], [0 0 .5]};
prob70_cols = {ones(1,3)*.35, [1 0 0], [0 0.1 1]};
prob60_cols = {ones(1,3)*.7, [1 .6 0], [0 .75 1]};

[OmegaV_traj] = compute_trajectory_by_reward_schedule(fitType, selectMod, groups.labels, group_to_plot, M, block_idx, AllBlockStats);

varSet.task = ["whatOnly","what","where"];
varSet.tasklabel = ["WHAT-Only","WHAT","WHERE"];

for g = group_to_plot
    figure(550+g); clf
    set(gcf,'Units','normalized','Position',[0,0,0.16,0.23], 'Color','w');
    
    schedules.colors{1} = prob80_cols{g};
    schedules.colors{2} = prob70_cols{g};
    schedules.colors{3} = prob60_cols{g};
    
    for j = 1:numel(varSet.task)
        for k = numel(schedules.subsets):-1:1           
            Lcol = schedules.colors{k};            
            MeanToPlot = OmegaV_traj.(groups.labels(g)).(varSet.task(j)).(schedules.subsets(k)).(omega_var).Mean;
            SEMToPlot = OmegaV_traj.(groups.labels(g)).(varSet.task(j)).(schedules.subsets(k)).(omega_var).sem;
            shadedErrorBar(1:size(MeanToPlot,2), MeanToPlot, SEMToPlot, 'lineProps',{'LineWidth',2,'LineStyle',varSet.linstyle(j),'Color',Lcol});
            hold on;
        end
    end
    xline(40.5,"--k",'linewidth',1); xlim([0 80]);  % rev
    xticks(0:20:80);
    xticklabels({'0','20','<\it{rev}\rm>','60','80'});
    xtickangle(0);
    
    yline(0.5,":k");
    ylim([0 1]);
    yticks(0:.1:1); 
    yticklabels({'0','','0.2','','0.4','','0.6','','0.8','','1'});
    ylabel(varLabel); 
    xlabel("Trials");
    L = legend(flip(schedules.labels),'box','off','Location','northeast','fontsize',gca_fontsize);
    set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');
end


%% Fig. 3E-G: effective arbitration weights (psi+, psi-)
figure(3); clf
set(gcf,'Color','w','Units','normalized','Position',[0.0, 0.0, 0.55, 0.23]);

varSet.task = ["whatOnly","what","where"];
varSet.tasklabel = ["What-only","What","Where"];

varSet.name = ["effectiveArbPlus","effectiveArbMinus"];
varSet.label = ["\psi_+","\psi_-"];

varSet.linetypes = ["-",":"];
varSet.ylabel = "\psi"; 

for j = 1:numel(varSet.task)
    SP = subplot(1,numel(varSet.task),j);
        
    for g = 1:numel(comparison_groups)
        for k = 1:numel(varSet.name)
            MeanToPlot = AvgTraj.(groups.labels(g)).(varSet.task(j)).(varSet.name(k)).Mean;
            SEMToPlot = AvgTraj.(groups.labels(g)).(varSet.task(j)).(varSet.name(k)).sem;
            if 1
                MeanToPlot = smooth(MeanToPlot)';
                SEMToPlot = smooth(SEMToPlot)';
            end
            shadedErrorBar(1:size(MeanToPlot,2), MeanToPlot, SEMToPlot, 'lineProps',{'LineWidth',1.5,'Color',groups.colors{comparison_groups(g)},'linestyle',varSet.linetypes(k)});
            hold on;
        end
    end
    Rev = xline(41,"--k",'linewidth',1); xlim([0 80]);  % rev  
    ylabel(varSet.ylabel);
    if j==1
        legend(varSet.label,'box','off','Location','northwest','fontsize',gca_fontsize-1);
    end
    xlabel("Trials");
    if contains(varSet.name(1),"Potent")||strcmp(varSet.name(1),"effectiveArbPlus")
        ylim([0 0.15]);
        yticks(0:.025:.15);
        SP.YTickLabel = {'0','','.05','','.10','','.15'};
    elseif contains(varSet.name(1),"Effective")
        ylim([0 0.4]);
    elseif strcmp(varSet.name(1),"deltaRel")
        yline(0,':k','handlevisibility','off');
    elseif strcmp(varSet.name(1),"omegaV")
        if j==1
            ylim([0.5 1]);
        else
            ylim([0 1]);  
        end
        yticks(0:.1:1);
        yline(0.5,':k','LineWidth',1,'handlevisibility','off');
        SP.YTickLabel = {'0','','0.2','','0.4','','0.6','','0.8','','1'};
    end        
    SP.XTick = [1, 20, 41, 60, 80]; SP.XTickLabel = {'1','20','<\it{rev}>','60','80'};
    xtickangle(0);
    set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');
    title(varSet.tasklabel(j),'Fontsize',gca_fontsize);
end
