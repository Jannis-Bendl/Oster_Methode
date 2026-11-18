
diary('log/C3_matlab_analysis_altmkts.log')
diary on

%**********************************************************************
%------------------------ ALTERNATIVE MARKETS ------------------------* 
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

mlist = {38300,19400,24300,35001,20901};
    
    % Parameters: [beta_low, beta_high, beta_missing, h_a, h_b, gamma_mu, gamma_sd, tau_s]     
    % Start points based on solution region to increase speed
    x0matrix = [0.75,1.25,2,450,0.5,350,150,0;...
                0.75,1.25,2,450,0.5,300,150,0;...
                0.75,1.25,2,450,0.5,400,150,5;...
                0.75,1.25,2,450,0.5,400,150,25;...
                0.75,1.25,2,450,0.5,300,150,20];
                            
    A = [1,0,0,0,0,0,0,0;0,-1,0,0,0,0,0,0;0,1,-1,0,0,0,0,0];
    b = [1,-1,0];
    lb = [0.01,0.01,0.01,100,0.1,-3000,25,0];
    ub = [100,100,100,1500,1,3000,3000,300];

    params_comb = [];
    save('intermediate/params_altmkts.mat','params_comb')

for m = 1:length(mlist)

    % Provider level
    filename = ['providers_' num2str(mlist{m}) '_bin.xlsx'];
    providers_file = fullfile(root,'intermediate',filename);
    providers_GP = readtable(providers_file);

    % Market level
    filename = ['markets_' num2str(mlist{m}) '.xlsx'];
    markets_file = fullfile(root,'intermediate',filename);
    markets = readtable(markets_file);
   
    x0 = x0matrix(m,:);

    rng("default")  % For reproducibility
    gmm_tomin = @(params) matlab_equil_bin(params,providers_GP,markets);   
    [params,fval] = fmincon(gmm_tomin,x0,A,b,[],[],lb,ub,[],options);
 
    load('intermediate/params_altmkts.mat')
    params_comb = [params_comb;params];
    save('intermediate/params_altmkts.mat','params_comb')

end

%**********************************************************************

diary off