function [this_model] = session_fit_and_save(sess_stats, dataset_label, task_subsets, group_label, this_model, extracted_model, numFitRun)
    if ~exist('numFitRun','var')
       numFitRun = 100;      % default # of initial random parameters to run
    end
    
    %% fitting a set of parameters to *each session*
    if ~this_model.sessionfit_exists
	
        session_num = length(sess_stats.what);
        disp(task_subsets);
        for tt = 1:numel(task_subsets) 
            disp("Fitting "+upper(task_subsets(tt))+" blocks");
            LL = NaN(session_num,1);    % initialize bin
            BIC = NaN(session_num,1);
            normLL = NaN(session_num,1);
            AIC = NaN(session_num,1);
            NumBlocks = NaN(session_num,1);
            fitpars = cell(session_num,1);
            
            parfor sesscnt = 1:session_num			
                initpars = this_model.initparpool;
                stats_subset = sess_stats.(task_subsets(tt)){sesscnt};  
                if isempty(stats_subset)
                    fitpars{sesscnt,1} = NaN(size(initpars{1}));
                    LL(sesscnt,1) = NaN;
                    AIC(sesscnt,1) = NaN;
                    BIC(sesscnt,1) = NaN;
                    normLL(sesscnt,1) = NaN;
                    NumBlocks(sesscnt,1) = 0;
                else
                    %% fit model using best fit parameters from less complex models
                    minLL = intmax; fitpar0 = [];
                    for i = 1:numFitRun
                        % fit using extracted params
                        if ~isempty(extracted_model)&&i>numFitRun/2
                            initpars{i}(1:numel(extracted_model.initpar)) = extracted_model.SessionFit.fitpar.(task_subsets(tt)){sesscnt};
                        end
                        % run fitting across blocks within same session
                        [qpar, negloglike] = fit_fun_task(stats_subset, this_model.fun, initpars{i}, this_model.lb, this_model.ub);
                        if negloglike<minLL
                            minLL = negloglike;
                            fitpar0 = qpar;
                        end
                    end             
                    tot_aic = 2*minLL + numel(this_model.initpar)*2;
                    tot_bic = 2*minLL + numel(this_model.initpar)*log(80*length(stats_subset));
                    nlike0 = exp(-1*minLL)^(1/(80*length(stats_subset)));

                    fitpars{sesscnt,1} = fitpar0;
                    LL(sesscnt,1) = minLL/length(stats_subset);
                    AIC(sesscnt,1) = tot_aic/length(stats_subset);
                    BIC(sesscnt,1) = tot_bic/length(stats_subset);
                    normLL(sesscnt,1) = nlike0;
                    NumBlocks(sesscnt,1) = length(stats_subset);
                    if mod(sesscnt,10)==0; disp(sesscnt+"/"+session_num); end                      
                end
            end
            % assign output
            this_model.SessionFit.fitpar.(task_subsets(tt)) = fitpars;
            this_model.SessionFit.ll.(task_subsets(tt)) = LL;
            this_model.SessionFit.aic.(task_subsets(tt)) = AIC;
            this_model.SessionFit.bic.(task_subsets(tt)) = BIC;
            this_model.SessionFit.nlike.(task_subsets(tt)) = normLL;
            this_model.SessionFit.blocks_per_session.(task_subsets(tt)) = NumBlocks;     
            fprintf('\n');
        end    
        
        % saving fitting output
        model_struct = this_model.SessionFit;
        if ~this_model.sessionfit_exists
            fitfname = strcat('output/model/',dataset_label,'/sessionfit/',group_label,'/',this_model.name,'.mat');    
            save(fitfname, 'model_struct');
            disp("Fit output saved!");
        else
            disp('fit loaded');
        end
    end
end