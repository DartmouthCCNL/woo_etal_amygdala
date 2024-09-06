function stats_sim = simulateAgentBehavior(player, stats)
% % simulate agent behavior %
%PURPOSE:   Simulate agent behavior on simulated blocks
%AUTHORS:   Jae Hyung Woo 211006
%
%INPUT ARGUMENTS
%   player:    player structure
%       label - the name of the algorithm, the name should correspond to a .m file
%       params - parameters associated with that algorithm
%   stats:      stats about the actual choice behavior
%
%OUTPUT ARGUMENTS
%   stats_sim:      simulated choice behavior and latent variables


%% initialize

nT = size(stats.rewardprob,1);   % number of trials

stats_sim = struct;             % stat for the game

stats_sim.currTrial = 1;       % starts at trial number 1
stats_sim.pL = nan(nT,1);      % probability to choose *left* side
stats_sim.c = nan(nT,1);       % choice vector (stimuli)
stats_sim.cloc = nan(nT,1);    % choice vector (location)  
stats_sim.r = nan(nT,1);       % reward vector

stats_sim.q1 = nan(nT,1);      % action value for *Cir* choice
stats_sim.q2 = nan(nT,1);      % action value for *Sqr* choice
stats_sim.qL = nan(nT,1);      % action value for *Left* choice
stats_sim.qR = nan(nT,1);      % action value for *Right* choice

stats_sim.cL = nan(nT,1);      % choicekernel left
stats_sim.cR = nan(nT,1);      % choicekernel right
stats_sim.erpe = nan(nT,1);    % erpe
stats_sim.rpe = nan(nT,1);     % reward prediction error vector

%% create reward environment

stats_sim.shape_on_right = stats.shape_on_right;

%% simualte the task

rng('shuffle');

stats_sim.playerlabel = player.label;
stats_sim.playerparams = player.params;

% take the text label for the player, there should be a corresponding Matlab
% function describing how the player will play
simplay1 = str2func(player.label);

for j = 1:nT
    %what is the player's probability for choosing left?
    stats_sim.currTrial = j;
    stats_sim = simplay1(stats_sim, stats_sim.playerparams);
    
    if(rand()<stats_sim.pL(j))
        stats_sim.cloc(j) = -1;    % choose left
        stats_sim.r(j) = stats.rewardarrayLR(j,1);    
    else
        stats_sim.cloc(j) = 1;     % choose right
        stats_sim.r(j) = stats.rewardarrayLR(j,2);
    end
    
    %which shape did the player choose?
    stats_sim.c(j) = stats_sim.shape_on_right(j)*stats_sim.cloc(j);
end

%which shape did the player choose?
stats_sim.c = stats_sim.shape_on_right.*stats_sim.cloc;

% % viz
% figure(100);  clf;
% plot(filtfilt(ones(1,10)/10,1,stats_sim.r),'g'); hold on
% plot(filtfilt(ones(1,10)/10,1,stats_sim.pL),'k');
% plot(filtfilt(ones(1,10)/10,1,double(stats_sim.c==1)),'b');
% plot(filtfilt(ones(1,10)/10,1,double(stats_sim.cloc==-1)),'m');
% legend("P(Win)","P(chooseLeft)","choseSqr","choseLeft",'Location','northoutside');
% revPoint = stats.acq_end + 1;
% plot([revPoint revPoint],[0 1],'--k','HandleVisibility','off');
% xlabel(stats.blockType+", "+stats.HRprob);

end