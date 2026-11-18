
diary('log/C4_matlab_post.log')
diary on

%**********************************************************************
%-------------------------- COUNTERFACTUALS --------------------------* 
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
options=optimset('Display','off');

set(0,'defaultAxesFontName','Times');
CF_altmkts = [];
CF_altR = [];

%---------------------------------------------------------------------%
%----------------------------- Load data -----------------------------%
%---------------------------------------------------------------------%

mlist = {'39400','38300','19400','24300','35001','20901'};
rlist = [0.5,0.75,0.9,1,1.1,1.25,1.5];

for m = 1:length(mlist)

    if strcmp(mlist{m},'39400')
        rvals = rlist;
    else
        rvals = 1;
    end

    for k = 1:numel(rvals)

        r = rvals(k); 

        % Provider level
        filename = ['providers_' num2str(mlist{m}) '.xlsx'];
        providers_file = fullfile(root,'intermediate',filename);
        providers_GP = readtable(providers_file);
        providers_GP.R = providers_GP.R*r;

        % Market level
        filename = ['markets_' num2str(mlist{m}) '.xlsx'];
        markets_file = fullfile(root,'intermediate',filename);
        markets = readtable(markets_file);
   
        pop = markets.pop(1);
        n_GP = markets.n_GP(1);
        tau_d = markets.tau_d(1);
        tau_o = markets.tau_o(1);
        pain = markets.pain(1);
        misuse_sm = markets.misuse_sm(1);
        mkt_price = markets.price(1);
        op_US = markets.OP_US(1);

        % Extract estimates
        if strcmp(mlist{m},'39400') && r == 1 
            load(fullfile('intermediate','params_39400.mat'));
            load('intermediate/CI_39400');
        elseif strcmp(mlist{m}, '39400') && r ~= 1
            load(fullfile('intermediate','params_altR.mat'));
            if r < 1
                params = params_comb(k,:);
            else
                params = params_comb(k-1,:);
            end
            clearvars param_comb
        else
            load(fullfile('intermediate','params_altmkts.mat'));
            params = params_comb(m-1,:);
            clearvars param_comb
        end
       
        beta_params = [params(1),1,params(2),params(3)];
        tau_s = params(8) + tau_d;
        c = 0.0001;

        % Extract equilibrium objects 
        [~,price,harm_sm] = matlab_equil_main(params,providers_GP,markets);
        clearvars markets

