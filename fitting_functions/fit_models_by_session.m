function fit_models_by_session(dataset_code, group_code)
    %% fitting & simulating WhatWhere task
    addpath(genpath(pwd));

    switch dataset_code
        case 1
            dataset_label = "Costa16";
            task_subsets = "what";
            data_dir = "dataset/preprocessed/all_stats_";
            switch group_code
                case 1
                    lesion_group = "control";
                case 2
                    lesion_group = "amygdala";
                case 3
                    lesion_group = "VS";
            end

        case 2
            dataset_label = "WhatWhere";
            task_subsets = "Combined";
            data_dir = "dataset/preprocessed/WW_stats_";
            switch group_code
                case 1
                    lesion_group = "control17";
                case 2
                    lesion_group = "control21";
                case 3
                    lesion_group = "amygdala";
                case 4
                    lesion_group = "VS";
            end
    end

    %% fit & sim param
    numFitRun = 100;    disp("# of fitting = "+numFitRun);

    load_fit_output = true;
    load_sim_output = true;
    pseudorandom_side = false;

    %% load
    data_file_name = data_dir + lesion_group + ".mat";
    load(data_file_name, 'all_stats','group_label');          % load all stats structures
    if ~strcmp(group_label,lesion_group)
        error('Different lesion group label');
    end
    disp(group_label+" data loaded");

    %% initialize models to be fitted  
    [models] = initialize_models(dataset_label, group_label, load_fit_output, load_sim_output, pseudorandom_side, numFitRun);

    models_list = string;
    for m = 1:length(models)
        models_list(m) = models{m}.name;
    end
    
    %%  loop through each model
    for m = 1:length(models)
        tic
        
        % if passing fixed rho values for each subject
        [all_stats] = pass_subject_fixed_params(dataset_label, models, m, all_stats);
        
        % rearrange into session-based stats
        [sess_stats] = rearrange_into_session(dataset_label, all_stats);
        
        % fitting
        disp(m+". fitting model (session-wise): " + models{m}.name);
        if sum(models_list==models{m}.extract_initpar_from)==0
            models{m}.extract_initpar_from = 'none';
        end
        if (strcmp(models{m}.extract_initpar_from,'None')||strcmp(models{m}.extract_initpar_from,'none'))
            extracted_model = {};
        else
            extracted_model = models{models_list==models{m}.extract_initpar_from};
            disp("   extracting initial values from "+extracted_model.name);
        end
        
        models{m} = session_fit_and_save(sess_stats, dataset_label, task_subsets, lesion_group, models{m}, extracted_model, numFitRun);
        
        ET = toc;
        disp("Elasped time is "+ET/60+" minutes");
        disp(datetime);
    end

    disp('Done!');

end