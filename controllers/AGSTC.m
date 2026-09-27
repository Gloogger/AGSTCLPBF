function [Q, Qraw, u] = AGSTC(P, A, t, QEnd, alpha, nu)
    Aeff = max(A, P.AFloor);
    sigma = A - P.Ar;
    Ti = initialTemperature(P, t, QEnd, P.etaCtrlNom);
    
    betaHat = P.AGSTC.betaHat;
    cHat = cCoefficient(P, betaHat, Ti);
    lambdaHat = lambda_bar(P, betaHat);
    ArDot = referenceAreaDerivative(P, t);
    
    u = -alpha*sigPower(sigma, 0.5) + nu;
    Qraw = cHat/P.etaCtrlNom*Aeff + sqrt(Aeff)/(P.etaCtrlNom*lambdaHat)*(ArDot + u);

    if P.AGSTC.useSaturation
        Q = min(max(Qraw, 0), P.Qsat);
    else
        Q = Qraw;
    end
end