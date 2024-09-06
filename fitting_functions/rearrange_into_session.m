function [sess_stats] = rearrange_into_session(dataset_label, all_stats)
    abs_sess_id = 0;
    numSession = 0;  
    if strcmp(dataset_label,"Costa16")
        for i = 1:length(all_stats)
            if abs_sess_id~=all_stats{i}.session_date
                abs_sess_id = all_stats{i}.session_date;
                numSession = numSession + 1;
                sess_stats.what{numSession} = {};
            end
            sess_stats.what{numSession} = [sess_stats.what{numSession}, all_stats{i}];
        end     
    else
        for i = 1:length(all_stats)
            if abs_sess_id~=all_stats{i}.session_idx
                abs_sess_id = all_stats{i}.session_idx;
                numSession = numSession + 1;
                sess_stats.what{numSession} = {};
                sess_stats.where{numSession} = {};
                sess_stats.Combined{numSession} = {};
            end
            sess_stats.Combined{numSession} = [sess_stats.Combined{numSession}, all_stats{i}];
            if all_stats{i}.what
                sess_stats.what{numSession} = [sess_stats.what{numSession}, all_stats{i}];
            else
                sess_stats.where{numSession} = [sess_stats.where{numSession}, all_stats{i}];
            end
        end 
    end
end