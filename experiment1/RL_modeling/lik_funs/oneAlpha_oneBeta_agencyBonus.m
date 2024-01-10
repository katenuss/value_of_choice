
function [lik, latents] = oneAlpha_oneBeta_agencyBonus(QbanditOrder, agencyChoiceVec, banditChoiceVec, outcome, agency, offer, leftBandit, rightBandit, x, priors)
alpha = x(1);
beta = x(2);
agencyBonus = x(3);

% initialize log likelihood and q values
lik = 0;
Qbandit = .5 * ones(3,2);

% Loop through trials
for ii = 1:length(outcome)
    
    % get Q indices for left and right bandit
    leftBanditQidx = find(contains(QbanditOrder,leftBandit{ii}));
    rightBanditQidx = find(contains(QbanditOrder,rightBandit{ii}));
    
    % offer
    thisTrial_offer = offer(ii);
    
    % agency choice
    thisTrial_agencyResp = agencyChoiceVec(ii);
    
    % estimate EVcomp
    estEVcomp(ii) = .5*Qbandit(leftBanditQidx) + .5*Qbandit(rightBanditQidx) + thisTrial_offer/10;
    
    % KN note - look into
    % if estEVcomp(ii)>1
    %     estEVcomp(ii)=1;
    % end
    
    % estimate EVchoice
    estEVchoice(ii) = max([Qbandit(leftBanditQidx), Qbandit(rightBanditQidx)]) + agencyBonus;
    
    %combine both Q value estimates into a vector
    thisTrial_agencyQs = [estEVcomp(ii), estEVchoice(ii)];
    
    %choice function
    numerator = exp(thisTrial_agencyQs(thisTrial_agencyResp)*beta);
    denominator = sum(exp(([estEVcomp(ii), estEVchoice(ii)])*beta));
    
    % probability of selecting choice
    lik_choice(ii) = numerator/denominator;
    
    %updating loglikelihood of choice
    lik = lik + log(lik_choice(ii));
    
    % bandit choice
    thisTrial_banditResp = banditChoiceVec(ii);
    thisTrial_banditQs = [Qbandit(leftBanditQidx), Qbandit(rightBanditQidx)];
    
    if thisTrial_banditResp == 1
        selectedBandit = leftBandit{ii};
    else
        selectedBandit = rightBandit{ii};
    end
    
    if agency(ii) == 1
        numerator = exp(thisTrial_banditQs(thisTrial_banditResp)*beta);
        denominator = sum(exp((thisTrial_banditQs)*beta));
        lik_choice = numerator/denominator; % probability of selecting choice 1
        
        %updating loglikelihood of choice
        lik = lik + log(lik_choice);
    end
    
    % Update Q value
    RPE = outcome(ii) - thisTrial_banditQs(thisTrial_banditResp); % outcome minus expectation
    Qbandit(find(contains(QbanditOrder,selectedBandit))) = Qbandit(find(contains(QbanditOrder,selectedBandit))) + alpha * RPE;
    
    % save latent variables
    latents.banditQs(ii, :) = thisTrial_banditQs;
    latents.estEVChoice(ii) = estEVchoice(ii);
    latents.estEVComp(ii) = estEVcomp(ii);
    latents.RPE(ii) = RPE;

end


% Put priors on parameters
if (priors)
    lik = lik + log(betapdf(alpha, 1.1, 1.1));
    lik = lik + log(gampdf(beta, 2 , 3));
    lik = lik + log(normpdf(agencyBonus, 0, 3));
end


%flip sign of log likelihood (which is negative, and we want it to be as close to 0 as possible; i.e. as high as possible) so we can enter it into fmincon, which searches for minimum, rather than maximum values
lik = -lik;
end
