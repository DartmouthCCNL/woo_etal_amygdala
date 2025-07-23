%% Plot time course of performance

plot_all_breakdowns = 0;    % toggle on to plot by each group & schedule, and by each subjects
save_output_dat = 0;

output_dat = "output\behavior\pBetter_runAvg.mat";
if exist(output_dat,'file')
    load(output_dat,'pBetterStruct');
    disp("Output file loaded");
else
    pBetterStruct = struct;
    %% compute P(Bettter) across groups and save output
    for d = 1:numel(datasets)
        dataset_label = datasets{d}; 
        pBetterStruct.(dataset_label) = struct;
        schedule_subsets = schedules.subsets;
        switch dataset_label
            case 'Costa16'
                lesion_groups = ["control", "amygdala", "VS"];  
                data_dir = "dataset/preprocessed/all_stats_";
                task_subsets = "what";
             case 'WhatWhere'
                lesion_groups = ["control17", "control21", "control", "amygdala", "VS"];  
                task_subsets = ["what","where"];
                data_dir = "dataset/preprocessed/WW_stats_";
                task_subsets = ["what","where"];
        end
    
        % Compile choice data for each group
        for g = 1:length(lesion_groups)
            group_label = lesion_groups(g); disp(dataset_label+", "+group_label);
    
            if strcmp(dataset_label,"WhatWhere")&&strcmp(lesion_groups(g),"control")
                % combine two controls for WW tasks
                % 2017 VS control
                data_file_name = data_dir + group_label +"17" + ".mat";
                load(data_file_name,'all_stats'); c17 = all_stats(:);
                % 2021 amyg control
                data_file_name = data_dir + group_label +"21" + ".mat";
                load(data_file_name,'all_stats'); c21 = all_stats(:);
                all_stats = [c17; c21];
            else
                data_file_name = data_dir + lesion_groups(g) + ".mat";
                load(data_file_name,'all_stats');
            end
            
            % initialize
            pBetterStruct.(dataset_label).(group_label) = struct;
            alignedStats = struct;
            
            %% loop through each block
            for b = 1:length(all_stats)
                block_stats = all_stats{b}; 
                if isfield(block_stats,'prob1000')&&block_stats.prob1000(1)
                    continue;
                end
                revPoint = block_stats.block_addresses(2);
                idx1 = 1:20;  % (No stay/switch info for 1st trial)
                idx2 = revPoint-20:revPoint-1;    % 20 before Rev
                idx3 = revPoint:revPoint+20-1;    % 20 after Rev
                idx4 = 61:80;                % last 20 trials
                aligned_idx = [idx1, idx2, idx3, idx4];
                chooseBetter = block_stats.c==block_stats.hr_shape;
                tempBlock.cBetter = chooseBetter(aligned_idx)';
    
                if strcmp(dataset_label,'Costa16')||block_stats.what
                    blockType = "what";
                else
                    blockType = "where";
                end
                alignedStats = append_to_fields(alignedStats, {tempBlock} ); 
                
                alignedStats.animal_id(b) = block_stats.animal_ids;
                alignedStats.blockType(b) = blockType;
                for ss = 1:numel(schedule_subsets)
                    if block_stats.(schedule_subsets(ss))(1)
                        alignedStats.schedule(b) = schedule_subsets(ss);
                    end
                end
            end       
    
            %% calculate across all blocks
            animal_set = [unique(alignedStats.animal_id), "allSub"];
            schedule_set = [schedule_subsets, "stochastic"];
            
            for tt = 1:numel(task_subsets)
                task_idx = alignedStats.blockType==task_subsets(tt);
                for aa = 1:length(animal_set)
                    if strcmp(animal_set(aa),"allSub")
                        subj_idx = true(size(alignedStats.animal_id));
                    else
                        subj_idx = alignedStats.animal_id==animal_set(aa);
                    end            
                    for ss = 1:length(schedule_set)
                        if strcmp(schedule_set(ss),"stochastic")
                            sched_idx = true(size(alignedStats.schedule));
                        else
                            sched_idx = alignedStats.schedule==schedule_set(ss);
                        end
                        
                        tempMet = struct;
                        this_idx = task_idx&subj_idx&sched_idx;
                        
                        for t = 1:80   
                            better = alignedStats.cBetter(this_idx,t);
                            n  = sum(~isnan(better));
                            p = mean(better, 'omitnan');
                            tempMet.mean(1,t) = p;
                            tempMet.sem(1,t) = sqrt(p*(1-p)/n);
                        end
                        pBetterStruct.(dataset_label).(group_label).(task_subsets(tt)).(animal_set(aa)).(schedule_set(ss)) = tempMet;
                    end
                end        
            end
        end
    end
    if save_output_dat
        save(output_dat,'pBetterStruct');
    end
end

