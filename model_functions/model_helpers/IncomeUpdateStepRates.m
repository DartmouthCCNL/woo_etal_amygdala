function [v_Opt1, v_Opt2, rpe] = IncomeUpdateStepRates(reward, choice, v_Opt1, v_Opt2, alpha, alpha2, decay_rate)
% updates value estimates V_i with the decay rate for the unchosen side

%     decay_rate = decayR;
    decay_base = 0;     %pars(5);
    
    if choice==1        %chose sqr
        rpe = reward - v_Opt2;
        if reward>0
            v_Opt2 = v_Opt2 + alpha*(rpe);
        else
            v_Opt2 = v_Opt2 + alpha2*(rpe);
        end
        v_Opt1 = v_Opt1 + decay_rate*(decay_base-v_Opt1);
    elseif choice==-1   %chose cir
        rpe = reward - v_Opt1;
        if reward>0
            v_Opt1 = v_Opt1 + alpha*(rpe);
        else
            v_Opt1 = v_Opt1 + alpha2*(rpe);
        end
        v_Opt2 = v_Opt2 + decay_rate*(decay_base-v_Opt2);
    elseif choice==0
        rpe = nan;
        v_Opt1 = v_Opt1 + decay_rate*(decay_base-v_Opt1);
        v_Opt2 = v_Opt2 + decay_rate*(decay_base-v_Opt2);
    end

end





