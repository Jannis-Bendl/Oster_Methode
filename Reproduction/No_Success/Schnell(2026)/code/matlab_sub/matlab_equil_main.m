
function [F,price,harm_sm] = matlab_equil_main(params,providers_GP,markets)
    
    options = optimset('Display','off');
    
    beta_params = [params(1),1,params(2),params(3)];
    tau_s = params(8) + markets.tau_d(1);
    c = 0.0001;

    price0 = 0;
    priceL = 0;
    priceH = 0;
    price = markets.price(1);
    mkt_price = markets.price(1);

    n_GP = height(providers_GP);
    pain = markets.pain(1);
    tau_o = markets.tau_o(1);
    pop = markets.pop(1);
    misuse_sm = markets.misuse_sm(1);
    clearvars markets

    pres_sell = 100;
    pres_buy = 0;
    countM = 1;

    while abs(price0-price) > 0.01 && abs(pres_sell - pres_buy) > 10 && countM < 30
        if countM == 2
            price0 = price;
            price = price0 + (pres_buy - pres_sell)/100;
        end
        if countM >= 3
            price00 = price0;
            price0 = price;
    
            if abs(pres_buy - pres_sell) <= 100
                step = 1;
            end
            if abs(pres_buy - pres_sell) > 100 && abs(pres_buy - pres_sell) <= 1000
                step = 10;
            end
            if abs(pres_buy - pres_sell) > 1000 && abs(pres_buy - pres_sell) <= 10000
                step = 100;
            end
            if abs(pres_buy - pres_sell) > 10000
                step = 1000;
            end
    
            if sign(pres_sell0-pres_buy0) ~= sign(pres_sell-pres_buy)
                price = (price0 + price00)/2;
            end
            if sign(pres_sell0-pres_buy0) == 1 && sign(pres_sell-pres_buy) == 1
                if priceL ~= 0
                    price = (price0 + priceL)/2;
                else
                    price = price0 + (pres_buy - pres_sell)/step;
                end
            end
            if sign(pres_sell0-pres_buy0) == -1 && sign(pres_sell-pres_buy) == -1
                if priceH ~= 0
                    price = (price0 + priceH)/2;
                else
                    price = price0 + (pres_buy - pres_sell)/step;
                end
            end
        end
        if price < 0 
            price = 0;
        end

        harm_sm = -125;
        harm_sm0 = 0;
    
        count = 1;
        while abs(harm_sm0-harm_sm) > 0.1 && count < 25
        
            if count ~= 1 && harm_sm ~= 0
                harm_sm = (harm_sm + harm_sm0)/2;
            end
        
            %---------------------------------------------------------------------%
            %---------------- 1. Given parameters, extract k_stars ---------------%
            %---------------------------------------------------------------------%
   
            % Compute minimum to determine when no solution
            RHS_deriv = @(x) 1 - normcdf(price-x,params(6),params(7)) + ...
                normpdf(price-x,params(6),params(7))*(x-harm_sm);
            min_hkstar1 = fzero(RHS_deriv,-100,options);
            min_hkstar2 = fzero(RHS_deriv,100,options);
            min_RHS = min_hkstar1 + normcdf(price-min_hkstar1,params(6),params(7))*(harm_sm-min_hkstar1);

            k_star = zeros(1,n_GP);

            % If RHS not flat
            if abs(min_hkstar1 - min_hkstar2) < 1 

                % Smooth for parameter search 
                min_kstar = inv_ben(min_hkstar1,params(4),params(5),c);
                if min_kstar > 0 
                    RHS_func = @(x) ben(x,params(4),params(5),c) + normcdf(price-ben(x,params(4),params(5),c),params(6),params(7)).*(harm_sm-ben(x,params(4),params(5),c));
                    RHS_smooth = interp1([min_kstar:(3-min_kstar)/1000:3],RHS_func(min_kstar:(3-min_kstar)/1000:3),[0:min_kstar/1000:min_kstar],'linear','extrap');
                    RHS_smooth = [[0:min_kstar/1000:min_kstar]',RHS_smooth'];
                    RHS_smooth = fit(RHS_smooth(:,1),RHS_smooth(:,2),'linearinterp');
                    RHS_smooth = @(x) RHS_smooth(x)';
                else
                    RHS_smooth = @(x) Inf;
                end
                
                % Solve for k_stars   
                parfor i=1:n_GP
                    scal_fac=providers_GP.R(i)./beta_params(providers_GP.beta(i));
                    if -scal_fac >= min_RHS
                        RHS_func = @(x) x + normcdf(price-x,params(6),params(7)).*(harm_sm-x) + scal_fac;
                        try 
                            hk_star = fzero(RHS_func,[min_hkstar1 10000]);
                            k_star(i) = inv_ben(hk_star,params(4),params(5),c);
                        catch 
                            warning('off');
                            k_star(i) = 10;
                            warning('on');
                        end
                    elseif -scal_fac >= RHS_smooth(0)
                        RHS_func = @(x) RHS_smooth(x) + scal_fac;
                        k_star(i) = fzero(RHS_func,[0 min_kstar]);
                    end
                end
            else
                % Solve for k_stars   
                parfor i=1:n_GP
                    scal_fac=providers_GP.R(i)./beta_params(providers_GP.beta(i));
                    if -scal_fac >= min_RHS
                        k_star(i) = 10;
                    end
                end
            end
            providers_GP = [providers_GP,array2table(k_star','VariableNames',{'k_star'})];
            
            %---------------------------------------------------------------------%
            %------------------------ 2. Get eCDF of P(k) ------------------------%
            %---------------------------------------------------------------------%
    
            % Empirical distribution of P(k)
            Pk = [(0:(max(providers_GP.k_star)+1)/1000:max(providers_GP.k_star)+1)',...
                0.*(0:(max(providers_GP.k_star)+1)/1000:max(providers_GP.k_star)+1)'];
            for x = 1:length(Pk)
                Pk(x,2) = sum(providers_GP.k_star <= Pk(x,1))/n_GP;
            end
    
            % Fit probability function
            Pfit = fit(Pk(:,1),Pk(:,2),'linearinterp');
            Pfit = @(x) Pfit(x)';
    
            % Solve for P_tilde  
            if tau_s/(price-tau_o) <= 1 
                if Pfit(0) >= tau_s/(price-tau_o)
                    P_tilde = 0;
                else
                    P_tilde = fzero(@(x) Pfit(x) - tau_s/(price-tau_o),2);
                end
                jp = n_GP-sum(providers_GP.k_star < P_tilde);
            else 
                jp = 1;
            end
            providers_GP = sortrows(providers_GP,'k_star','descend');
            if jp ~= 0
                P_tilde = providers_GP.k_star(jp);
            end
    
            %---------------------------------------------------------------------%
            %------------ 3. Compute market shares by consumption type -----------%
            %---------------------------------------------------------------------%
    
            %--------------------- 0. Base pieces ---------------------%
    
            above = zeros(n_GP+1,1);
            habove = zeros(n_GP+1,1);
            below = zeros(n_GP,1);
    
            above(1,1) = integral(@(k) pdf('Exponential',k,pain).*...
                (1-normcdf(price-ben(k,params(4),params(5),c),...
                params(6),params(7))),providers_GP.k_star(1),Inf);
            habove(1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                pdf('Exponential',k,pain).*...
                (1-normcdf(price-ben(k,params(4),params(5),c),...
                params(6),params(7))),providers_GP.k_star(1),Inf);
            below(1,1) = integral(@(k) pdf('Exponential',k,pain).*...
                normcdf(price-ben(k,params(4),params(5),c),...
                params(6),params(7)),providers_GP.k_star(1),Inf);
            parfor i = 2:n_GP
                above(i,1) = integral(@(k) pdf('Exponential',k,pain).*...
                    (1-normcdf(price-ben(k,params(4),params(5),c),...
                    params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));
                habove(i,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                    pdf('Exponential',k,pain).*...
                    (1-normcdf(price-ben(k,params(4),params(5),c),...
                    params(6),params(7))),providers_GP.k_star(i),providers_GP.k_star(i-1));
                below(i,1) = integral(@(k) pdf('Exponential',k,pain).*...
                    normcdf(price-ben(k,params(4),params(5),c),...
                    params(6),params(7)),providers_GP.k_star(i),providers_GP.k_star(i-1));
            end
            above(n_GP+1,1) = integral(@(k) pdf('Exponential',k,pain).*...
                (1-normcdf(price-ben(k,params(4),params(5),c),...
                params(6),params(7))),0,providers_GP.k_star(n_GP));
            habove(n_GP+1,1) = integral(@(k) ben(k,params(4),params(5),c).*...
                pdf('Exponential',k,pain).*...
                (1-normcdf(price-ben(k,params(4),params(5),c),...
                params(6),params(7))),0,providers_GP.k_star(n_GP));
            below(n_GP+1,1) = integral(@(k) pdf('Exponential',k,pain).*...
                normcdf(price-ben(k,params(4),params(5),c),...
                params(6),params(7)),0,providers_GP.k_star(n_GP));
    
            %---------------- i. Prescribed medication ----------------%
            %------------------- ii. Not prescribed -------------------%
            % Consume or sell
            % Buy or do nothing
    
            consume = zeros(n_GP,1);
            sell = zeros(n_GP,1);
            buy = zeros(n_GP,1);
            hbuy = zeros(n_GP,1);
    
            parfor j = 1:n_GP
                cumc = 0;
                cums = 0;
                if j <= jp                
                    for n = 1:j-1
                        cumc = cumc + (1/((n_GP-n+1)*(n_GP-n)))*sum(above(n+1:j));
                        cums = cums + (1/((n_GP-n+1)*(n_GP-n)))*sum(below(n+1:j));
                    end
                    buy(j,1) = (1/n_GP)*sum(above(jp+1:n_GP+1));
                    hbuy(j,1) = (1/n_GP)*sum(habove(jp+1:n_GP+1));
                else 
                    for n = 1:jp-1
                        cumc = cumc + 1/((n_GP-n+1)*(n_GP-n))*sum(above(n+1:jp));
                        cums = cums + 1/((n_GP-n+1)*(n_GP-n))*sum(below(n+1:jp));
                    end
                    buy(j,1) = (1/n_GP)*sum(above(j+1:n_GP+1));
                    hbuy(j,1) = (1/n_GP)*sum(habove(j+1:n_GP+1));
                end
                consume(j,1) = cumc + (1/n_GP)*sum(above(1:j));
                sell(j,1) = cums + (1/n_GP)*sum(below(1:j));
            end
                    
            %---------------------------------------------------------------------%
            %----------------------------- 4. MOMENTS ----------------------------%
            %---------------------------------------------------------------------%
    
            harm_sm0 = harm_sm;
            if sum(buy) > 0
                harm_sm = sum(hbuy)/sum(buy);
            else
                harm_sm = 0;
            end
    
            count = count + 1;
            providers_GP = providers_GP(:,1:7);
        end
    
        if countM ~= 1
            pres_sell0 = pres_sell;
            pres_buy0 = pres_buy;
        end
    
        pres = pop*(consume+sell);
        pres_sell = pop*sum(sell);
        pres_buy = pop*sum(buy);
    
        if pres_buy - pres_sell > 0
            priceL = price;
        else
            priceH = price;
        end
    
        countM = countM + 1;
    end

    % MOMENTS
    M=zeros(1,10);
    for i=1:4
        M(i) = mean(pres(providers_GP.beta==i)) - mean(providers_GP.pres(providers_GP.beta==i));
    end
    for i=1:3
        M(i+4) = mean(pres(providers_GP.R_group==i)) - mean(providers_GP.pres(providers_GP.R_group==i));
    end
    
    % Rescale to make same order of magnitude
    M(8) = 5000*(misuse_sm-sum(buy));
    M(9) = 0.1*(mkt_price-price);
    M(10) = 0.01*(pres_sell-pres_buy);
    
    F = M*M';

end
