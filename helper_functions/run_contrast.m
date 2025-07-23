
%% function for planned & post-hoc contrasts analysis
function [stats] = run_contrast(mdl, C, display)
    if nargin<3 || display==1 || strcmp(display,'on')
        display = true;
    else
        display = false;
    end
    Betas = fixedEffects(mdl);
    assert(length(C)==length(Betas),"Length of contrast weights should match the number of coeff.");
    b = C * Betas;
    SE = sqrt(C*mdl.CoefficientCovariance*C');
    tstat = b /SE;
    pval = 2 * (1 - tcdf(abs(tstat), mdl.DFE));
    
    [pval2,F] = coefTest(mdl,C); % check that the output results are same with built-in function    
    if display
        % disp("b = "+b+", SE = "+SE+", t("+mdl.DFE+") = "+tstat+", p = "+pval);
        disp("F = "+F+", p = "+pval2);
    end

    % output results
    stats = struct;
    stats.b = b;
    stats.pval = pval;
    stats.SE = SE;
    stats.DF = mdl.DFE;
    stats.tstat = tstat;    
    stats.Fstat = F;
end
