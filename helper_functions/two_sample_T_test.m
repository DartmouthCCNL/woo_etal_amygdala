function [pval, cohensD, asterisk, stats] = two_sample_T_test(Sample1, Sample2, multcomp, tail_type)
    % parametric test
    if ~exist('tail_type','var')
        tail_type = 'both';
    end
    [~,pval,~,stats] = ttest2(Sample1, Sample2,'tail',tail_type); 
    cohensD = computeCohen_d(Sample1, Sample2);
    
    askType = "*";
%     askType = "∗";
    
%     asterisk = "n.s.";
    asterisk = "";
    if pval<.05/multcomp; asterisk = askType;
        if pval <.01/multcomp; asterisk = askType+askType; 
            if pval<.001/multcomp; asterisk = askType+askType+askType; end; end
    end
end