% Data_dir = "output/model/PhasePlaneData/";

% fixed params
betaDV  = 10;       % total inv. temp.

RewEnv = struct;
RewEnv.Probs = [0.8, 0.2];
RewEnv.totalL = 200;
RewEnv.blockL = 100;    

% params: aRew, aUnrew, decay, gamma
params_set = {[0.1, 0.3, 0.5, 0.1], [0.7, 0.1, 0.01, 0.1], ...
              [0.3, 0.5, 0.6, 0.3], [0.25, 0.2, 0.05, 0.8],  ...
              [0.3, 0.1, 0.7, 0.2], [0.5, 0.4, 0.1, 0.3]};

%% Plot panels

figure(7);  clf;
set(gcf,'Color','w','Units','normalized','Position',[0.0, 0.0, 0.45, 0.7]);

for p = 1:length(params_set)
    SP = subplot(3,2,p);
    if mod(p,2)==1
        SP.Position(1) = 0.075;        
    else
        SP.Position(1) = 0.575;
    end
    SP.Position(3) = 0.4;
    SP.Position(4) = 0.2;

    aRew    = params_set{p}(1);
    aUnrew  = params_set{p}(2);
    decayR  = params_set{p}(3);
    updateR  = params_set{p}(4);    
    dname = Data_dir+"Plastic_N10000_L"+RewEnv.totalL+"_rev"+RewEnv.blockL+"_aP"+aRew+"aN"+aUnrew+"_b"+betaDV+"_d"+decayR+"_g"+updateR+".mat";
    if ~exist(dname, 'file')
        disp("File doesn't exist: "+dname);
        continue;
    else
        load(dname,'MeanTraj','player');
    end    
    
    plot_phase_plane(MeanTraj, player, RewEnv);
    if p>=length(params_set)-1
        xlabel("Trials"); 
    end    
    ax.XTick = [0:25:200]; ax.XTickLabelRotation = 0;
    xtlbl = strings(1,length(ax.XTick)); xtlbl(1:2:end) = 0:50:200;
    ax.XTickLabel = xtlbl;
    
    ax.XRuler.TickLabelGapOffset = -3;
    
    title("\alpha_+="+player.params(1)+", \alpha_-="+player.params(4)+", \zeta="+player.params(5)+", \alpha_{\omega}="+player.params(6));
    
    set(gca,'FontName','Helvetica','FontSize',gca_fontsize,'FontWeight','normal','LineWidth',1,'tickdir','out','Box','off');        
end


%% subfunc: plotting
function plot_phase_plane(MeanTraj, player, RewEnv)
    
    block_addresses = 1:RewEnv.blockL:RewEnv.totalL;

    include_arb_rates = 1;
    plot_eff_arb = 0;           % plot delta(Eff.Arb)

    % plot each trajectory for omega_0
    for q1 = 1:length(player.omega0_set)
        if include_arb_rates&&plot_eff_arb
            DeltaArb = MeanTraj{q1}.posDeltaOmega - MeanTraj{q1}.negDeltaOmega;
            if contains(player.label,'betaR')&&plot_EffOmega
                L = cline(1:totalL, MeanTraj{q1}.EffOmega, DeltaArb);
                Y1Lbl = "\Omega (effective \omega)";
            else
                L = cline(1:totalL, MeanTraj{q1}.omegaV, DeltaArb);
                Y1Lbl = "\omega";
            end            
        else
            if contains(player.label,'betaR')&&plot_EffOmega
                L = cline(1:RewEnv.totalL, MeanTraj{q1}.EffOmega, MeanTraj{q1}.chooseBetter);
                Y1Lbl = "\Omega (effective \omega)";
            else
                L = cline(1:RewEnv.totalL, MeanTraj{q1}.omegaV, MeanTraj{q1}.chooseBetter);
                Y1Lbl = "\Omega";
            end            
        end
        L.LineWidth = 1.5;
        hold on;
    end

    C = colorbar;
    if include_arb_rates&&plot_eff_arb
        colormap(bipolar); caxis([-.1 .1]);
        C.Label.String = '\DeltaEff. arb. rates';
    else
        colormap(turbo); caxis([.5 1]);
        C.Ticks = .5:.1:1;
        C.Label.String = 'P(Better)';
    end
    C.Label.Units = 'normalized';
    C.Label.Rotation = 0;
    C.Label.Position(1) = 1.15;
    C.Label.Position(2) = 1.15;

    %rev lines
    if length(block_addresses)>1
        xline(block_addresses(2:end)-.5,'--k','HandleVisibility','off');
    end

    xticks(0:20:RewEnv.totalL);
    xtickangle(40);
    ylabel(Y1Lbl); 
    ylim([0 1]); 
    yticks(0:.1:1);
    yticklabels({'0','','0.2','','0.4','','0.6','','0.8','','1'});            
end
