function Q = robustSMC(P, A, t, QEnd)
    Aeff = max(A, P.AFloor);
    z = A - P.Ar;
    sigma = z;
    Ti = initialTemperature(P, t, QEnd, P.etaCtrlNom);
    
    betaMin = P.betaNom - P.deltaBeta;
    betaMax = P.betaNom + P.deltaBeta;
    
    cMin = cCoefficient(P, betaMin, Ti);
    cMax = cCoefficient(P, betaMax, Ti);
    cMean = 0.5*(cMax + cMin);
    deltaC = 0.5*(cMax - cMin);
    
    lbMin = lambda_bar(P, betaMax); 
    act = tanh(sigma/P.epsilonA);
    
    Q = (cMean - deltaC*act)/P.etaCtrlNom*A ...
        - sqrt(Aeff)/(P.etaCtrlNom*lbMin)*(P.gamma/sqrt(2) + P.gammaTilde)*act;
end