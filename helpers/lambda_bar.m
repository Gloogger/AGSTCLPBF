function lb = lambda_bar(P, beta)
    [~, ~, lambda] = geomConstants(P, beta);
    lb = 2/(3*lambda*P.rho*P.eInternal);
end