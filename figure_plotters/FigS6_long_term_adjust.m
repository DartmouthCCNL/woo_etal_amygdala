dataset_lbs = ["WHAT-only","WHAT/WHERE"];

MET_set = ["ERDS_stim", "ERDS_loc","medianRT", "initialArbWeight"]; % 
MET_label = ["ERDS_{Stim}", "ERDS_{Action}"," RT (msec)", "\Omega_0 (effective \omega_0)"];   %

schedule_label = "stochastic";

selectModNum = 7;
initialize_model_fun = "initialize_models";
[M, block_idx, AllBlockStats] = load_fitted_Params_dist_all_dataset(groups.labels, initialize_model_fun);

wholeBlockOutput = assign_initial_arb_weight(M, groups, selectModNum, block_idx, wholeBlockOutput);

%% Plot figure: What-only task
figure(60); clf;
set(gcf,'Units','normalized','Position',[0,0,0.51,0.51], 'Color','w');  % 2-by-2

disp_sub_stats = 1;     % individual stats
smoothing = 1;
inset_not_stats = 1;    % 0 = report stats in numbers
                        % 1 = second sub-panel on the right
                        % 2 = inset at bottom corner              
for m = 1:length(MET_set)
    fprintf('\n\n');
    disp("===================="+MET_label(m)+"====================");        
    for d = 1
        dataset_label = datasets{d};
        disp(">>>>>>>>>>> "+dataset_label);
        all_output = wholeBlockOutput.(dataset_label);
        SP = subplot(2,2,m);
        SP.Position(1) = .075 + (mod(m+1,2))*0.49;
        SP.Position(3) = 0.31;    
        SP.Position(4) = 0.3; 

        % compile subject data
        [timeseriesMET] = compile_sub_dat(dataset_label, all_output, MET_set(m), groups, schedule_label, disp_sub_stats);
        
        % average across subjects
        Beta = nan(1,3); Pval = nan(1,3); SE = nan(1,3);
        for g = 1:numel(groups.labels)
            group_label = groups.labels(g);  
            disp(group_label+"-----------");
            subject_labels = unique(all_output.(group_label).subj_idx);
            numSub = length(subject_labels);
            % plot normalized bin
            NormBin = nan(numSub,100);
            for s = 1:numSub
                tsin = timeseries(timeseriesMET.(groups.labels(g)){s});
                timepoints = linspace(1,tsin.Time(end),100);
                tsout = resample(tsin,timepoints);
                NormBin(s,:) = tsout.Data;
                % regression using normalized data
                stats = regstats(tsout.Data',(1:100)'/100);
                disp(subject_labels(s)+"  -  reg: b = "+num2str(stats.tstat.beta(2),3)+", p = "+num2str(stats.tstat.pval(2),3));
            end
            y = mean(NormBin,1,'omitnan'); 
            errBar = std(NormBin,1,'omitnan')/sqrt(size(NormBin,1));
            
            % sig test: BEFORE smoothing
            numPerc = repmat(1:100,[size(NormBin,1),1])./100;
            stats = regstats(NormBin(:),numPerc(:));
            Beta(g) = stats.tstat.beta(2);  SE(g) = stats.tstat.se(2);
            Pval(g) = stats.tstat.pval(2);
            ast = ""; LS = ':';
            fitCol = ones(1,3)*.3;
            if Pval(g)<.05/18; ast = "∗"; LS = '-'; fitCol = groups.colors{g}; end
            
            if smoothing
                y = smooth(y)';     % smooth with span of 5
                errBar = smooth(errBar)';
            end    
            shadedErrorBar([1:length(y)], y, errBar, 'lineProps',{'LineWidth', 1.5, 'Color',groups.colors{g},'linestyle','-'});
            hold on;                
            
            % fit slope
            p = polyfit(1:length(y),y,1);
            plot([1:length(y)]*p(1)+p(2),'color',fitCol,'LineWidth',1,'LineStyle',LS,'HandleVisibility','off');
            text(100,((length(y)+1)*p(1)+p(2)), ast,'Color',groups.colors{g},'FontSize',gca_fontsize,'Units','data','HorizontalAlignment','left','VerticalAlignment','middle');
            
            % beta values
            if inset_not_stats==0
                if d==1&&m==1
                    sTxt = ["\bf\fontsize{12}"+groups.labels(g),"\rm\fontsize{12}\beta = "+num2str(round(Beta(g)*10^4)/10^4,3),"\it{p} = "+num2str(Pval(g),3)];
                    text(0.2+0.33*(g-1),0.01,sTxt,'Units','normalized','Color',groups.colors{g},'HorizontalAlignment','center','VerticalAlignment','bottom');
                else
                    sTxt = ["\rm\fontsize{12}\beta = "+num2str(round(Beta(g)*10^4)/10^4,3),"\it{p} = "+num2str(Pval(g),3)];
                    text(0.2+0.33*(g-1),0.01,sTxt,'Units','normalized','Color',groups.colors{g},'HorizontalAlignment','center','VerticalAlignment','bottom');
                end
            end
        end
        disp("beta's = "+Beta); % display beta values
        disp("p-val's = "+Pval);
        
        % axis labels
        ylabel(MET_label(m)); 
        if m>=length(MET_set)-1
            xlabel("Sessions completed (%)");
        end
        xlim([0 100]); xticks(0:25:100);
        if m==1
            ylim([0.3 1]); yticks(0.3:.1:1.0); SP.YTickLabel = {'','0.4','','0.6','','0.8','','1'};
        elseif m==2
            ylim([0.4 1]); yticks(0.4:.1:1.0); SP.YTickLabel = {'0.4','','0.6','','0.8','','1'};
        elseif m==3
            ylim([125 265]); yticks(125:25:265); SP.YTickLabel = {'','150','','200','','250'};
        elseif m==4
            ylim([0 1]); yticks(0:.25:1.0);
        end
        set(SP,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1, 'tickdir','out','Box','off');
        
        fprintf('\n');
        
        if inset_not_stats~=0
            if d==2&&m==1
                legend(groups.labels,'box','off','FontSize',gca_fontsize-1,'Location','southwest');
            end
            
            if inset_not_stats
                inset = axes('Position',[SP.Position(1)+SP.Position(3)*1.025, SP.Position(2)+SP.Position(4)*0.145, SP.Position(3)*.15, SP.Position(4)*.75]);
                yticks([]);
                yyaxis right
                xlabel("Groups");
                inset.YAxis(1).Visible = 'off';
                inset.YAxis(2).Color = inset.XAxis.Color;
            end
            
            % bar plots in the inset
            for g = 1:numel(groups.labels)
                bar(g, Beta(g),'FaceColor',groups.colors{g},'EdgeColor',groups.colors{g}); hold on;
                errorbar(g,Beta(g),SE(g),'LineStyle','none','Marker','none','Color',ones(1,3).*double(g==1)*0.5);
                if Pval(g)<.05/18
                    if Beta(g)>0
                        astY = Beta(g)+SE(g);
                    else
                        astY = 0;
                    end
                    text(g,astY,"∗",'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',gca_fontsize-4,'Color',groups.colors{g}); 
                end
            end
            xlim([0, 4]); xticks(1:3); xticklabels([]);
            if m==1
                insetLim1 = -.3; insetLim2 = .20;
                yticks(-.30:0.1:.20);
                
                if d==1
                    % cont/amyg/VS
                    text(.9,0.12,"cont",'FontSize',gca_fontsize-4,'FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','color',groups.colors{1},'Rotation',60);
                    text(1.9,0.12,"amyg",'FontSize',gca_fontsize-4,'FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','color',groups.colors{2},'Rotation',60);
                    text(3.1,0.12,"VS",'FontSize',gca_fontsize-4,'FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','color',groups.colors{3},'Rotation',60);
                end
                
            elseif m==2
                insetLim1 = -.2; insetLim2 = .2;
                yticks(-.2:0.1:.20);
            elseif m==3
                insetLim1 = -21; insetLim2 = 20;
            elseif m==4
                insetLim1 = -.2; insetLim2 = .21;
                yticks(-.2:0.1:.20);
            end
            ylim([insetLim1, insetLim2]);                
            title("\beta",'FontWeight','normal');
            set(inset,'FontName','Helvetica','FontSize',gca_fontsize-4,'FontWeight','normal','LineWidth',1.0, 'tickdir', 'in','Box','off');
        end  
        
        axes(SP);   % bring main panel to the front
    end           
