%%% Run and save simulation for trajectories of arbitration weight as a
%%% function of its initial value

modelNum = 5;    % 5=omega, 6=beta-rho
numSim = 1000*10;
disp("N = "+numSim);          

RewEnv = struct;
RewEnv.Probs   = [.8 .2];     % reward schedules
RewEnv.totalL  = 200;         % total # of trials
RewEnv.blockL  = 100;         % length of block (reversals)

[models] = initialize_models('Costa16', 'control', 1, 0);
simMod     = models{modelNum};

omega0_set = 0:0.05:1;

% set params to simulate
paramSet = struct;
paramSet.aRew      = [0.5];
paramSet.aUnrew    = [0.4];   %[0.1, 0.2, 0.3, 0.4, 0.5]; %;
paramSet.beta      = 10;
paramSet.decayRate = [0.1]; %[0.01, 0.1, 0.2, 0.3, 0.5];
paramSet.gammaW    = [0.3];

Rho = 0.5;
SideBias  = 0;
omegaDec  = 0.05;

tic;
for q1 = 1:length(paramSet.aRew)
    aRew = paramSet.aRew(q1);
    disp("aRew = "+aRew);
    for q2 = 1:length(paramSet.aUnrew)
        aUnrew = paramSet.aUnrew(q2);

        for q3 = 1:length(paramSet.beta)
            betaDV = paramSet.beta(q3);

            for q4 = 1:length(paramSet.decayRate)
                decayRate = paramSet.decayRate(q4);

                for q5 = 1:length(paramSet.gammaW)
		            disp(q2+"."+q3+"."+q4+"."+q5+":");
                    gammaW = paramSet.gammaW(q5);

                    player = struct;
                    player.label  = strcat('algo_',simMod.algo);

                    switch modelNum
                        case 5
                            modName = "Plastic";
                            player.params = [aRew,betaDV,SideBias,aUnrew,decayRate,gammaW,NaN,omegaDec];
                        case 7
                            modName = "BetaRho";
                            beta1 = betaDV*2;
                            player.params = [aRew,beta1,SideBias,aUnrew,decayRate,Rho,gammaW,NaN,omegaDec];
                    end
                    player.omega0_set = omega0_set;
                    
                    % set file name
                    simFname = modName+"_N"+numSim+"_L"+RewEnv.totalL+"_rev"+RewEnv.blockL+"_aP"+aRew+"aN"+aUnrew+"_b"+betaDV+"_d"+decayRate+"_g"+gammaW;
                    simData = "output/model/Combined/"+simFname+".mat";
                    if ~exist(simData,'file')
                        [MeanTraj] = run_paramSet_PhasePlane(simMod, numSim, RewEnv, player);
                        save(simData,'MeanTraj','player');
                    else
                        load(simData,'MeanTraj','player');
                    end
                    
                    %% plot and save
                    plot_phase_plane(MeanTraj, player, RewEnv);
                    simFig = "output/figs/"+RewEnv.Probs(1)*100+""+RewEnv.Probs(2)*100+"/aRew_"+aRew+"/"+simFname+".fig";
                    savefig(simFig);
                    
                end
            end
        end
    end
end
disp("All simulations completed!")
TT = toc;
disp("Total elapsed time is "+TT/60+" minutes ("+TT/3600+" hours).");

%% subfunc: plotting
function plot_phase_plane(MeanTraj, player, RewEnv)
    block_addresses = 1:RewEnv.blockL:RewEnv.totalL;
    gca_fontsize = 16;

    include_arb_rates = 1;
    plot_eff_arb = 0;       % plot delta(Eff.Arb)

    figure;  clf;
    set(gcf,'Color','w','Units','normalized','Position',[0.0, 0.0, 0.325, 0.35]);   % 27

    % plot each trajectory for omega_0
    for q1 = 1:length(player.omega0_set)
        if include_arb_rates&&plot_eff_arb
            DeltaArb = MeanTraj{q1}.posDeltaOmega - MeanTraj{q1}.negDeltaOmega;
            if contains(player.label,'betaR')&&plot_EffOmega
                cline(1:totalL, MeanTraj{q1}.EffOmega, DeltaArb);
                Y1Lbl = "Effective \omega_V";
            else
                cline(1:totalL, MeanTraj{q1}.omegaV, DeltaArb);
                Y1Lbl = "\omega_V";
            end
            hold on;  
        else
            if contains(player.label,'betaR')&&plot_EffOmega
                cline(1:RewEnv.totalL, MeanTraj{q1}.EffOmega, MeanTraj{q1}.chooseBetter);
                Y1Lbl = "Effective \omega_V";
            else
                cline(1:RewEnv.totalL, MeanTraj{q1}.omegaV, MeanTraj{q1}.chooseBetter);
                Y1Lbl = "\omega_V";
            end
            hold on;  
        end
    end
    C = colorbar;
    if include_arb_rates&&plot_eff_arb
        colormap(bipolar); clim([-.1 .1]);
        C.Label.String = '\DeltaEff. arb. rates';
    else
        colormap(turbo); clim([.5 1]);
        C.Label.String = 'P(Better)';
    end

    %rev lines
    if length(block_addresses)>1
        xline(block_addresses(2:end)-.5,'--k','HandleVisibility','off');
    end
    if contains(player.label,'betaR')
        title("WHAT "+RewEnv.Probs(1)*100+"/"+RewEnv.Probs(2)*100+": \rho="+player.params(6)+", \alpha_+="+player.params(1)+", \alpha_-="+player.params(4)+", \zeta="+player.params(5)+", \gamma="+player.params(7));
    else
        title("WHAT "+RewEnv.Probs(1)*100+"/"+RewEnv.Probs(2)*100+": \beta="+player.params(2)+", \alpha_+="+player.params(1)+", \alpha_-="+player.params(4)+", \zeta="+player.params(5)+", \gamma="+player.params(6));
    end
    xlabel("Trials"); xticks(0:20:RewEnv.totalL);
    ylabel(Y1Lbl); ylim([0 1]); yticks(0:.1:1);
    yticklabels({'0','','0.2','','0.4','','0.6','','0.8','','1'});        
    set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');
end


