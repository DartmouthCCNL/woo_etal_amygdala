%% Averaged trajectory of omegaV

% Load data
group_idx = 1;  % controls
fitType = "Session"; 
selectMod = 7;

[OmegaV_traj] = compute_trajectory_by_reward_schedule(fitType, selectMod, group_idx);
%% Panel D: separate by reward schedule

omega_var = "EffOmegaV";    varLabel = "\Omega (effective \omega)";
% omega_var = "omegaV";     varLabel = "\omega_V (dynamic)";

varSet.linstyle = ["-","--",":"];
schedules.colors = {[0 0 0],ones(1,3)*.35,ones(1,3)*.7};
varSet.task = ["whatOnly","what","where"];
varSet.tasklabel = ["What-only","What","Where"];

for g = group_idx
    figure(350+g); clf
    % set(gcf,'Units','normalized','Position',[0,0,0.2,0.3], 'Color','w');
    set(gcf,'Units','normalized','Position',[0,0,0.18,0.26], 'Color','w');

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
    xtickangle(0);
    xticklabels({'0','20','<\it{rev}\rm>','60','80'});
    
    text(2,0.8,varSet.tasklabel(1),'VerticalAlignment','bottom','FontName','Helvetica','FontSize',gca_fontsize);
    text(80,0.5,varSet.tasklabel(2),'VerticalAlignment','bottom','HorizontalAlignment','right','FontName','Helvetica','FontSize',gca_fontsize);
    text(80,0.21,varSet.tasklabel(3),'VerticalAlignment','top','HorizontalAlignment','right','FontName','Helvetica','FontSize',gca_fontsize);
    xlabel("Trials");
    ylabel(varLabel);
    yline(0.5,":k");
    ylim([0 1]); yticks(0:.25:1); yticklabels({'0','','0.5','','1'});
    legend(flip(schedules.labels),'box','off','Location','southwest','fontsize',gca_fontsize);
    
    set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');
end

%% C. Example omegaV trajectory
load("dataset/preprocessed/demo_stats_control.mat",'block_stats','exampleNum','sess_num');
StimCols = {[73,179,161]/255,[234,82,138]/255}; 

dataset_label = "WhatWhere";
[M] = initialize_models(dataset_label, "control17", 1, 0);

ModsToPlot = 7;         % dynamic omega (plastic)
LineStyle_set = {'-'};
omegaCols = 'k';

figure(32); clf
set(gcf,'Units','normalized','Position',[0,0,0.21,0.26], 'Color','w');  % 1-by-1
ax = gca;
ax.Position(1) = 0.18;
ax.Position(2) = 0.19;
ax.Position(3) = 0.6;
ax.Position(4) = 0.73;

% specify label
if block_stats.what
    blockType = "what";
else
    blockType = "where";
end
for s = 1:numel(schedules.subsets)
    if block_stats.(schedules.subsets(s))(1)
        blockSched = schedules.labels(s);
    end
end

% choice & rewards
x = 1:80;
shape_on_right = block_stats.c.*block_stats.cloc;
Rs_height = 1.15; 
Ls_height = 1.3;
Cir_on_right = (shape_on_right==-1);
Sqr_on_right = (shape_on_right==1);
c_Cir_rewarded = (block_stats.c==-1&block_stats.r==1);
c_Sqr_rewarded = (block_stats.c==1&block_stats.r==1);

