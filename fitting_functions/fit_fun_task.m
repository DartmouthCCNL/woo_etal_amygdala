
function [qpar, negloglike] = fit_fun_task(all_stats, fit_func, initpar, lb, ub)
    maxit = 1e20;
    maxeval = 1e20;
    op = optimset('fminsearch');
    op.MaxIter = maxit;
    op.MaxFunEvals = maxeval;

    func_handle = str2func("block_wrapper");
    [qpar, negloglike, exitflag] = fmincon(func_handle, initpar, [], [], [], [], lb, ub, [], op, {all_stats, fit_func});
   
    if exitflag==0
        qpar = nan(size(qpar));   %did not converge to a solution, so return NaN
        negloglike = nan;
    end
end

function [tot_negloglike] = block_wrapper(xpar, data)
    tot_negloglike = 0;
    all_stats = data{1};
    func_handle = str2func(data{2});
    total_num_trials = 0;
    
    if contains(data{2},'SubjectFixed')
        pass_FixedParam_flag = 1;
    else
        pass_FixedParam_flag = 0;
    end

    for i = 1:length(all_stats)
        statss = all_stats{i};
        total_num_trials = total_num_trials + sum(~isnan(statss.r));
        
        if isfield(statss,'cloc')
            dat = [statss.c statss.r statss.cloc];
        else
            dat = [statss.c statss.r];
        end
        
        % if passing on fixed param(s) for each subject
        if pass_FixedParam_flag
            initVals.Rho = statss.SubjectFixed_Rho;
            if length(data)>2
                [negloglike] = func_handle(xpar, dat, initVals, data{3});
            else                
                [negloglike] = func_handle(xpar, dat, initVals);
            end
        else
            [negloglike] = func_handle(xpar, dat);  %disp(negloglike);
        end
        
        tot_negloglike = tot_negloglike + negloglike;
    end
end