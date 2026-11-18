
diary('log/C3_matlab_analysis_altR.log')
diary on

%**********************************************************************
%------------------------ ALTERNATIVE REVENUE ------------------------* 
%**********************************************************************

%---------------------------------------------------------------------%
%-------------------- Define directories/ settings -------------------%
%---------------------------------------------------------------------%

n = str2double(getenv('SLURM_CPUS_PER_TASK'));
parpool('local',n-1);

root = fileparts(fileparts(mfilename('fullpath')));
root = strtrim(char(root));  
cd(root);
addpath(fullfile(root,'code','matlab_sub'));
options = optimoptions('fmincon','Display','off','Algorithm','interior-point');

%**********************************************************************
%-------------------------------- GMM --------------------------------* 
%**********************************************************************

rlist = [0.5,0.75,0.9,1.1,1.25,1.5];
    
    % Parameters: [beta_low, beta_high, beta_missing, h_a, h_b, gamma_mu, gamma_sd, tau_s]     
    % Start points based on solution region to increase speed
    x0matrix = [0.75,1.25,2,200,0.5,350,150,0;...
                0.75,1.25,2,250,0.5,350,150,10;...
                0.75,1.25,2,350,0.5,350,150,25;...
                0.75,1.25,2,500,0.5,350,150,30;...
                0.75,1.25,2,550,0.5,350,150,40;...
                0.75,1.25,2,600,0.5,300,150,50];

    A = [1,0,0,0,0,0,0,0;0,-1,0,0,0,0,0,0;0,1,-1,0,0,0,0,0];
    b = [1,-1,0];
    lb = [0.01,0.01,0.01,100,0.1,-3000,25,0];
    ub = [100,100,100,1500,1,3000,3000,300];

    params_comb = [];
    save('intermediate/params_altR.mat','params_comb')

for k = 1:numel(rlist)

    r = rlist(k);

    % Provider level
    providers_file = fullfile(root,'intermediate','providers_39400_bin.xlsx');
    providers_GP = readtable(providers_file);
    providers_GP.R = providers_GP.R*r;

    % Market level
    markets_file = fullfile(root,'intermediate','markets_39400.xlsx');
    markets = readtable(markets_file);
   
    x0 = x0matrix(k,:);

    rng("default")  % For reproducibility
    gmm_tomin = @(params) matlab_equil_bin(params,providers_GP,markets);   
    [params,fval] = fmincon(gmm_tomin,x0,A,b,[],[],lb,ub,[],options);

    load('intermediate/params_altR.mat')
    params_comb = [params_comb;params];
    save('intermediate/params_altR.mat','params_comb')

end

%**********************************************************************

diary off