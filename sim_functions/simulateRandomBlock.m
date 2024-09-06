function stats = simulateRandomBlock(HRprob, blockL, reversalRange, sd, blockType)
% creates random simulated block with the assigned reward prob
%       for Costa et al., 2016 task (and What/Where task)
% INPUT:
%       HRprob          : higher reward probability (0.6, 0.7, 0.8, 1.0)
%       blockL          : block length (=80 for Costa dataset)
%       reversalRange   : range for where the random reversal is located
%       sd              : random number seed
%       WHERE      : indicates whether this is an WHERE block (default is WHAT)
%
% OUTPUT:
%   stats               : struct with the following fields 
%       hr_shape        : higher shape (-1 for Cir, 1 for Sqr)
%       rewardprob      : reward probability matrix for each stimuli (blockL x 2)
%       hr_side         : indicates side where the higher shape appeared on
%       rewardarray     : indicates whether the assigned reward exists in the given stimuli
%       shape_on_right  : indicates which shape is on the right side, assigned pseudorandomly (-1 for Cir, 1 for Sqr)
%       acq_end         : last trial number in the acquisition phase
%
%%  
    if ~exist('blockType','var')
        blockType = 'WHAT';      % default is WHAT block
    end
    rng('shuffle');
    % assign reversal point
    revPoint = randi(reversalRange);
    acq_end = revPoint - 1;
    acqBetter_idx = randperm(2);
    betterOpt_acq = (acqBetter_idx(1)-1)*2-1;     % better shape(what)/side(where) during acquisition
    
    
    stats = struct;
    stats.rewardprob = nan(blockL, 2);
    stats.rewardarray = nan(blockL, 2); 
    stats.hr_shape = nan(blockL, 1);
    stats.hr_side = nan(blockL, 1);
        
    % assign reward prob based on shape
    LRprob = 1 - HRprob;
    stats.rewardprob(1:acq_end,acqBetter_idx(1)) = HRprob*ones(acq_end,1);
    stats.rewardprob(1:acq_end,acqBetter_idx(2)) = LRprob*ones(acq_end,1);
    stats.rewardprob(revPoint:blockL,acqBetter_idx(1)) = LRprob*ones(blockL-acq_end,1);
    stats.rewardprob(revPoint:blockL,acqBetter_idx(2)) = HRprob*ones(blockL-acq_end,1);
    
    % assign pseudorandom location values for shapes:
    stats.shape_on_right = (randi(2,blockL,1)-1.5)*2;
    cir_on_right = (stats.shape_on_right==-1);
    
    rng(sd);
    % reward array: assign rewards
    acq_rew = [round(stats.rewardprob(1,1)*acq_end), round(stats.rewardprob(1,2)*acq_end)];       % number of assigned rewards for each shape during Acq
    acq_unrew = acq_end - acq_rew;                                  % number of assigned no rewards for each shape during Acq
    ra1 = [zeros(acq_unrew(1),1); ones(acq_rew(1),1)];
    ra1 = ra1(randperm(acq_end));                                   % randomly shuffle where the rewards exist for Cir
    ra2 = [zeros(acq_unrew(2),1); ones(acq_rew(2),1)];
    ra2 = ra2(randperm(acq_end));                                   % randomly shuffle where the rewards exist for Sqr
    stats.rewardarray(1:acq_end,:) = [ra1, ra2];                    % reward array during Acq
    % rev
    rev_rew = [round(stats.rewardprob(revPoint,1)*(blockL-acq_end)),round(stats.rewardprob(revPoint,2)*(blockL-acq_end))];
    rev_unrew = (blockL-acq_end) - rev_rew;
    ra1 = [zeros(rev_unrew(1),1); ones(rev_rew(1),1)];
    ra1 = ra1(randperm(blockL-acq_end));
    ra2 = [zeros(rev_unrew(2),1); ones(rev_rew(2),1)];
    ra2 = ra2(randperm(blockL-acq_end));
    stats.rewardarray(revPoint:blockL,:) = [ra1, ra2];
    
    if strcmp(blockType,'WHAT')
        % compute higher reward shape for each trial (What blocks)
        stats.hr_shape(1:acq_end) = betterOpt_acq*ones(acq_end,1);
        stats.hr_shape(revPoint:blockL) = -betterOpt_acq*ones(blockL-acq_end,1);
        
        % compute higher reward side for each trial
        stats.hr_side = stats.shape_on_right.*stats.hr_shape;
        
        % assgined rewards for each side?
        stats.rewardarrayLR = stats.rewardarray;
        stats.rewardarrayLR(cir_on_right,:) = flip(stats.rewardarrayLR(cir_on_right,:),2);
        
    elseif strcmp(blockType,'WHERE')
        stats.hr_side(1:acq_end) = betterOpt_acq*ones(acq_end,1);
        stats.hr_side(revPoint:blockL) = -betterOpt_acq*ones(blockL-acq_end,1);
        
        % compute higher reward shape for each trial
        stats.hr_shape = stats.shape_on_right.*stats.hr_side;
        
        % flip reward array for WHERE blocks
        stats.rewardarrayLR = stats.rewardarray;
        stats.rewardarray(cir_on_right,:) = flip(stats.rewardarray(cir_on_right,:),2);
    else
        error("Set block type: WHAT or WHERE");
    end
    stats.acq_end = acq_end;
    stats.blockType = blockType;
    stats.HRprob = HRprob;
    
%     % viz
%     figure(1); clf; sgtitle(blockType+" "+HRprob*100+"/"+LRprob*100);
%     subplot(1,4,1); imagesc(stats.rewardarray); title('rewards array Stim'); xticks([1 2]); xticklabels(["Cir","Sqr"]);
%     hold on; plot([0.5, 2.5],[acq_end,acq_end]+.5,'r','LineWidth',2);
%     subplot(1,4,2); imagesc(stats.rewardarrayLR); title('rewards array Loc'); xticks([1 2]); xticklabels(["Left","Right"]);
%     hold on; plot([0.5, 2.5],[acq_end,acq_end]+.5,'r','LineWidth',2);
%     subplot(1,4,3); imagesc(stats.shape_on_right); title('shape on right'); colorbar; 
%     hold on; plot([0.5, 2.5],[acq_end,acq_end]+.5,'r','LineWidth',2);
%     subplot(1,4,4); imagesc(stats.hr_side); title('hr side'); colorbar;
%     hold on; plot([0.5, 2.5],[acq_end,acq_end]+.5,'r','LineWidth',2);
    
end