%% plot figures - all group data
figure(1); clf
set(gcf,'Units','normalized','Position',[0,0,0.5,0.27], 'Color','w');

% loop through each task and block type
for pp = 1:3
    if pp==1
        dataset_label = 'Costa16';
        block_type = 'what'; tlt = "What-only";
    else
        dataset_label = 'WhatWhere';
        if pp==2
            block_type = 'what'; tlt = "What";
        else
            block_type = 'where'; tlt = "Where";
        end
    end
    subplot(1,3,pp);
    for g = 1:length(groups.labels)
        Xmean = pBetterStruct.(dataset_label).(groups.labels(g)).(block_type).allSub.stochastic.mean;
        Xsem = pBetterStruct.(dataset_label).(groups.labels(g)).(block_type).allSub.stochastic.sem;
        shadedErrorBar(1:80, Xmean,Xsem, 'lineProps',{'LineWidth',1.75, 'Color',groups.colors{g}}); hold on;
    end
    ylim([0 1]); ylabel("P(Better)");
    xline(40.5,'--k'); xlabel("Trials");
    title(tlt); set(gca,'FontSize',16,'LineWidth',.5);
end
legend(groups.labels,'fontsize',10,'location','southwest');

%% Plot by each group & schedule
if plot_all_breakdowns
    sched_cols = [prob80_cols; prob70_cols; prob60_cols];

    for g = 1:length(groups.labels)
        figure(20+g); clf
        set(gcf,'Units','normalized','Position',[0,0,0.5,0.28], 'Color','w');    
        for pp = 1:3
            if pp==1
                dataset_label = 'Costa16';
                block_type = 'what'; tlt = "What-only";
            else
                dataset_label = 'WhatWhere';
                if pp==2
                    block_type = 'what'; tlt = "What";
                else
                    block_type = 'where'; tlt = "Where";
                end
            end
            subplot(1,3,pp);
            for ss = 1:length(schedule_subsets)
                Xmean = pBetterStruct.(dataset_label).(groups.labels(g)).(block_type).allSub.(schedule_subsets(ss)).mean;
                Xsem = pBetterStruct.(dataset_label).(groups.labels(g)).(block_type).allSub.(schedule_subsets(ss)).sem;
                shadedErrorBar(1:80, Xmean,Xsem, 'lineProps',{'LineWidth',1.75, 'Color',sched_cols{ss,g}}); hold on;
            end                
            if pp==1; legend(schedules.labels, 'Location','southeast','box','off'); end
            ylim([0 1]); ylabel("P(Better)");
            xline(40.5,'--k', 'HandleVisibility','off'); xlabel("Trials");
            title(tlt); set(gca,'FontSize',16,'LineWidth',.5);
        end 
        sgtitle(groups.labels(g));
    end
end

%% Plot by each subject
if plot_all_breakdowns
    close all
    for d = 1:numel(datasets)
        switch datasets{d}
            case 'Costa16'
                lesion_groups = ["control", "amygdala", "VS"];  
                blockTypes = "what"; tlt = "What-only";
                block_cols = groups.colors;
             case 'WhatWhere'
                lesion_groups = ["control17", "control21", "amygdala", "VS"];  
                blockTypes = ["what","where"]; tlt = "What/Where";
                block_cols = sched_cols([1,3],[1 1 2 3]);
        end

        for g = 1:length(lesion_groups)
            figure(300+d*10+g); clf                      
            thisDat = pBetterStruct.(datasets{d}).(lesion_groups(g));      
            animal_ids = string(setdiff(fieldnames(thisDat.what),'allSub'))';
            if length(animal_ids)<=4
                set(gcf,'Units','normalized','Position',[0,0,0.7,0.28], 'Color','w');
                rNum = 1; cNum = 4;
            elseif length(animal_ids)>4
                set(gcf,'Units','normalized','Position',[0,0,0.54,0.52], 'Color','w'); 
                rNum = 2; cNum = 3;
            end
            for aa = 1:length(animal_ids)
                subplot(rNum,cNum,aa);            
                for tt = 1:length(blockTypes)  
                    Xmean = thisDat.(blockTypes(tt)).(animal_ids(aa)).stochastic.mean;
                    Xsem = thisDat.(blockTypes(tt)).(animal_ids(aa)).stochastic.sem;
                    shadedErrorBar(1:80, Xmean,Xsem, 'lineProps',{'LineWidth',1.75, 'Color',block_cols{tt,g}}); hold on;
                end
                ylim([0 1]); ylabel("P(Better)");
                xline(40.5,'--k', 'HandleVisibility','off'); xlabel("Trials");
                title(animal_ids(aa)); set(gca,'FontSize',16,'LineWidth',.5);
                if d>1&&aa==1; legend(blockTypes,'Location','southeast','box','off'); end
            end        
            sgtitle(tlt+", "+lesion_groups(g));                       
        end
    end
end


