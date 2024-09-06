% ERDS simulation
groups_to_plot = 1;   % controls only
blocks_to_plot = 1;   % 1=What-only task; 2=What; 3=Where

markerAlp = 0.6;
roundNumBeta = 4;

%% Panel A: empirical data
MET.name = 'ERDS'; MET.label = 'ERDS';

figure(40); clf
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

        % regression
        stats = regstats(yy,xx);
        text(.05, .05, ["\beta = "+round(stats.tstat.beta(2)*10^roundNumBeta)/10^roundNumBeta,"\it{p} = \rm"+num2str(stats.tstat.pval(2),3)],'Units','normalized','HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',gca_fontsize);

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
[SimMet, M] = simulate_subfunc(groups, groups_to_plot, models_to_plot, {datasets{1}}, "Session", 0.05); 

for m = 1:numel(SimMet)
    figure(50+m); clf
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
                GroupDat = SimMet{m}.(dataset_label).(group_label);
                blockIDX = wholeBlockOutput.(dataset_label).(group_label).(task_subsets(b));

                % exclude deterministic schedule for What-only task
                if strcmp(task_labels(b),"What-only")
                    blockIDX = blockIDX & ~wholeBlockOutput.(dataset_label).(group_label).prob1000;
                end
                xx = GroupDat.ERDS_stim(blockIDX);
                yy = GroupDat.ERDS_loc(blockIDX);

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
                stats = regstats(yy,xx);
                text(.05, .05, ["\beta = "+round(stats.tstat.beta(2)*10^roundNumBeta)/10^roundNumBeta,"\it{p} = \rm"+num2str(stats.tstat.pval(2),3)],'Units','normalized','HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',gca_fontsize);

                % paired t-test
                [H,tpv,~,stats] = ttest(xx,yy,'Alpha',.05/3);
                cohensD = computeCohen_d(xx,yy,'paired');
                disp("t("+stats.df+") = "+num2str(stats.tstat,3)+", p = "+num2str(tpv,3)+", Cohen's d = "+cohensD);

                % model label
                title("Simulation: "+M.Costa16.(group_label){m}.label);

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