%**********************************************************************
%------------------------------- Set-up ------------------------------*
%**********************************************************************

        %----------------------- Thresholds -----------------------%
    
        LHS_deriv = @(x) 1 - normcdf(price-x,params(6),params(7)) + ...
                    normpdf(price-x,params(6),params(7))*(x-harm_sm);
        min_hkstar = fzero(LHS_deriv,-100,options); 
        min_RHS = min_hkstar + normcdf(price-min_hkstar,params(6),params(7))*(harm_sm-min_hkstar);
    
        k_star = zeros(n_GP,1);
        k_star_nosm = zeros(n_GP,1);
        parfor i=1:n_GP
            scal_fac=providers_GP.R(i)./beta_params(providers_GP.beta(i));
    
            % Actual: with SM
            if -scal_fac >= min_RHS
                RHS_func = @(x) x + normcdf(price-x,params(6),params(7)).*(harm_sm-x) + scal_fac;
                try 
                    hk_star = fzero(RHS_func,[min_hkstar 10000]);
                    k_star(i) = inv_ben(hk_star,params(4),params(5),c);
                catch 
                    warning('off');
                    k_star(i) = 10;
                    warning('on');
                end
            end
        end
    
        providers_GP = [providers_GP,array2table(k_star,'VariableNames',{'k_star'})];
        providers_GP = sortrows(providers_GP,'k_star','descend');
        
        parfor i=1:n_GP
            scal_fac = providers_GP.R(i)./beta_params(providers_GP.beta(i));
            
            % Counterfactual: without SM
            k_star_nosm(i) = inv_ben(-scal_fac,params(4),params(5),c);
        end
       
        % Counterfactual: without SM, no overprescribing 
        k_star_0 = fzero(@(x) ben(x,params(4),params(5),c),[0 100]);
        k_star_nosm_noop = k_star_nosm;
        k_star_nosm_noop(k_star_nosm_noop<=k_star_0) = k_star_0;
      
        %--------------------- Search process ---------------------%
        
        % Empirical distribution of P(k)
        Pk_sm = [(0:(max(providers_GP.k_star)+1)/1000:max(providers_GP.k_star)+1)',...
                  0.*(0:(max(providers_GP.k_star)+1)/1000:max(providers_GP.k_star)+1)'];
        for x = 1:length(Pk_sm)
            Pk_sm(x,2) = sum(providers_GP.k_star <= Pk_sm(x,1))/n_GP;
        end
        
        Pk_nosm = [(0:(max(k_star_nosm)+1)/1000:max(k_star_nosm)+1)',...
                    0.*(0:(max(k_star_nosm)+1)/1000:max(k_star_nosm)+1)'];
        for x = 1:length(Pk_nosm)
            Pk_nosm(x,2) = sum(k_star_nosm <= Pk_nosm(x,1))/n_GP;
        end
        
        Pk_nosm_noop = [(0:(max(k_star_nosm_noop)+1)/1000:max(k_star_nosm_noop)+1)',...
                         0.*(0:(max(k_star_nosm_noop)+1)/1000:max(k_star_nosm_noop)+1)'];
        for x = 1:length(Pk_nosm_noop)
            Pk_nosm_noop(x,2) = sum(k_star_nosm_noop <= Pk_nosm_noop(x,1))/n_GP;
        end
            
        % Fit probability function
        Pfit_sm = fit(Pk_sm(:,1),Pk_sm(:,2),'linearinterp');
        Pfit_sm = @(x) Pfit_sm(x)';
    
        Pfit_nosm = fit(Pk_nosm(:,1),Pk_nosm(:,2),'linearinterp');
        Pfit_nosm = @(x) Pfit_nosm(x)';
        
        Pfit_nosm_noop = fit(Pk_nosm_noop(:,1),Pk_nosm_noop(:,2),'linearinterp');
        Pfit_nosm_noop = @(x) Pfit_nosm_noop(x)';
            
        % Solve for P_tilde (with SM only)
        P_tilde = fzero(@(x) Pfit_sm(x) - tau_s/(price-tau_o),2);
        jp = n_GP-sum(providers_GP.k_star < P_tilde); 
        P_tilde = providers_GP.k_star(jp);
        
        %----------------------- Base pieces ----------------------% 
        % 1. With SM
        % 2. Without SM, old thresholds
        % 3. Without SM, new thresholds
        % 4. Without SM, new thresholds + no overprescribing
    
        % With SM
        above = zeros(n_GP+1,1); 
        habove = zeros(n_GP+1,1);
        below = zeros(n_GP,1); 
        hbelow = zeros(n_GP+1,1);
    
        % Without SM, old thresholds
        saboveo = zeros(n_GP+1,1);
        hsaboveo = zeros(n_GP+1,1);
        caboveo = zeros(n_GP+1,1);
        hcaboveo = zeros(n_GP+1,1);
        sbelowo = zeros(n_GP+1,1);
        cbelowo = zeros(n_GP+1,1);
    
        % Without SM, new thresholds
        sabove = zeros(n_GP+1,1);
        hsabove = zeros(n_GP+1,1);
        cabove = zeros(n_GP+1,1);
        hcabove = zeros(n_GP+1,1);
        sbelow = zeros(n_GP+1,1);
        cbelow = zeros(n_GP+1,1);
    
        % Without SM, no overprescribing 
        sabove_noop = zeros(n_GP+1,1);
        hsabove_noop = zeros(n_GP+1,1);
        cabove_noop = zeros(n_GP+1,1);
        hcabove_noop = zeros(n_GP+1,1);
        sbelow_noop = zeros(n_GP+1,1);
        cbelow_noop = zeros(n_GP+1,1);
        
        above(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                    (1-normcdf(price-ben(k,params(4),params(5),c),...
                                    params(6),params(7))),providers_GP.k_star(1),Inf);
        habove(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                    pdf('Exponential',k,pain).*...
                                    (1-normcdf(price-ben(k,params(4),params(5),c),...
                                    params(6),params(7))),providers_GP.k_star(1),Inf);                        
        below(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                    normcdf(price-ben(k,params(4),params(5),c),...
                                    params(6),params(7)),providers_GP.k_star(1),Inf);
        hbelow(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                    pdf('Exponential',k,pain).*...
                                    normcdf(price-ben(k,params(4),params(5),c),...
                                    params(6),params(7)),providers_GP.k_star(1),Inf); 
    
        saboveo(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                      (1-normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                      params(6),params(7))),providers_GP.k_star(1),Inf);       
        hsaboveo(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                      pdf('Exponential',k,pain).*...
                                      (1-normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                      params(6),params(7))),providers_GP.k_star(1),Inf); 
        caboveo(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                      (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                      params(6),params(7))),providers_GP.k_star(1),Inf);      
        hcaboveo(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                      pdf('Exponential',k,pain).*...
                                      (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                      params(6),params(7))),providers_GP.k_star(1),Inf);
        sbelowo(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                      normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                      params(6),params(7)),providers_GP.k_star(1),Inf);
        cbelowo(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                      normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                      params(6),params(7)),providers_GP.k_star(1),Inf);
    
        sabove(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                     (1-normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                     params(6),params(7))),k_star_nosm(1),Inf);  
        hsabove(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                     pdf('Exponential',k,pain).*...
                                     (1-normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                     params(6),params(7))),k_star_nosm(1),Inf); 
        cabove(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                     (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                     params(6),params(7))),k_star_nosm(1),Inf);      
        hcabove(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                     pdf('Exponential',k,pain).*...
                                     (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                     params(6),params(7))),k_star_nosm(1),Inf);
        sbelow(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                     normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                     params(6),params(7)),k_star_nosm(1),Inf);
        cbelow(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                     normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                     params(6),params(7)),k_star_nosm(1),Inf);
    
        sabove_noop(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),k_star_nosm_noop(1),Inf);       
        hsabove_noop(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                          pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),k_star_nosm_noop(1),Inf); 
        cabove_noop(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),k_star_nosm_noop(1),Inf);      
        hcabove_noop(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                          pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),k_star_nosm_noop(1),Inf);
        sbelow_noop(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7)),k_star_nosm_noop(1),Inf);
        cbelow_noop(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7)),k_star_nosm_noop(1),Inf);
    
        parfor i = 2:n_GP
            above(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                        (1-normcdf(price-ben(k,params(4),params(5),c),...
                                        params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));
            habove(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                        pdf('Exponential',k,pain).*...
                                        (1-normcdf(price-ben(k,params(4),params(5),c),...
                                        params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));                        
            below(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                        normcdf(price-ben(k,params(4),params(5),c),...
                                        params(6),params(7)),providers_GP.k_star(i),providers_GP.k_star(i-1));
            hbelow(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                        pdf('Exponential',k,pain).*...
                                        normcdf(price-ben(k,params(4),params(5),c),...
                                        params(6),params(7)),providers_GP.k_star(i),providers_GP.k_star(i-1));
    
            saboveo(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));  
            hsaboveo(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                          pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));  
            caboveo(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));    
            hcaboveo(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                          pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));   
            sbelowo(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7)),providers_GP.k_star(i),providers_GP.k_star(i-1));
            cbelowo(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7)),providers_GP.k_star(i),providers_GP.k_star(i-1));
    
            sabove(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                         (1-normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                         params(6),params(7))),k_star_nosm(i),k_star_nosm(i-1));  
            hsabove(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                         pdf('Exponential',k,pain).*...
                                         (1-normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                         params(6),params(7))),k_star_nosm(i),k_star_nosm(i-1));  
            cabove(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                         (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                         params(6),params(7))),k_star_nosm(i),k_star_nosm(i-1));    
            hcabove(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                         pdf('Exponential',k,pain).*...
                                         (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                         params(6),params(7))),k_star_nosm(i),k_star_nosm(i-1));   
            sbelow(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                         normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                         params(6),params(7)),k_star_nosm(i),k_star_nosm(i-1));
            cbelow(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                         normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                         params(6),params(7)),k_star_nosm(i),k_star_nosm(i-1));
    
            sabove_noop(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                              (1-normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                              params(6),params(7))),k_star_nosm_noop(i),k_star_nosm_noop(i-1));  
            hsabove_noop(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                              pdf('Exponential',k,pain).*...
                                              (1-normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                              params(6),params(7))),k_star_nosm_noop(i),k_star_nosm_noop(i-1));  
            cabove_noop(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                              (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                              params(6),params(7))),k_star_nosm_noop(i),k_star_nosm_noop(i-1));    
            hcabove_noop(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                              pdf('Exponential',k,pain).*...
                                              (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                              params(6),params(7))),k_star_nosm_noop(i),k_star_nosm_noop(i-1));   
            sbelow_noop(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                              normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                              params(6),params(7)),k_star_nosm_noop(i),k_star_nosm_noop(i-1));
            cbelow_noop(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                              normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                              params(6),params(7)),k_star_nosm_noop(i),k_star_nosm_noop(i-1));
        end
    
        above(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                         (1-normcdf(price-ben(k,params(4),params(5),c),...
                                         params(6),params(7))),0,providers_GP.k_star(n_GP));
        habove(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                         pdf('Exponential',k,pain).*...
                                         (1-normcdf(price-ben(k,params(4),params(5),c),...
                                         params(6),params(7))),0,providers_GP.k_star(n_GP));
        below(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                         normcdf(price-ben(k,params(4),params(5),c),...
                                         params(6),params(7)),0,providers_GP.k_star(n_GP));
        hbelow(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                         pdf('Exponential',k,pain).*...
                                         normcdf(price-ben(k,params(4),params(5),c),...
                                         params(6),params(7)),0,providers_GP.k_star(n_GP));
    
        saboveo(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                           (1-normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                           params(6),params(7))),0,providers_GP.k_star(n_GP));
        hsaboveo(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                           pdf('Exponential',k,pain).*...
                                           (1-normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                           params(6),params(7))),0,providers_GP.k_star(n_GP));
        caboveo(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                           (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                           params(6),params(7))),0,providers_GP.k_star(n_GP));                                      
        hcaboveo(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                           pdf('Exponential',k,pain).*...
                                           (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                           params(6),params(7))),0,providers_GP.k_star(n_GP));                                             
        sbelowo(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                           normcdf(tau_s./Pfit_sm(k) + tau_o - ben(k,params(4),params(5),c),...
                                           params(6),params(7)),0,providers_GP.k_star(n_GP));
        cbelowo(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                           normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                           params(6),params(7)),0,providers_GP.k_star(n_GP));
                                                
        sabove(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),0,k_star_nosm(n_GP));
        hsabove(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                          pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),0,k_star_nosm(n_GP));
        cabove(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),0,k_star_nosm(n_GP));                                      
        hcabove(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                          pdf('Exponential',k,pain).*...
                                          (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7))),0,k_star_nosm(n_GP));                                             
        sbelow(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          normcdf(tau_s./Pfit_nosm(k) + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7)),0,k_star_nosm(n_GP));
        cbelow(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                          normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                          params(6),params(7)),0,k_star_nosm(n_GP));
                                                 
        sabove_noop(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                               (1-normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                               params(6),params(7))),0,k_star_nosm_noop(n_GP));
        hsabove_noop(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                               pdf('Exponential',k,pain).*...
                                               (1-normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                               params(6),params(7))),0,k_star_nosm_noop(n_GP));
        cabove_noop(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                               (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                               params(6),params(7))),0,k_star_nosm_noop(n_GP));                                      
        hcabove_noop(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                               pdf('Exponential',k,pain).*...
                                               (1-normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                               params(6),params(7))),0,k_star_nosm_noop(n_GP));                                             
        sbelow_noop(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                               normcdf(tau_s./Pfit_nosm_noop(k) + tau_o - ben(k,params(4),params(5),c),...
                                               params(6),params(7)),0,k_star_nosm_noop(n_GP));
        cbelow_noop(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                               normcdf(tau_d + tau_o - ben(k,params(4),params(5),c),...
                                               params(6),params(7)),0,k_star_nosm_noop(n_GP));
        
    %**********************************************************************
    %------------------------ Equilibrium outcomes -----------------------*
    %**********************************************************************
    
        %------------------------ With SM -------------------------%
      
        consume_sm = zeros(n_GP,1); 
        hconsume_sm = zeros(n_GP,1); 
        sell_sm = zeros(n_GP,1); 
        buy_sm = zeros(n_GP,1); 
        hbuy_sm = zeros(n_GP,1);
        
        parfor j = 1:jp    
            cumc = 0;
            cumhc = 0;
            cums = 0;
            for n = 1:j-1
                cumc = cumc + (1/((n_GP-n+1)*(n_GP-n)))*sum(above(n+1:j));
                cumhc = cumhc + (1/((n_GP-n+1)*(n_GP-n)))*sum(habove(n+1:j));
                cums = cums + (1/((n_GP-n+1)*(n_GP-n)))*sum(below(n+1:j));
            end
            consume_sm(j,1) = cumc + (1/n_GP)*sum(above(1:j));
            hconsume_sm(j,1) = cumhc + (1/n_GP)*sum(habove(1:j));
            sell_sm(j,1) = cums + (1/n_GP)*sum(below(1:j));
            buy_sm(j,1) = (1/n_GP)*sum(above(jp+1:n_GP+1));
            hbuy_sm(j,1) = (1/n_GP)*sum(habove(jp+1:n_GP+1));
        end
        
        cumc = 0;
        cumhc = 0;
        cums = 0;
        for n = 1:jp
            cumc = cumc + 1/((n_GP-n+1)*(n_GP-n))*sum(above(n+1:jp));
            cumhc = cumhc + 1/((n_GP-n+1)*(n_GP-n))*sum(habove(n+1:jp));
            cums = cums + 1/((n_GP-n+1)*(n_GP-n))*sum(below(n+1:jp));
        end
        parfor j = jp+1:n_GP
            consume_sm(j,1) = cumc + 1/n_GP*sum(above(1:j));
            hconsume_sm(j,1) = cumhc + 1/n_GP*sum(habove(1:j));
            sell_sm(j,1) = cums + 1/n_GP*sum(below(1:j));
            buy_sm(j,1) = (1/n_GP)*sum(above(j+1:n_GP+1));
            hbuy_sm(j,1) = (1/n_GP)*sum(habove(j+1:n_GP+1));
        end
        
        pres_sm = pop*(consume_sm + sell_sm); 
        health_sm = pop*(hconsume_sm + hbuy_sm);
        
        %------------------------ Remove SM -----------------------%
        
        % a. No reallocation 
        hsell_sm = zeros(n_GP,1); 
      
        parfor j = 1:jp    
            cumhs = 0;
            for n = 1:j-1
                cumhs = cumhs + (1/((n_GP-n+1)*(n_GP-n)))*sum(hbelow(n+1:j));
            end
            hsell_sm(j,1) = cumhs + (1/n_GP)*sum(hbelow(1:j));
        end
        cumhs = 0;
        for n = 1:jp
            cumhs = cumhs + 1/((n_GP-n+1)*(n_GP-n))*sum(hbelow(n+1:jp));
        end
        parfor j = jp+1:n_GP
            hsell_sm(j,1) = cumhs + (1/n_GP)*sum(hbelow(1:j));
        end
        
        pres_dir = pres_sm;
        health_dir = pop*(hconsume_sm + hsell_sm);
        
        % b. + New demand
        consume_newd = zeros(n_GP,1); 
        hconsume_newd = zeros(n_GP,1); 
       
        parfor j = 1:n_GP 
            cums = 0; 
            cumhs = 0;
            for n = 1:j-1
               cums = cums + (1/((n_GP-n+1)*(n_GP-n)))*sum(saboveo(n+1:j));
               cumhs = cumhs + (1/((n_GP-n+1)*(n_GP-n)))*sum(hsaboveo(n+1:j));
            end
            consume_newd(j,1) = cums + (1/n_GP)*sum(caboveo(1:j));
            hconsume_newd(j,1) = cumhs + (1/n_GP)*sum(hcaboveo(1:j));
        end 
        
        pres_newd = pop*consume_newd; 
        health_newd = pop*hconsume_newd;
        
        % c. + New thresholds
        consume_nosm = zeros(n_GP,1); 
        hconsume_nosm = zeros(n_GP,1); 
       
        parfor j = 1:n_GP 
            cums = 0; 
            cumhs = 0;
            for n = 1:j-1
               cums = cums + (1/((n_GP-n+1)*(n_GP-n)))*sum(sabove(n+1:j));
               cumhs = cumhs + (1/((n_GP-n+1)*(n_GP-n)))*sum(hsabove(n+1:j));
            end
            consume_nosm(j,1) = cums + (1/n_GP)*sum(cabove(1:j));
            hconsume_nosm(j,1) = cumhs + (1/n_GP)*sum(hcabove(1:j));
        end 
        
        pres_nosm = pop*consume_nosm; 
        health_nosm = pop*hconsume_nosm;
        
        %----------------- Remove overprescribing -----------------%
        % Loop for the secondary market to clear
    
        %----- With SM -----%    
        price_cf0 = 0;
        price_cfL = 0;
        price_cfH = 0;
        price_cf = price*(4/3);
        hbar_cf = harm_sm;
    
        pres_sell_noop = 100;
        pres_buy_noop = 0;
        countM = 1;
    
        while abs(price_cf0-price_cf) > 0.1 
            
            if countM == 2
                price_cf0 = price_cf;
                price_cf = price_cf0 + (pres_buy_noop - pres_sell_noop)/100;
            end
            if countM >= 3
                price_cf00 = price_cf0;
                price_cf0 = price_cf;
        
                if abs(pres_buy_noop - pres_sell_noop) <= 100
                    step = 1;
                end
                if abs(pres_buy_noop - pres_sell_noop) > 100 && abs(pres_buy_noop - pres_sell_noop) <= 1000
                    step = 10;
                end
                if abs(pres_buy_noop - pres_sell_noop) > 1000 && abs(pres_buy_noop - pres_sell_noop) <= 10000
                    step = 100;
                end
                if abs(pres_buy_noop - pres_sell_noop) > 10000
                    step = 1000;
                end
        
                if sign(pres_sell_noop0-pres_buy_noop0) ~= sign(pres_sell_noop-pres_buy_noop)
                    price_cf = (price_cf0 + price_cf00)/2;
                end
                if sign(pres_sell_noop0-pres_buy_noop0) == 1 && sign(pres_sell_noop-pres_buy_noop) == 1
                    if price_cfL ~= 0
                        price_cf = (price_cf0 + price_cfL)/2;
                    else
                        price_cf = price_cf0 + (pres_buy_noop - pres_sell_noop)/step;
                    end
                end
                if sign(pres_sell_noop0-pres_buy_noop0) == -1 && sign(pres_sell_noop-pres_buy_noop) == -1
                    if price_cfH ~= 0
                        price_cf = (price_cf0 + price_cfH)/2;
                    else
                        price_cf = price_cf0 + (pres_buy_noop - pres_sell_noop)/step;
                    end
                end
            end
            if price_cf < 0 
                price_cf = 0;
            end
      
            hbar_cf0 = 0;
            count = 1; 
            
            while abs(hbar_cf0-hbar_cf) > 0.1 & count < 25
        
                if count ~= 1 
                    hbar_cf = (hbar_cf + hbar_cf0)/2;
                end
    
                % Update optimal thresholds
                LHS_deriv = @(x) 1 - normcdf(price_cf-x,params(6),params(7)) +...
                            normpdf(price_cf-x,params(6),params(7))*(x-hbar_cf);
                min_hkstar = fzero(LHS_deriv,-100,options); 
                min_RHS = min_hkstar + normcdf(price_cf-min_hkstar,params(6),params(7))*(hbar_cf-min_hkstar);
              
                k_star_sm_noop = zeros(n_GP,1);
                parfor i=1:n_GP
                    scal_fac=providers_GP.R(i)./beta_params(providers_GP.beta(i));
                    if -scal_fac >= min_RHS
                        LHS_func = @(x) x+normcdf(price_cf-x,params(6),params(7)).*(hbar_cf-x)+scal_fac;
                        hk_star = fzero(LHS_func,[min_hkstar 10000]);
                        k_star_sm_noop(i) = inv_ben(hk_star,params(4),params(5),c);
                    end
                end
                sortrows(k_star_sm_noop,'descend');
    
                % Stop overprescribing 
                k_star_sm_noop(k_star_sm_noop<=k_star_0) = k_star_0;
           
                % Update search process
                Pk_sm_noop = [(0:(max(k_star_sm_noop)+1)/1000:max(k_star_sm_noop)+1)',0.*(0:(max(k_star_sm_noop)+1)/1000:max(k_star_sm_noop)+1)'];
                for x = 1:length(Pk_sm_noop)
                    Pk_sm_noop(x,2) = sum(k_star_sm_noop <= Pk_sm_noop(x,1))/n_GP;
                end
            
                Pfit_sm_noop = fit(Pk_sm_noop(:,1),Pk_sm_noop(:,2),'linearinterp');
                Pfit_sm_noop = @(x) Pfit_sm_noop(x)';
            
                P_tilde_noop = fzero(@(x) Pfit_sm_noop(x) - tau_s/(price_cf-tau_o),2);
                jp_noop = n_GP-sum(k_star_sm_noop < P_tilde_noop); 
                if jp_noop == 0 
                    jp_noop = 1;
                end
                P_tilde_noop = k_star_sm_noop(jp_noop);
                                        
                % Base pieces
                above_noop = zeros(n_GP+1,1); 
                habove_noop = zeros(n_GP+1,1);
                below_noop = zeros(n_GP,1); 
                hbelow_noop = zeros(n_GP+1,1);
        
                above_noop(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                                 (1-normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                 params(6),params(7))),k_star_sm_noop(1),Inf);
                habove_noop(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                                 pdf('Exponential',k,pain).*...
                                                 (1-normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                 params(6),params(7))),k_star_sm_noop(1),Inf);                        
                below_noop(1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                                 normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                 params(6),params(7)),k_star_sm_noop(1),Inf);
                hbelow_noop(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                                 pdf('Exponential',k,pain).*...
                                                 normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                 params(6),params(7)),k_star_sm_noop(1),Inf); 
                parfor i = 2:n_GP
                    above_noop(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                                     (1-normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                     params(6),params(7))),k_star_sm_noop(i),k_star_sm_noop(i-1));
                    habove_noop(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                                     pdf('Exponential',k,pain).*...
                                                     (1-normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                     params(6),params(7))),k_star_sm_noop(i),k_star_sm_noop(i-1));                        
                    below_noop(i,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                                     normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                     params(6),params(7)),k_star_sm_noop(i),k_star_sm_noop(i-1));
                    hbelow_noop(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                                     pdf('Exponential',k,pain).*...
                                                     normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                     params(6),params(7)),k_star_sm_noop(i),k_star_sm_noop(i-1));
                end
                above_noop(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                                      (1-normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                      params(6),params(7))),0,k_star_sm_noop(n_GP));
                habove_noop(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                                      pdf('Exponential',k,pain).*...
                                                      (1-normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                      params(6),params(7))),0,k_star_sm_noop(n_GP));
                below_noop(n_GP+1,1) = integral(@(k)  pdf('Exponential',k,pain).*...
                                                      normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                      params(6),params(7)),0,k_star_sm_noop(n_GP));
                hbelow_noop(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                                                      pdf('Exponential',k,pain).*...
                                                      normcdf(price_cf-ben(k,params(4),params(5),c),...
                                                      params(6),params(7)),0,k_star_sm_noop(n_GP));
        
                % Equilibrium outcomes 
                consume_sm_noop = zeros(n_GP,1); 
                hconsume_sm_noop = zeros(n_GP,1); 
                buy_sm_noop = zeros(n_GP,1); 
                hbuy_sm_noop = zeros(n_GP,1);
                sell_sm_noop = zeros(n_GP,1); 
               
                parfor j = 1:jp_noop    
                    cumc = 0;
                    cumhc = 0;
                    cums = 0;
                    for n = 1:j-1
                        cumc = cumc + (1/((n_GP-n+1)*(n_GP-n)))*sum(above_noop(n+1:j));
                        cumhc = cumhc + (1/((n_GP-n+1)*(n_GP-n)))*sum(habove_noop(n+1:j));
                        cums = cums + (1/((n_GP-n+1)*(n_GP-n)))*sum(below_noop(n+1:j));
                    end
                    consume_sm_noop(j,1) = cumc + (1/n_GP)*sum(above_noop(1:j));
                    hconsume_sm_noop(j,1) = cumhc + (1/n_GP)*sum(habove_noop(1:j));
                    sell_sm_noop(j,1) = cums + (1/n_GP)*sum(below_noop(1:j));
                    buy_sm_noop(j,1) = (1/n_GP)*sum(above_noop(jp_noop+1:n_GP+1));
                    hbuy_sm_noop(j,1) = (1/n_GP)*sum(habove_noop(jp_noop+1:n_GP+1));
                end
            
                cumc = 0;
                cumhc = 0;
                cums = 0;
                for n = 1:jp_noop
                    cumc = cumc + 1/((n_GP-n+1)*(n_GP-n))*sum(above_noop(n+1:jp_noop));
                    cumhc = cumhc + 1/((n_GP-n+1)*(n_GP-n))*sum(habove_noop(n+1:jp_noop));
                    cums = cums + 1/((n_GP-n+1)*(n_GP-n))*sum(below_noop(n+1:jp_noop));
                end
                parfor j = jp_noop+1:n_GP
                    consume_sm_noop(j,1) = cumc + (1/n_GP)*sum(above_noop(1:j));
                    hconsume_sm_noop(j,1) = cumhc + (1/n_GP)*sum(habove_noop(1:j));
                    sell_sm_noop(j,1) = cums + (1/n_GP)*sum(below_noop(1:j));
                    buy_sm_noop(j,1) = (1/n_GP)*sum(above_noop(j+1:n_GP+1));
                    hbuy_sm_noop(j,1) = (1/n_GP)*sum(habove_noop(j+1:n_GP+1));
                end
            
                pres_sm_noop = pop*(consume_sm_noop + sell_sm_noop); 
                health_sm_noop = pop*(hconsume_sm_noop + hbuy_sm_noop);
           
                hbar_cf0 = hbar_cf;
                if sum(buy_sm_noop) > 0
                    hbar_cf = sum(hbuy_sm_noop)/sum(buy_sm_noop);
                else
                    hbar_cf = 0;
                end
        
                count = count + 1;
            end
      
            if countM ~= 1
                pres_sell_noop0 = pres_sell_noop;
                pres_buy_noop0 = pres_buy_noop;
            end
        
            pres_sell_noop = pop*sum(sell_sm_noop);
            pres_buy_noop = pop*sum(buy_sm_noop);
        
            if pres_buy_noop - pres_sell_noop > 0
                price_cfL = price_cf;
            else
                price_cfH = price_cf;
            end
    
            countM = countM + 1;
        end
        
        if strcmp(mlist{m},'39400') && r == 1 
            fprintf('Counterfactual price: %.4f\n', price_cf);
            fprintf('Percent change: %.4f\n', price_cf/price - 1);
        end

        %---- Without SM ---%
        consume_nosm_noop = zeros(n_GP,1); 
        hconsume_nosm_noop = zeros(n_GP,1); 
       
        parfor j = 1:n_GP 
            cums = 0; 
            cumhs = 0;
            for n = 1:j-1
               cums = cums + (1/((n_GP-n+1)*(n_GP-n)))*sum(sabove_noop(n+1:j));
               cumhs = cumhs + (1/((n_GP-n+1)*(n_GP-n)))*sum(hsabove_noop(n+1:j));
            end
            consume_nosm_noop(j,1) = cums + (1/n_GP)*sum(cabove_noop(1:j));
            hconsume_nosm_noop(j,1) = cumhs + (1/n_GP)*sum(hcabove_noop(1:j));
        end 
        
        pres_nosm_noop = pop*consume_nosm_noop; 
        health_nosm_noop = pop*hconsume_nosm_noop;

