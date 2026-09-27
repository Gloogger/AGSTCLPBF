function dA = plantDynamics(P, A, Q, betaPlant, Tinit)

    Aeff = max(A, P.AFloor);
    c = cCoefficient(P, betaPlant, Tinit);
    lb = lambda_bar(P, betaPlant);
    dA = lb*(-c*sqrt(Aeff) + P.eta*Q/sqrt(Aeff));
    
end