end
    
%% subfunc
function wholeBlockOutput = assign_initial_arb_weight(M, groups, selectModNum, block_idx, wholeBlockOutput)
datasets = fieldnames(M);

for d = 1:length(datasets)
    dataset_label = datasets{d};

    for g = 1:numel(groups.labels)
        group_label = groups.labels(g);
        numBlocks = length(block_idx.(dataset_label).(group_label).sessionNum);
        thisModel = M.(dataset_label).(group_label){selectModNum};
        betaFlag = "";
        if contains(thisModel.name,"SubjectFixedRho")
            betaFlag = "SubjectFixedRho";
        elseif contains(thisModel.name,"2betaR")
            betaFlag = "freeRho";
        end
        
        wholeBlockOutput.(dataset_label).(group_label).initialArbWeight = nan(numBlocks,1);
        wholeBlockOutput.(dataset_label).(group_label).omega0 = nan(numBlocks,1);
        for b = 1:numBlocks
            % obtain fitted params
            session_num = block_idx.(dataset_label).(group_label).sessionNum(b);
            if d==1
                fitpar0 = thisModel.SessionFit.fitpar.what{session_num};
            else
                fitpar0 = thisModel.SessionFit.fitpar.Combined{session_num};
            end
            
            omega0 = fitpar0(strcmp(thisModel.plabels,"\omega_0"));
            if betaFlag==""
                initialState = omega0;
            else
                if strcmp(betaFlag,"SubjectFixedRho")
                    Rho = block_idx.(dataset_label).(group_label).subjectFixedRho(session_num);
                elseif strcmp(betaFlag,"freeRho")
                    Rho = fitpar0(strcmp(thisModel.plabels,"\rho"));
                end
                OmegaStim = Rho*omega0;
                OmegaAct = (1-Rho)*(1-omega0);
                EffOmega0 = OmegaStim./(OmegaStim + OmegaAct);                    
                initialState = EffOmega0;
            end
            wholeBlockOutput.(dataset_label).(group_label).omega0(b) = omega0;
            wholeBlockOutput.(dataset_label).(group_label).initialArbWeight(b) = initialState;
        end
    end                        
