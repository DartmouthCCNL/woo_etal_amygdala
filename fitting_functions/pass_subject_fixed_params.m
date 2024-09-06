function [all_stats] = pass_subject_fixed_params(dataset_label, models, model_num, all_stats)
    %% if passing fixed rho values for each subject
    if strcmp(dataset_label,'Costa16')
        fitType = "what";
    else
        fitType = "Combined";
    end
    
    models_list = string;
    for k = 1:length(models)
        models_list(k) = models{k}.name;
    end
    
    thisMod = models{model_num};
    if contains(thisMod.name,'SubjectFixed')&&contains(thisMod.name,'Rho')
        FixParam = "\rho";

        SourceModel = strrep(models_list(model_num),'SubjectFixedRho','2betaR');
        if ~any(contains(models_list, SourceModel))
            error("Source model for \rho not identified");
        end
        sourceNum = find(strcmp(models_list,SourceModel));
        if sourceNum==model_num
            error(model_num+": Source model # is identical to target model #");
        end

        SourceModel = models{sourceNum};
        disp("Source model identified: ("+sourceNum+") "+SourceModel.name);
        param_idx = contains(SourceModel.plabels, FixParam);
        if isempty(param_idx)
            error("Param not identified");
        else
            disp("Param identified: "+FixParam+" ("+find(param_idx)+")");
        end

        animal_set = strings(1,length(all_stats));
        for i = 1:length(all_stats); animal_set(i) = all_stats{i}.animal_ids; end
        animal_set = unique(animal_set);
        
        % assign fixed rho value per each subject
        if ~SourceModel.subjectfit_exists
            error("No subject fit data.");
        end

        for i = 1:length(all_stats)
            animal_idx = find(strcmp(animal_set,all_stats{i}.animal_ids));
            if isempty(animal_idx)
                error(">>>>>>>> Unidentified animal id: "+all_stats{i}.animal_ids);
            end
            SourcePar = SourceModel.SubjectFit.fitpar.(fitType){animal_idx};
            all_stats{i}.SubjectFixed_Rho = SourcePar(param_idx);
        end
        disp("Subject-fixed rho values assigned.")
    end
end