%% subfunc: simulate model
function [SimMet, M] = simulate_subfunc(groups, groups_to_plot, models_to_plot, datasets, fitType, perfBound)
    %% 0. load and compile results    
    SimMet = cell(1,length(models_to_plot));
    numSim = 100;         % # of simulation per parameter set
    same_revPoint = 1;    % if having the same reversal position as real experiment
    comp_idxes = 1:80;    % compute metrics from entire block
    
    % load model info
    load("output/model/Combined/Model_struct.mat", 'M','block_idx');

    %% Simulate from fitted params
    mod_cnt = 0;
    % run for each model
    for m = models_to_plot
        mod_cnt = mod_cnt + 1;
        
        for d = 1:numel(datasets)
            dataset_label = datasets{d};

            for g = groups_to_plot
                SimMet{mod_cnt} = struct;

                group_label = groups.labels(g);     disp(groups.labels(g));
                thisModel = M.(dataset_label).(group_label){m};
                disp(m+". Model: "+thisModel.name);

                player = struct;
                player.label = strcat('algo_',thisModel.algo);
                
                sname = "output/model/"+dataset_label+"/simulated/"+group_label+"/"+fitType+"_simulated_metrics_nn"+numSim+"_"+thisModel.name+"_sameRev"+same_revPoint+"_pBound"+perfBound+".mat";
                if ~exist(sname,'file')
                    tic
                    load("dataset/preprocessed/all_stats_"+group_label+".mat"); 

                    numBlocks = length(block_idx.(dataset_label).(group_label).revTrial);
                    for b = 1:numBlocks
                        if block_idx.(dataset_label).(group_label).what(b)
                            blockType = 'what';
                        elseif block_idx.(dataset_label).(group_label).where(b)
                            blockType = 'where'; 
                        end
                        
                        % specify params to simulate
                        switch fitType
                            case "Block"
                                fitpar0 = thisModel.fitpar{b};   % use fitted params to each block
                            case "Session"
                                if d==1
                                    fitpar0 = thisModel.SessionFit.fitpar.(blockType){block_idx.(dataset_label).(group_label).sessionNum(b)};
                                else
                                    fitpar0 = thisModel.SessionFit.fitpar.Combined{block_idx.(dataset_label).(group_label).sessionNum(b)};
                                end
                        end
                        player.params = fitpar0;
                        
                        % set up block environment
                        if block_idx.(dataset_label).(group_label).prob6040(b)
                            HRprob = 0.6;
                        elseif block_idx.(dataset_label).(group_label).prob7030(b)
                            HRprob = 0.7;
                        elseif block_idx.(dataset_label).(group_label).prob8020(b)
                            HRprob = 0.8;
                        elseif block_idx.(dataset_label).(group_label).prob1000(b)
                            HRprob = 1.0;
                        end
                        if same_revPoint
                            revPoint = block_idx.(dataset_label).(group_label).revTrial(b); 
                            revRange = [revPoint, revPoint];     % use actual rev num
                        else
                            revRange = [30, 50];
                        end

                        % run sim N times
                        pbetter = nan(numSim,1);
                        ERDS_stim = nan(numSim,1); ERDS_loc = ERDS_stim;
                        empPerf = mean(all_stats{b}.c==all_stats{b}.hr_shape);    % observed P(Better)
                        parfor nn = 1:numSim
                            EntTemp = struct;
                            block_sim = simulateRandomBlock(HRprob, 80, revRange, nn*10000+b, upper(blockType));
                            stats_sim = simulateAgentBehavior(player, block_sim);
                            if perfBound>0
                                sd_cnt = 0;
                                simPerf = mean(stats_sim.c==block_sim.hr_shape);    % simulated P(Better)
                                devPerf = simPerf - empPerf;            
                                while abs(devPerf)>perfBound
                                    stats_sim = simulateAgentBehavior(player, block_sim);
                                    simPerf = mean(stats_sim.c==block_sim.hr_shape);    % simulated P(Better)
                                    devPerf = simPerf - empPerf;
                                    sd_cnt = sd_cnt + 1;
                                    if mod(sd_cnt,100)==0
                                        % change block env. if performance constraint is not met for every 100th iterations
                                        block_sim = simulateRandomBlock(HRprob, 80, revRange, nn*10000+b+sd_cnt, upper(blockType));
                                    end
                                end
                            end
                            choice_stim = stats_sim.c(comp_idxes);
                            choice_side = stats_sim.cloc(comp_idxes);
                            reward = stats_sim.r(comp_idxes); 
                            str_stim = choice_stim(1:end-1)==choice_stim(2:end); 
                            str_side = choice_side(1:end-1)==choice_side(2:end); 

                            pbetter(nn,1) = mean(stats_sim.c==block_sim.hr_shape);
                            EntTemp = copy_field_names(EntTemp, ...
                                    {Conditional_Entropy(str_stim, reward(1:end-1), "ERDS_stim"), ...
                                     Conditional_Entropy(str_side, reward(1:end-1), "ERDS_loc"), ...
                                     });                            
                            ERDS_stim(nn,1) = EntTemp.ERDS_stim;
                            ERDS_loc(nn,1) = EntTemp.ERDS_loc;
                        end


                        % take average from N simulation values
                        SimMet{mod_cnt}.(dataset_label).(group_label).pbetter(b,1) = mean(pbetter,'omitnan');
                        SimMet{mod_cnt}.(dataset_label).(group_label).ERDS_stim(b,1) = mean(ERDS_stim,'omitnan');
                        SimMet{mod_cnt}.(dataset_label).(group_label).ERDS_loc(b,1) = mean(ERDS_loc,'omitnan');

                        display_counter(b);
                    end
                    % save file
                    modSimStruct = SimMet{mod_cnt}.(dataset_label).(group_label);
                    save(sname, 'modSimStruct');
                    ET = toc;
                    disp("Elaspsed time is "+ET/60+" minutes.");
                    disp("File saved: "+sname); disp(datetime); 
                else
                    load(sname, 'modSimStruct');
                    SimMet{mod_cnt}.(dataset_label).(group_label) = modSimStruct; 
                    disp("File loaded: "+sname);
                end
            end
        end
    end
end
