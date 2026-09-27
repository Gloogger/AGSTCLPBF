function Q = proportionalControl(P, A, t, QEnd, betaCtrl, gainScale)
    Aeff = max(A, P.AFloor);
    z = A - P.Ar;
    Ti = initialTemperature(P, t, QEnd, P.etaCtrlNom);
    c = cCoefficient(P, betaCtrl, Ti);
    lb = lambda_bar(P, betaCtrl);
    Q = c/P.etaCtrlNom*A - gainScale*P.Kp/(P.etaCtrlNom*lb)*z*sqrt(Aeff);
end