% Chose: Cir on right
chosen_idx = block_stats.c==-1&block_stats.cloc==1;
scatter(x(Cir_on_right&chosen_idx), Rs_height*-shape_on_right(Cir_on_right&chosen_idx), 15, 'o','filled','MarkerFaceColor',StimCols{1}); hold on;
% scatter(x(Cir_on_right&c_Cir_rewarded&chosen_idx), (Rs_height+.025)*-shape_on_right(Cir_on_right&c_Cir_rewarded&chosen_idx),'.g','LineWidth',1.1); 
% Sqr on right
chosen_idx = block_stats.c==1&block_stats.cloc==1;
scatter(x(Sqr_on_right&chosen_idx), Rs_height*shape_on_right(Sqr_on_right&chosen_idx), 20, 's','filled','MarkerFaceColor',StimCols{2});
% scatter(x(Sqr_on_right&c_Sqr_rewarded&chosen_idx), (Rs_height+.025)*shape_on_right(Sqr_on_right&c_Sqr_rewarded&chosen_idx),'.g','LineWidth',1.1); 
% Cir on left
chosen_idx = block_stats.c==-1&block_stats.cloc==-1;
scatter(x(Sqr_on_right&chosen_idx), Ls_height*shape_on_right(Sqr_on_right&chosen_idx), 15, 'o','filled','MarkerFaceColor',StimCols{1},'HandleVisibility','off');
% scatter(x(Sqr_on_right&c_Cir_rewarded&chosen_idx), (Ls_height+.025)*shape_on_right(Sqr_on_right&c_Cir_rewarded&chosen_idx),'.g','LineWidth',1.1); 
% Sqr on left
chosen_idx = block_stats.c==1&block_stats.cloc==-1;
scatter(x(Cir_on_right&chosen_idx), Ls_height*-shape_on_right(Cir_on_right&chosen_idx), 20, 's','filled','MarkerFaceColor',StimCols{2},'HandleVisibility','off');
% scatter(x(Cir_on_right&c_Sqr_rewarded&chosen_idx), (Ls_height+.025)*-shape_on_right(Cir_on_right&c_Sqr_rewarded&chosen_idx),'.g','LineWidth',1.1); 

% reward
scatter(x(block_stats.r==1), (Rs_height+Ls_height)/2*-shape_on_right(block_stats.r==1),'|g','LineWidth',0.8); 

% omegaV traj
dat = [block_stats.c, block_stats.r, block_stats.cloc];
nLL = nan(1,numel(ModsToPlot));
LL_trials = nan(numel(ModsToPlot),80);
Omega_set = nan(80,numel(ModsToPlot));
for m = 1:numel(ModsToPlot)
    mtp = ModsToPlot(m);
    thisMod = M{mtp};   disp(thisMod.label);
    fitfun0 = str2func(thisMod.fun);
    % choose fitted params to use
    switch fitType
        case "Block"
            fitpar0 = thisMod.fitpar{exampleNum};
        case "Session"
            if strcmp(dataset_label,'Costa16')
                fitpar0 = thisMod.SessionFit.fitpar.what{sess_num};
            else
                fitpar0 = thisMod.SessionFit.fitpar.Combined{sess_num};
            end
    end
    disp(thisMod.plabels'+": "+num2str(fitpar0',3));
    if contains(thisMod.name,'SubjectFixedRho')
        disp("Effective omega model with fixed rho");
        initVals.Rho = block_stats.SubjectFixed_Rho;    disp(initVals.Rho);
        [nLL(m), LL_trials(m,:), ~, ~, omegaVs] = fitfun0(fitpar0, dat, initVals);
        plot(omegaVs,'--k'); hold on; % omega before scaling
        omegaVs = omegaVs.*initVals.Rho./(omegaVs.*initVals.Rho+(1-omegaVs).*(1-initVals.Rho));
    else
        disp("Dynamic omega model");
        [nLL(m), LL_trials(m,:), ~, ~, omegaVs] = fitfun0(fitpar0, dat);
    end
    Omega_set(:,m) = omegaVs;
    disp("-LL = "+num2str(nLL(m)));
    plot(omegaVs,'LineWidth',2,'LineStyle',LineStyle_set{m},'Color',omegaCols,'Marker','none','HandleVisibility','on'); hold on;
end
disp(nLL);

ylabel(["Arbitration weight \Omega       ","  \leftarrow{\it{action      stim}}\rm\rightarrow             "]); %
rev = block_stats.block_addresses(2);
xline(block_stats.block_addresses(2),'--k','LineWidth',1,'HandleVisibility','off'); % Reversal
text(rev+.5,1.325,"\it{rev}",'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',gca_fontsize-1);
text(80,0,upper(blockType)+" block, "+blockSched+"%" ,'HorizontalAlignment','right','VerticalAlignment','bottom','FontSize',gca_fontsize+2);

text(-6,1.1,"\it{choice}",'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',gca_fontsize-1,'Rotation',90);
ylim([0 Ls_height+.025]);
yticks([0:.20:1.0,Rs_height,Ls_height]);
ax.YTickLabel{end} = 'L';
ax.YTickLabel{end-1} = 'R';
xlabel("Trials");

% task legend
L = legend(["Stim A","Stim B","reward"],'FontSize',gca_fontsize-1,'Location','northeastoutside','box','on','LineWidth',.5,'Position',[.8 .75 .19 .17]);
set(ax,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
