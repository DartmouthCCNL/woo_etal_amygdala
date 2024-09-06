%% subfunction: load models
function [M, block_idx, AllStats] = load_fitted_Params_dist_all_dataset(loaded_groups, initialize_model_fun, datasets, pass_rho_vals)
    if ~exist('datasets','var')
        datasets = {'Costa16','WhatWhere'};
    end
    if ~exist('pass_rho_vals','var')
       pass_rho_vals = true; 
    end
    initialize_model_fun = str2func(initialize_model_fun);
    M = struct; 
    block_idx = struct;
    AllStats = struct;

    % load model information
    fname = "output/model/Combined/Model_struct.mat";
    if exist(fname,'file')
        load(fname,"M","block_idx");
        return;
    end

    for d = 1:numel(datasets)
        dataset_label = datasets{d};
        %% load output
        disp("========================"+dataset_label+"========================");
        switch dataset_label
            case 'Costa16'            
                schedule_subsets = ["prob6040","prob7030","prob8020","prob1000"]; 
                data_dir = "dataset/preprocessed/all_stats_";
                session_tasks = "what";
            case 'WhatWhere'
                schedule_subsets = ["prob6040","prob7030","prob8020"];
                session_tasks = "Combined";
                data_dir = "dataset/preprocessed/WW_stats_";
        end
        %% 0. load and compile results
        
        for g = 1:length(loaded_groups)
            disp(loaded_groups(g));
            % Load processed_data & model fits
            if strcmp(dataset_label,"WhatWhere")&&strcmp(loaded_groups(g),"control")
                group_label = loaded_groups(g);
                % 2017 VS control
                data_file_name = data_dir + group_label +"17" + ".mat";
                load(data_file_name,'all_stats'); c17 = all_stats(:);
                [models] = initialize_model_fun(dataset_label, group_label+"17");
                % 2021 amyg control
                data_file_name = data_dir + group_label +"21" + ".mat";
                load(data_file_name,'all_stats'); c21 = all_stats(:);
                [models21] = initialize_model_fun(dataset_label, group_label+"21");
                all_stats = [c17; c21]';
                % combine two control group models
                for m = 1:length(models)
                    if ~models21{m}.fit_exists||~models{m}.fit_exists 
                        disp(m+". No block fit data"); 
                    else
                        models{m}.fitpar = [models{m}.fitpar; models21{m}.fitpar];
                        models{m}.ll = [models{m}.ll; models21{m}.ll];
                        models{m}.aic = [models{m}.aic; models21{m}.aic];
                        models{m}.bic = [models{m}.bic; models21{m}.bic];
                        models{m}.nlike = [models{m}.nlike; models21{m}.nlike];
                    end
                    if ~models21{m}.sessionfit_exists||~models{m}.sessionfit_exists
                        disp(m+". No session fit data"); 
                    else
                        for tt = 1:numel(session_tasks)
                            blockType = session_tasks(tt);
                            models{m}.SessionFit.fitpar.(blockType) = [models{m}.SessionFit.fitpar.(blockType); models21{m}.SessionFit.fitpar.(blockType)];
                            models{m}.SessionFit.ll.(blockType) = [models{m}.SessionFit.ll.(blockType); models21{m}.SessionFit.ll.(blockType)];
                            models{m}.SessionFit.aic.(blockType) = [models{m}.SessionFit.aic.(blockType); models21{m}.SessionFit.aic.(blockType)];
                            models{m}.SessionFit.bic.(blockType) = [models{m}.SessionFit.bic.(blockType); models21{m}.SessionFit.bic.(blockType)];
                            models{m}.SessionFit.nlike.(blockType) = [models{m}.SessionFit.nlike.(blockType); models21{m}.SessionFit.nlike.(blockType)];
                        end  
                    end
                    % combine single subject fit
                    if ~models21{m}.subjectfit_exists||~models{m}.subjectfit_exists
                        disp(m+". No subject fit data"); 
                    else
                        for tt = 1
                            blockType = session_tasks(tt);
                            models{m}.SubjectFit.fitpar.(blockType) = [models{m}.SubjectFit.fitpar.(blockType); models21{m}.SubjectFit.fitpar.(blockType)];
                            models{m}.SubjectFit.ll.(blockType) = [models{m}.SubjectFit.ll.(blockType); models21{m}.SubjectFit.ll.(blockType)];
                            models{m}.SubjectFit.aic.(blockType) = [models{m}.SubjectFit.aic.(blockType); models21{m}.SubjectFit.aic.(blockType)];
                            models{m}.SubjectFit.bic.(blockType) = [models{m}.SubjectFit.bic.(blockType); models21{m}.SubjectFit.bic.(blockType)];
                            models{m}.SubjectFit.nlike.(blockType) = [models{m}.SubjectFit.nlike.(blockType); models21{m}.SubjectFit.nlike.(blockType)];
                        end
                    end
                end            
            else
                % Brain-lesioned groups
                load(data_dir+loaded_groups(g)+".mat",'all_stats','group_label');
                if ~strcmp(group_label,loaded_groups(g))
                    error('Different lesion group label');
                end
                disp(dataset_label+" - "+group_label);
                % load fitted model
                [models] = initialize_model_fun(dataset_label, group_label);
            end
    
            %% Set flag if passing fixed param(s) for each subject
            models_list = string;
            for m = 1:length(models)
                models_list(m) = models{m}.name;
            end
            rho_flag = 0;
            if pass_rho_vals
                if sum(contains(models_list,'FixedRho'))>0
                    FixParam = "\rho";
                    SourceModel = "RL25_dynamicVchoLinRelDec_omegaV_2betaR";
                    if sum(contains(models_list,SourceModel))==0
                        error("Source model for \rho not identified");
                    end
                    SourceModel = models{strcmp(models_list, SourceModel)};
                    param_idx = strcmp(SourceModel.plabels, FixParam);
                    animal_set = strings(1,length(all_stats));
                    for i = 1:length(all_stats); animal_set(i) = all_stats{i}.animal_ids; end
                    animal_set = unique(animal_set);
        
                    % assign fixed rho value per each subject
                    for i = 1:length(all_stats)
                        animal_idx = find(strcmp(animal_set, all_stats{i}.animal_ids));
                        if isempty(animal_idx)
                            error(">>>>>>>> Unidentified animal id: "+all_stats{i}.animal_ids);
                        end
                        SourcePar = SourceModel.SubjectFit.fitpar.(session_tasks(1)){animal_idx};
                        all_stats{i}.SubjectFixed_Rho = SourcePar(param_idx);
                    end
                    rho_flag = 1;
                end
            end
            %% setting block index
            numSession = 0;
            abs_sess_id = 0;
            for b = 1:length(all_stats)
                if strcmp(dataset_label,'WhatWhere')
                    block_idx.(dataset_label).(group_label).what(b) = all_stats{b}.what;
                    block_idx.(dataset_label).(group_label).where(b) = all_stats{b}.where;
                    
                    % obtain session #
                    if abs_sess_id~= all_stats{b}.session_idx
                        abs_sess_id =  all_stats{b}.session_idx;
                        numSession = numSession + 1;
                        if rho_flag
                            block_idx.(dataset_label).(group_label).subjectFixedRho(numSession) = all_stats{b}.SubjectFixed_Rho;
                        end
                    end
                    block_idx.(dataset_label).(group_label).sessionNum(b) = numSession;
                    
                elseif strcmp(dataset_label,'Costa16')
                    block_idx.(dataset_label).(group_label).what(b) = true;
                    block_idx.(dataset_label).(group_label).where(b) = false;
                    
                    % obtain session #
                    if abs_sess_id~= all_stats{b}.session_date
                        abs_sess_id =  all_stats{b}.session_date;
                        numSession = numSession + 1;
                        if rho_flag
                            block_idx.(dataset_label).(group_label).subjectFixedRho(numSession) = all_stats{b}.SubjectFixed_Rho;
                        end
                    end
                    block_idx.(dataset_label).(group_label).sessionNum(b) = numSession;
                    if all_stats{b}.prob1000(1)
                        block_idx.(dataset_label).(group_label).deterministic_session(numSession) = true;
                    else
                        block_idx.(dataset_label).(group_label).deterministic_session(numSession) = false;
                    end
                end
                for s = 1:numel(schedule_subsets)
                    block_idx.(dataset_label).(group_label).(schedule_subsets(s))(b) = all_stats{b}.(schedule_subsets(s))(1);
                end
            end    
            if strcmp(dataset_label,'Costa16')
               block_idx.(dataset_label).(group_label).stochastic = ~block_idx.(dataset_label).(group_label).prob1000;
            end
           
            M.(dataset_label).(group_label) = models;
            AllStats.(dataset_label).(group_label) = all_stats;
        end
    end
end