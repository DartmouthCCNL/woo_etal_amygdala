function [pleft, pright] = DecisionRuleSideBias2(SideBias,q_left,q_right,beta_DV)
    % adds stay bias for stimulus and location dimensions
    % beta_DV = inverse temperature
    % SideBias = side bias ranging [-1, 1], positive if biasing right side

    pright = 1/(1+exp(-(SideBias + beta_DV*(q_right-q_left))));
    pleft = 1 - pright;

    if pright==0
        pright = realmin;   % Smallest positive normalized floating point number, because otherwise log(zero) is -Inf
    end
    if pleft==0
        pleft = realmin;
    end
end