%**********************************************************************
%------------------------------- Tables ------------------------------*
%**********************************************************************  

        if strcmp(mlist{m},'39400') && r == 1
    
            % Table: parameters 
            params_CI = [params',CI];
           
            % Convert to cell for formatting
            params_CI_fmt = cell(13,2);
            params_CI_fmt(1,:)  = {sprintf('%.3f',params_CI(1,1)),sprintf('[%.3f, %.3f]',params_CI(1,2),params_CI(1,3))};
            params_CI_fmt(2,:)  = {sprintf('%.3f',1),''};
            params_CI_fmt(3,:)  = {sprintf('%.3f',params_CI(2,1)),sprintf('[%.3f, %.3f]',params_CI(2,2),params_CI(2,3))};
            params_CI_fmt(4,:)  = {sprintf('%.2f',params_CI(3,1)),sprintf('[%.2f, %.2f]',params_CI(3,2),params_CI(3,3))};
            params_CI_fmt(5,:)  = {sprintf('%.1f',params_CI(4,1)),sprintf('[%.1f, %.1f]',params_CI(4,2),params_CI(4,3))};
            params_CI_fmt(6,:)  = {sprintf('%.3f',params_CI(5,1)),sprintf('[%.3f, %.3f]',params_CI(5,2),params_CI(5,3))};
            params_CI_fmt(7,:)  = {sprintf('%.4f',c),''};
            params_CI_fmt(8,:)  = {sprintf('%.3f',pain),''};
            params_CI_fmt(9,:)  = {sprintf('%.1f',params_CI(6,1)),sprintf('[%.1f, %.1f]',params_CI(6,2),params_CI(6,3))};
            params_CI_fmt(10,:) = {sprintf('%.2f',params_CI(7,1)),sprintf('[%.2f, %.2f]',params_CI(7,2),params_CI(7,3))};
            params_CI_fmt(11,:) = {sprintf('%.2f',tau_d),''};
            params_CI_fmt(12,:) = {sprintf('%.2f',tau_o),''};
            params_CI_fmt(13,:) = {sprintf('%.2f',params_CI(8,1)),sprintf('[%.2f, %.2f]',params_CI(8,2),params_CI(8,3))};
            writecell(params_CI_fmt,'results/Table_2_raw.xlsx');
            
            % Table: model fit 
            model_fit = [mean(providers_GP.pres(providers_GP.beta==1)),mean(pres_sm(providers_GP.beta==1));...
                         mean(providers_GP.pres(providers_GP.beta==2)),mean(pres_sm(providers_GP.beta==2));...
                         mean(providers_GP.pres(providers_GP.beta==3)),mean(pres_sm(providers_GP.beta==3));...
                         mean(providers_GP.pres(providers_GP.beta==4)),mean(pres_sm(providers_GP.beta==4));...
                         mean(providers_GP.pres(providers_GP.R_group==1)),mean(pres_sm(providers_GP.R_group==1));...
                         mean(providers_GP.pres(providers_GP.R_group==2)),mean(pres_sm(providers_GP.R_group==2));...
                         mean(providers_GP.pres(providers_GP.R_group==3)),mean(pres_sm(providers_GP.R_group==3));...
                         mkt_price,price;...
                         100*misuse_sm,100*sum(buy_sm)];
  
            % Convert to cell for formatting
            model_fit_fmt = cell(size(model_fit));
            for i = 1:7
                model_fit_fmt(i,:) = {sprintf('%.2f',model_fit(i,1)),sprintf('%.2f',model_fit(i,2))};
            end
            model_fit_fmt(8,:) = {sprintf('%.1f',model_fit(8,1)),sprintf('%.1f',model_fit(8,2))};
            model_fit_fmt(9,:) = {sprintf('%.3f',model_fit(9,1)),sprintf('%.3f',model_fit(9,2))};
            writecell(model_fit_fmt,'results/Table_3_raw.xlsx');
        end

        pres_sm = sum(pres_sm);
        pres_dir = sum(pres_dir);
        pres_newd = sum(pres_newd);
        pres_nosm = sum(pres_nosm);
        pres_sm_noop = sum(pres_sm_noop);
        pres_nosm_noop = sum(pres_nosm_noop);
        
        health_sm = sum(health_sm);
        health_dir = sum(health_dir);
        health_newd = sum(health_newd);
        health_nosm = sum(health_nosm);
        health_sm_noop = sum(health_sm_noop);
        health_nosm_noop = sum(health_nosm_noop);
        
        scale = op_US/pres_sm;
        billions = 1/(10^9);
        hmillions = 1/(10^8);

        if strcmp(mlist{m},'39400') && r == 1 
    
            % Table: changes in prescriptions, changes in health impacts
            CF_table = [scale*pres_sm*hmillions,0,scale*health_sm*billions,0;...
                             scale*pres_dir*hmillions,100*(pres_dir-pres_sm)/abs(pres_sm),scale*health_dir*billions,scale*(health_dir-health_sm)*billions;...
                             scale*pres_newd*hmillions,100*(pres_newd-pres_sm)/abs(pres_sm),scale*health_newd*billions,scale*(health_newd-health_sm)*billions;...
                             scale*pres_nosm*hmillions,100*(pres_nosm-pres_sm)/abs(pres_sm),scale*health_nosm*billions,scale*(health_nosm-health_sm)*billions;...
                             scale*pres_sm_noop*hmillions,100*(pres_sm_noop-pres_sm)/abs(pres_sm),scale*health_sm_noop*billions,scale*(health_sm_noop-health_sm)*billions;...
                             scale*pres_nosm_noop*hmillions,100*(pres_nosm_noop-pres_sm)/abs(pres_sm),scale*health_nosm_noop*billions,scale*(health_nosm_noop-health_sm)*billions];   
           
            % Convert to cell for formatting
            CF_table_fmt = cell(size(CF_table));
            for i = 1:size(CF_table,1)

                CF_table_fmt{i,1} = sprintf('%.2f',CF_table(i,1));
                CF_table_fmt{i,3} = sprintf('%.2f',CF_table(i,3));
                
                if i == 1
                    CF_table_fmt{i,2} = '--';
                    CF_table_fmt{i,4} = '--';
                else
                    val = CF_table(i,2);
                    if abs(val) >= 10
                        CF_table_fmt{i,2} = sprintf('%.1f', val);
                    else
                        CF_table_fmt{i,2} = sprintf('%.2f', val);
                    end

                    val = CF_table(i,4);
                    if abs(val - round(val)) < 1e-5
                        CF_table_fmt{i,4} = sprintf('%.1f', val);
                    else
                        CF_table_fmt{i,4} = sprintf('%.2f', val);
                    end
                end
            end
            writecell(CF_table_fmt,'results/Table_4_raw.xlsx');
        end

        if r == 1 
            mkt = str2double(mlist{m});
            CF_altmkts = [CF_altmkts;...
                          mkt,100*(pres_nosm-pres_sm)/abs(pres_sm),100*(pres_sm_noop-pres_sm)/abs(pres_sm),scale*(health_nosm_noop-health_sm)*billions];
            writematrix(CF_altmkts,'intermediate/output_CF_altmkts.xlsx');
        end
        if strcmp(mlist{m},'39400')
            CF_altR = [CF_altR;...
                          r,100*(pres_nosm-pres_sm)/abs(pres_sm),100*(pres_sm_noop-pres_sm)/abs(pres_sm),scale*(health_nosm_noop-health_sm)*billions];
            writematrix(CF_altR,'intermediate/output_CF_altR.xlsx');
        end

%**********************************************************************
%------------------------------ Figures ------------------------------*
%**********************************************************************

        %---------------------- Health impact ---------------------%
        % Health impact overlaid with pain CDF
    
        if strcmp(mlist{m},'39400') && r == 1 
    
            x = 0:0.01:2.5;
            y = ben(x,params(4),params(5),c);
            
            fig1 = figure;
            set(fig1,'defaultAxesColorOrder',[[0 0 0];[0 0 0]]);
            yline(0);
            hold on
            
            yyaxis left
            l1 = plot(x,y,'linewidth',2,'color',[78/255 42/255 132/255]);
            xlabel('Pain severity ($\kappa$)','interpreter','latex','FontSize',14)
            ylabel('Health impact of opioid prescription (h($\kappa$))','interpreter','latex','FontSize',14)
            
            yyaxis right
            
            mkt_chars = readtable('intermediate/markets_chars.csv');
            pain_US = mkt_chars.pain(mkt_chars.czone == 0);
            clear mkt_chars
            y2 = expcdf(x,pain_US);
            l2 = plot(x,y2,'linewidth',2,'color',[204/255 196/255 223/255]);
            
            y3 = expcdf(x,pain);
            l3 = plot(x,y3,'linewidth',1.5,'color',[204/255 196/255 223/255]);
            ylabel('CDF of pain ($F(\kappa)$)','interpreter','latex','FontSize',14)
            
            leg = legend([l1 l2 l3],'Health impact function','CDF of pain: U.S.','CDF of pain: Seattle','Location','southeast');
            legend boxoff
            leg.FontSize = 14;
            
            print('-depsc','-r200','results/Figure_7')
            close
        end

    end
end

delete(gcp('nocreate'));

%**********************************************************************

diary off