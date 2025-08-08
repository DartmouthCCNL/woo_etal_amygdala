% Comparison of fitted parameters across the three groups

% compile data to plot
[M, block_idx] = load_fitted_Params_dist_all_dataset(groups.labels, "initialize_models");
modNum = 7; % index for full model
groups_to_plot = 1:3;
%% Plot figs
nPars = length(M.WhatWhere.control{modNum}.plabels);
for dataset_label = ["WhatWhere","Costa16"]
    switch dataset_label
        case "WhatWhere"
            figure(90); clf
        case "Costa16"
            figure(100); clf
    end
    set(gcf,'Color','w','Units','normalized','Position',[0, 0, 0.35, 0.5]);
    tiledlayout(3,ceil(nPars/3));

    [D, GroupDat, SubDat] = compile_param_data(M, block_idx, modNum, dataset_label, wholeBlockOutput);

    for p = 1:length(Mod1.plabels)    
        nexttile;
        thisParam = GroupDat{p};
        violins   = violinplot(thisParam);
        Means = strings(1,numel(violins)); 
        subjectSEM = strings(1,numel(violins));
        for v = 1:numel(violins)                  
            mu  = round(mean(SubDat{p}.(groups.labels(v)))*1000)/1000;
            SEM = sem(SubDat{p}.(groups.labels(v)),2); 
            Means(v) = num2str(mu,3);    
            subjectSEM(v) = num2str(SEM,3);
            violins(v).ViolinColor = groups.colors{v};
            violins(v).ViolinAlpha = 0.1;           
        end
        xticks(1:3);
        FontCols = "\color{"+["black","red","blue"]+"}";
        xticklabels(FontCols+Means+"\newline\fontsize{10}\pm"+subjectSEM);
        xtickangle(0);    
        ylim([Mod1.lb(p) Mod1.ub(p)]);    
        if Mod1.lb(p)==0&&Mod1.ub(p)==1
            yticks(0:0.25:1); 
            yline(0.5,":k");
        elseif Mod1.ub(p)==100
            yticks(0:25:100); 
            yticklabels({'0','','50','','100'});
        elseif Mod1.lb(p)==-1
            yline(0,":k");
        end  
        ylabel(Mod1.plabels(p));
        set(gca,'FontName','Helvetica','FontSize',gca_fontsize-4,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
                
        % between-group comparisons
        disp("------------Comparing "+p+". "+Mod1.plabels(p)+"------------")
        y = "param"+p;
        mdl = fitlme(D, y+" ~ group + (1+sess_perc|subject)");   
        
        % plot significance for group-wise comparison (controls as ref.)
        asterisk = cell(1,3);
        var_idx = find(contains(mdl.CoefficientNames,'group')&~contains(mdl.CoefficientNames,':'));        
        group_pval = mdl.Coefficients.pValue(var_idx);     
        group_pval(3) = group_pval(2); % VS - Control comparison
        disp(mdl);
        
        % run contrast for difference of effects b/w lesion groups
        Betas = fixedEffects(mdl);
        L = [0 1 -1]; % amyg - VS
        contrast = L * Betas(1:length(L)); % intercep + main effects of amyg & VS
        SE = sqrt(L*mdl.CoefficientCovariance(1:length(L),1:length(L))*L');
        tstat = contrast /SE;
        pv = 2 * (1 - tcdf(abs(tstat), mdl.DFE));
        disp("b = "+contrast+", SE = "+SE+", t("+mdl.DFE+") = "+tstat+", p = "+pv);
        group_pval(2) = pv; % amyg - VS comparison
    
        for g = groups_to_plot
            if g==length(groups_to_plot)
                group_comp = groups.labels(1);
            else
                group_comp = groups.labels(g+1);
                g_comp = g+1;
            end       
            
            %%% Set p-val for asterisks
            disp_pval = group_pval(g);
            if disp_pval < 0.05
                if disp_pval < .01
                    if disp_pval < .001
                        asterisk{g} = "***";
                    else
                        asterisk{g} = "**";
                    end
                else
                    asterisk{g} = "*";
                end
            else
                asterisk{g} = "n.s.";
            end
    
            if contains(asterisk{g},"*")
                Fsize = 20;
            else
                Fsize = 12;
            end
            if g<=2
                plot([g+.2,g_comp-.2], [.3 .3]*Mod1.ub(p),'-k'); hold on;
                text(mean([g+.2,g_comp-.2]), (.3)*Mod1.ub(p), asterisk{g},'FontSize',Fsize,'HorizontalAlignment','center','VerticalAlignment','bottom');
            else
                plot([1.2, 2.8], [.95 .95]*Mod1.ub(p),'-k'); hold on;
                text(mean([1.2, 2.8]), (.95)*Mod1.ub(p), asterisk{g},'FontSize',Fsize,'HorizontalAlignment','center','VerticalAlignment','bottom');
            end       
        end  
    end
end

%% Compile data table for plotting/test
function [D, GroupDat, SubDat] = compile_param_data(M, block_idx, modNum, dataset_label, wholeBlockOutput)
    groups_labels = ["control","amygdala","VS"];
    nPars = length(M.WhatWhere.control{modNum}.plabels);
    GroupDat = cell(1,nPars); % for reporting M & SEM
    SubDat   = cell(1,nPars);
    D = table; % table for all group data
    groups_to_plot = 1:3; % include all three groups
    for g = groups_to_plot
        tempD = table; % data for this group
        group_label = groups_labels(g);
        Mod1 = M.(dataset_label).(group_label){modNum};  
        
        sub_ids = wholeBlockOutput.(dataset_label).(group_label).subj_idx;   
        switch dataset_label
            case 'Costa16'  
                det_idx = block_idx.(dataset_label).(group_label).deterministic_session;
                params = cell2mat(Mod1.SessionFit.fitpar.("what")(~det_idx));            
                sub_ids = sub_ids(~det_idx);
            case 'WhatWhere'            
                params = cell2mat(Mod1.SessionFit.fitpar.("Combined"));
        end      
        numSess = size(params,1);
        subject_set = unique(sub_ids);   
    
        % loop through params      
        for p = 1:length(Mod1.plabels)        
            GroupDat{p}.(group_label) = params(:,p);        
            tempD.("param"+p) = params(:,p);    
    
            % store average values by subject
            for sj = 1:length(subject_set)
                sub_idx = subject_set(sj)==sub_ids;
                sess_id = block_idx.(dataset_label).(group_label).sessionNum(sub_idx);
                SubDat{p}.(group_label)(sj) = mean(params(sess_id,p),'omitnan');
            end
        end
        
        % form data table
        tempD.group   = repmat(group_label,numSess,1);
%         tempD.subject = sub_ids';
        D = [D; tempD];
    end
    
    % obtain percentage of session completed by subject (mean-centered)
    load("dataset/Regression_BlockData.mat",'BlockData');
    SessionData = BlockData(BlockData.block_in_sess_ID==1,:);
    D2 = SessionData(SessionData.task==dataset_label,:);
    D.sess_perc = D2.sess_perc;
    D.subject   = D2.subject;
end