clear

load('1');

delta_vector = (0.01:0.01:0.99);  
lamda_vector = (0.1 : 0.1:   9); 
% lnP = delta.*lamda.*0;     % n*m  

m1 = dataset.Today_pay;
m2 = dataset.Future_pay;
t = dataset.Weeks_delayed;
x = dataset.Choose_future;

% for i = 1:75
%     if x(i)
%         prob = exp(lamda.*delta.*m2(i))./exp(lamda.*m1(i)+lamda.*delta.*m2(i));
%     else
%         prob = exp(lamda.*m1(i))./exp(lamda.*m1(i)+lamda.*delta.*m2(i));
%     end
% end

% P = zeros(length(delta_vector),length(lamda_vector));
% lnP = zeros(length(delta_vector),length(lamda_vector));
% 
for d = 1:length(delta_vector)
    delta = delta_vector(d);
    for e = 1:length(lamda_vector)
        lamda = lamda_vector(e);
        
        % create "prob" as a probabilty of an observation occurs 
        prob = zeros(1,75);
        for i = 1:75
            % when future option is chosen
            if x(i) == 1 
                prob(i) = exp(lamda*(delta.^t(i))*m2(i))./((exp(lamda*m1(i))+exp(lamda*(delta.^t(i)))*m2(i)));
                
            % when today option is chosen
            else
                prob(i) = exp(lamda*m1(i))./((exp(lamda*m1(i))+exp(lamda*(delta.^t(i)))*m2(i)));
            end
        end
        % let P denote the products of prob of observation (i.e. likelihood function)
        % then, lnP is the log-likelihood function 
        % note: lnP specifies which delta and lamda 
        % P(d,e) = prod(prob,'all');
        lnP(d,e) = sum(log(prob),'all');
        
    end
end

max_like_hood = max(lnP, [], 'all');
[max_d, max_e] = find(lnP == max_like_hood);
delta_hat = delta_vector(max_d);
lamda_hat = lamda_vector(max_e);