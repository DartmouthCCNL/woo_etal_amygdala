% clc;
groups_to_plot = 2:3; % plot for lesioned groups 
comp_mod_lines = ["--",":"];
MET_to_plot = "ERDS_diff"; MET_to_label = "ERDS_{Stim} − ERDS_{Action}"; % MET_to_label = "\DeltaERDS";
data_cols = {ones(1,3)*.5, 'm', 'c'};


% Select models to load:
[M, block_idx] = load_fitted_Params_dist_all_dataset(groups.labels, "initialize_models");

% plot each group
for g = groups_to_plot
    figure(60+g); clf;
    set(gcf,'Units','normalized','Position',[0,0,0.5,0.25], 'Color','w');
    tiledlayout(1,3);  
    
    % each panel for each block/task type
    for pp = 1:3
        nexttile; hold on;
        if pp==1
           dataset_label = 'Costa16';
           block_type = "what"; tlt = "What-only";
           compareMods = [3, 1];
           leg_label = ["Data","Dynamic","Static","Stim-only"];
        elseif pp==2
           dataset_label = 'WhatWhere';
           block_type = "what"; tlt = "What";
           compareMods = [3, 1];
           leg_label = ["Data","Dynamic","Static","Stim-only"]; 
        elseif pp==3
           dataset_label = 'WhatWhere';
           block_type = "where"; tlt = "Where";
           compareMods = [3, 2];
           leg_label = ["Data","Dynamic","Static","Act-only"];       
        end   
        fullMod = 7; % index for full dynamic model
        
        disp("==========="+groups.labels(g)+", "+tlt+"============")    
        groupDat = wholeBlockOutput.(dataset_label).(groups.labels(g));
        groupDat.ERDS_diff = groupDat.ERDS_stim - groupDat.ERDS_loc;
        emp_dat = groupDat.(MET_to_plot)(groupDat.(block_type));
        [f, x, flo, fup] = ecdf(emp_dat, 'Bounds', 'on'); 
        plot(x, f,'color',data_cols{g},'LineWidth',1); hold on; % plot(x, flo, ':'); plot(x, fup, ':'); 

        % load full model ERDS
        fname = "output/model/"+dataset_label+"/simulated/"+groups.labels(g)+"/simERDS_"+M.(dataset_label).(groups.labels(g)){fullMod}.name+"_rev1.mat";
        mod1 = load(fname, 'allDat'); 
        mod1.allDat.ERDS_diff = mod1.allDat.ERDS_stim - mod1.allDat.ERDS_act;
        dat_for_cdf1 = mod1.allDat.(MET_to_plot)(:);

        b_idx = groupDat.(block_type);
        if strcmp(dataset_label,'Costa16')
            b_idx = b_idx(~groupDat.prob1000); % exclude determinsitic task
        end
        b_idx = repmat(b_idx(:), numSim, 1);

        dat_for_cdf1 = dat_for_cdf1(b_idx);        
        [f, x, flo, fup] = ecdf(dat_for_cdf1, 'Bounds', 'on'); 
        
        plot(x, f, '-','color',groups.colors{g},'LineWidth',1);
        [~,pval,D_stat] = kstest2(dat_for_cdf1, emp_dat);
        disp("Full model: D = "+num2str(D_stat,3)+", p = "+num2str(pval,3));

        % comparison with other models
        other_cdf = cell(1,length(compareMods));
        for c = 1:length(compareMods)
            fname = "output/model/"+dataset_label+"/simulated/"+groups.labels(g)+"/simERDS_"+M.(dataset_label).(groups.labels(g)){compareMods(c)}.name+"_rev1.mat";
            mod2 = load(fname, 'allDat'); 
            mod2.allDat.ERDS_diff = mod2.allDat.ERDS_stim - mod2.allDat.ERDS_act;
            dat_for_cdf2 = mod2.allDat.(MET_to_plot)(:);
            other_cdf{c} = dat_for_cdf2(b_idx);
            [f, x, flo, fup] = ecdf(other_cdf{c}, 'Bounds', 'on'); 
            
            plot(x, f, comp_mod_lines(c),'color',groups.colors{g},'LineWidth',1);
            [~,pval,D_stat] = kstest2(other_cdf{c}, emp_dat);
            disp("Model "+compareMods(c)+": D = "+num2str(D_stat,3)+", p = "+num2str(pval,3));

            [~,pval,D_stat] = kstest2(dat_for_cdf1, other_cdf{c});
            disp("   from full model: D = "+num2str(D_stat,3)+", p = "+num2str(pval,3));
        end
        [~,pval,D_stat] = kstest2(other_cdf{1}, other_cdf{2});
        disp("Between other models: D = "+num2str(D_stat,3)+", p = "+num2str(pval,3));  
        legend(leg_label,'box','off','FontSize',12);
        xlabel(MET_to_label);
        xticks(-1:.5:1);
        if pp==1; ylabel("Fraction (c.d.f.)"); end
        title(tlt);
        set(gca,'FontName','Helvetica','FontSize',16,'FontWeight','normal','LineWidth',1, 'tickdir', 'out','Box','off');
    end
end