end
disp("Initial arbitration weights assigned.");
end

%% subfunc
function [timeseriesMET] = compile_sub_dat(dataset_label, all_output, MET_name, groups, schedule_label, disp_sub_stats)
display_msg = 0;

timeseriesMET = struct;
timeseriesMET.schedule_label = schedule_label;

for g = 1:numel(groups.labels)
    group_label = groups.labels(g);
    if display_msg; disp("------------------"+group_label+"------------------"); end

    subject_labels = unique(all_output.(group_label).subj_idx);
    numSub = length(subject_labels);
    
    all_Met_chrono = [];
    blocks_completed_num = [];
    for s = 1:numSub
        % find subject index
        thisSub_idx = all_output.(group_label).subj_idx==subject_labels(s); 
        if strcmp(dataset_label,"Costa16")
            if strcmp(schedule_label,"stochastic")
                thisSub_idx = thisSub_idx&(~all_output.(group_label).prob1000);
            else
                thisSub_idx = thisSub_idx&(all_output.(group_label).(schedule_label));
            end
        elseif strcmp(dataset_label,"WhatWhere")
            if strcmp(schedule_label,"stochastic")
                thisSub_idx = thisSub_idx;
            end
        end
        if sum(thisSub_idx)==0; continue;   end

        thisMET_timeseries = all_output.(group_label).(MET_name)(thisSub_idx);
        all_Met_chrono = [all_Met_chrono; thisMET_timeseries]; 
        blocks_completed_num = [blocks_completed_num; (1:length(thisMET_timeseries))'];

        timeseriesMET.(group_label){s} = thisMET_timeseries;

        if display_msg&&disp_sub_stats
            % correlation b/w num blocks experienced vs. metrics
            [r,p] = corr((1:length(thisMET_timeseries))', thisMET_timeseries,'rows','pairwise');
            % regression
            stats = regstats(thisMET_timeseries, (1:length(thisMET_timeseries))');
            disp(subject_labels(s)+" corr: r = "+num2str(r,3)+", p = "+num2str(p,3));
            disp(subject_labels(s)+"  -  reg: b = "+num2str(stats.tstat.beta(2),3)+", p = "+num2str(stats.tstat.pval(2),3));
        end
    end
    
    % group analysis stats using raw data
    [r,p] = corr(blocks_completed_num, all_Met_chrono,'rows','pairwise');
    stats = regstats(all_Met_chrono, blocks_completed_num);
    if display_msg
        disp(group_label+" all subjects -  Regression: beta = "+num2str(stats.tstat.beta(2),3)+", p = "+num2str(stats.tstat.pval(2),3));
    end
end
end