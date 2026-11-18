
diary('log/C3_matlab_analysis_main.log')
diary on

%**********************************************************************
%-------------------------- MODEL ESTIMATION -------------------------* 
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
options=optimoptions('fmincon','Display','off','Algorithm','interior-point');

%---------------------------------------------------------------------%
%----------------------------- Load data -----------------------------%
%---------------------------------------------------------------------%

   % Provider level
   providers_file = fullfile(root,'intermediate','providers_39400.xlsx');
   providers_GP = readtable(providers_file);

   % Market level 
   markets_file = fullfile(root,'intermediate','markets_39400.xlsx');
   markets = readtable(markets_file);

%**********************************************************************
%-------------------------------- GMM --------------------------------* 
%**********************************************************************

    % Parameters: [beta_low, beta_high, beta_missing, h_a, h_b, gamma_mu, gamma_sd, tau_s]     
    x0 = [0.75,1.25,2,450,0.5,350,150,25];
    lb = [0.01,0.01,0.01,100,0.1,-3000,25,0];
    ub = [100,100,100,1500,1,3000,3000,300];

    A = [1,0,0,0,0,0,0,0;0,-1,0,0,0,0,0,0;0,1,-1,0,0,0,0,0];
    b = [1,-1,0];

    rng("default")  % For reproducibility
    gmm_tomin = @(params) matlab_equil_main(params,providers_GP,markets);   
    [params,fval,exitflag,output,lambda,grad,hessian] = fmincon(gmm_tomin,x0,A,b,[],[],lb,ub,[],options);
    save('intermediate/params_39400','params')

    % Confidence interals 
    se = sqrt(diag(inv(hessian)));
    CI = [-1.98*se+params',1.98*se+params'];
    save('intermediate/CI_39400','CI')
 
%**********************************************************************

diary off

