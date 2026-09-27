function [lambdaS, lambdaG, lambda] = geomConstants(P, beta)

    lambdaS = 2^(5/3)*P.r^(1/3)*beta^(2/3);
    lambdaG = P.r*beta;
    lambda  = (4/3)*sqrt(P.r/pi)*beta;
    
end