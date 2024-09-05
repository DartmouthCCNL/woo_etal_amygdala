function [models] = initialize_models(dataset_label, group_label, load_fit_output, load_sim_output, numfitruns)
    if ~exist("load_fit_output",'var')
        load_fit_output = true;
    end
    if ~exist("load_sim_output",'var')
        load_sim_output = false;
    end 
    if ischar(dataset_label)
        dataset_label = convertCharsToStrings(dataset_label);
    end
    models = {};

%% 0. Single-component RL 
m = length(models) + 1;
models{m}.name = 'RL25_StimOnly1';
models{m}.algo = 'SideBias_StimOnly';      
models{m}.fun = 'funSideBias_StimOnly';    
models{m}.initpar=[.5  5   0 .5 .5];       
models{m}.lb     =[ 0  1  -1  0  0];   
models{m}.ub     =[ 1 100  1  1  1];
models{m}.label = "RL_{Stim-only}";
models{m}.plabels = ["\alpha_{rew}", "\beta_{1}","\beta_0", "\alpha_{unrew}","decay"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'none';

m = length(models) + 1;
models{m}.name = 'RL25_LocOnly1';
models{m}.algo = 'SideBias_LocOnly';      
models{m}.fun = 'funSideBias_LocOnly';    
models{m}.initpar=[.5  5   0 .5 .5];       
models{m}.lb     =[ 0  1  -1  0  0];   
models{m}.ub     =[ 1 100  1  1  1];
models{m}.label = "RL_{Action-only}";
models{m}.plabels = ["\alpha_{rew}", "\beta_{1}","\beta_0", "\alpha_{unrew}","decay"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'none';

%% 1. Static RL

m = length(models) + 1;
models{m}.name = 'RL25_omegaV_comp1';
models{m}.algo = 'SideBias_comp';      
models{m}.fun = 'funSideBias_comp';    
models{m}.initpar=[.5  5   0 .5 .5 .5];       
models{m}.lb     =[ 0  1  -1  0  0  0];   
models{m}.ub     =[ 1 100  1  1  1  1];
models{m}.label = "RL_{Stim+Action}+Static \omega";
models{m}.plabels = ["\alpha_{rew}", "\beta_{1}","\beta_0", "\alpha_{unrew}","decay","\omega_{V}"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'none';


%% 3. Dynamic omegaV adjustment without RDMP systems

m = length(models) + 1;
models{m}.name = 'RL25_dynamicAbsRPELinRel_omegaDec_comp1';             
models{m}.algo = 'SideBias_dynamicAbsRPELinRel_Dec';      
models{m}.fun = 'funSideBias_dynamicAbsRPELinRel_Dec';    
models{m}.initpar = [.5  5  0 .5 .5 .5 .5 .5];   
models{m}.lb      = [ 0  1 -1  0  0  0  0  0];   
models{m}.ub      = [ 1 100 1  1  1  1  1  1];     
models{m}.label = "Dynamic \omega (|RPE|)";
models{m}.plabels = ["\alpha_{rew}", "\beta_{1}","\beta_0", "\alpha_{unrew}","\zeta","\gamma","\omega_0","\zeta_{\omega}"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'RL25_dynamicVchoLinRel_omegaV_comp1';

m = length(models) + 1;
models{m}.name = 'RL25_dynamicVchoLinRel_omegaDec_comp1';             
models{m}.algo = 'SideBias_dynamicVchoLinRel_Dec';      
models{m}.fun = 'funSideBias_dynamicVchoLinRel_Dec';    
models{m}.initpar = [.5  5  0 .5 .5 .5 .5 .1];   
models{m}.lb      = [ 0  1 -1  0  0  0  0  0];   
models{m}.ub      = [ 1 100 1  1  1  1  1 .5];   
models{m}.label = "Dynamic \omega (V_{cho})";
models{m}.plabels = ["\alpha_{rew}", "\beta_{DV}","\beta_0", "\alpha_{unrew}","\zeta_V","\gamma","\omega_0","\zeta_{\omega}"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'RL25_dynamicVchoLinRel_omegaV_comp1';    

m = length(models) + 1;
models{m}.name = 'RL25_dynamicVchoLinRelDec_omegaV_2betaR';             
models{m}.algo = 'SideBias_dynamicVchoLinRelDec_2betaR';      
models{m}.fun = 'funSideBias_dynamicVchoLinRelDec_2betaR';       
models{m}.initpar = [.5   5  0 .5 .5 .5 .5 .5 .1];   
models{m}.lb      = [ 0   1 -1  0  0  0  0  0  0];   
models{m}.ub      = [ 1 100  1  1  1  1  1  1 .5];   
models{m}.label = "Dynamic \omega-\rho (V_{cho}): free \rho";
models{m}.plabels = ["\alpha_{(+)}","\beta_{1}","\beta_0", "\alpha_{(-)}","\zeta", "\rho","\alpha_{\omega}","\omega_0","\zeta_{\omega}"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'none';

m = length(models) + 1;
models{m}.name = 'RL25_dynamicVchoLinRelDec_omegaV_SubjectFixedRho';     % inputs fixed value of rho in the fitting           
models{m}.algo = 'SideBias_dynamicVchoLinRelDec_2betaR';      
models{m}.fun = 'funSideBias_dynamicVchoLinRelDec_SubjectFixedRho';       
models{m}.initpar = [.5   5  0 .5 .5 .5 .5 .5];   
models{m}.lb      = [ 0   1 -1  0  0  0  0  0];   
models{m}.ub      = [ 1 100  1  1  1  1  1  1];   
models{m}.label = "Dynamic \omega-\rho (V_{cho})";     % (subject-fixed)
models{m}.plabels = ["\alpha_{(+)}","\beta_{1}","\beta_0","\alpha_{(-)}","\zeta","\alpha_{\omega}","\omega_0","\zeta_{\omega}"];
models{m}.simfunc = 'predictAgentSimulationLocation';
models{m}.extract_initpar_from = 'RL25_dynamicVchoLinRel_omegaDec_comp1';

%% check for errors

numfields = numel(fieldnames(models{1}));
Names_set = {};

for m = 1:length(models)
    disp(m+". "+models{m}.name);

    if numel(models{m}.initpar)~=numel(models{m}.plabels)
        error(m+'. Error in number of parameters');
    end
    if numel(fieldnames(models{m}))~=numfields
        error("Check number of fields : Model "+m);
    end

    Names_set{m} = models{m}.name;    
    
    ffunc = models{m}.fun;
    sfunc = "algo_"+models{m}.algo;
    if ~(exist(ffunc,'file'))
        error(ffunc+": corresponding model fit function does not exist")
    end
end
if numel(unique(Names_set))~=numel(models)
   error('Error: should assign unique labels to each model');
end

%% load existing output
% if the saved output file exists, flag and load the data

output_dir = "output/model/"+dataset_label;
for m = 1:length(models)
    % fitting data
    fitfname = strcat(output_dir,'/fit/',group_label,'/',models{m}.name,'.mat');    
    if exist(fitfname, 'file') && load_fit_output
        load(fitfname, 'model_struct'); 
        orig_struct = model_struct;
        models{m}.fit_exists = 1;
        field_names = fieldnames(orig_struct);
        for cnt = 1:length(field_names)
            if ~isfield(models{m}, field_names{cnt})
                models{m}.(field_names{cnt}) = orig_struct.(field_names{cnt});
            end
        end
    else
        models{m}.fit_exists = 0;
    end
    
    % session-wise fit data
    sfitfname = strcat(output_dir,'/sessionfit/',group_label,'/',models{m}.name,'.mat');    
    if exist(sfitfname, 'file') && load_fit_output
        load(sfitfname, 'model_struct'); 
        models{m}.sessionfit_exists = 1;
        models{m}.SessionFit = model_struct;
    else
        models{m}.sessionfit_exists = 0;
    end
        
    % subject-wise fit data:
    sfitfname = strcat(output_dir,'/subjectfit/',group_label,'/',models{m}.name,'.mat');    
    if exist(sfitfname, 'file') && load_fit_output
        load(sfitfname, 'model_struct'); 
        models{m}.subjectfit_exists = 1;
        models{m}.SubjectFit = model_struct;
    else
        models{m}.subjectfit_exists = 0;
    end

    % simulation data
    simfname = output_dir+"/sim10/"+group_label+"/simLearn_"+models{m}.name+"_rev1_ext.mat";
    if exist(simfname, 'file') && load_sim_output
        load(simfname, 'SimRun','SimMean');
        models{m}.SimRun = SimRun;
        models{m}.SimMean = SimMean;
        models{m}.sim_exists = 1;
    else
        models{m}.sim_exists = 0;
    end
    
    % CV: 50 instances
    cv50fname = strcat(output_dir,'/crossval50/',group_label,'/',models{m}.name,'.mat');   
    if exist(cv50fname, 'file')
        load(cv50fname, 'model_struct');
        models{m}.CrossVal50 = model_struct;
        models{m}.cv50_exists = 1;
    else
        models{m}.cv50_exists = 0;
    end

    % model recovery: fit to simulated data
    numSim = 1; % # of simulation per block
    sfitfname = output_dir+"/SessionRecover"+numSim+"_10/"+group_label+"/"+models{m}.name+"_dev0.1"+".mat";
    if exist(sfitfname, 'file') && load_sim_output
        load(sfitfname, 'model_struct');
        models{m}.SimRecover = model_struct;
        models{m}.recovery_exists = 1;
    else
        models{m}.recovery_exists = 0;
    end
    sfitfname = output_dir+"/SubjectFitRecover"+numSim+"/"+group_label+"/"+models{m}.name+".mat";
    if exist(sfitfname, 'file') && load_sim_output
        load(sfitfname, 'model_struct');
        models{m}.SimRecover.SubjectFixed = model_struct;
        models{m}.subRecovery_exists = 1;
    else
        models{m}.subRecovery_exists = 0;
    end
    
end

%% generate initial value pool for evenly spaced search space
if ~exist('numfitruns','var')
   numfitruns = 10; 
end
for m = 1:length(models)
    initparpool = nan(numfitruns-1,length(models{m}.initpar));     
    for p = 1:length(models{m}.initpar)
        initpars = linspace(models{m}.lb(p),models{m}.ub(p),numfitruns-1);
        initpars = initpars(randperm(length(initpars)));    %randomize order
        initparpool(:,p) = initpars;
    end
    models{m}.initparpool = mat2cell(initparpool,ones(numfitruns-1,1),length(models{m}.initpar));
    models{m}.initparpool{numfitruns} = models{m}.initpar;
end
%% display info
disp(">> "+ numel(models)+" models initialized:"); 
disp('-----------------');

end