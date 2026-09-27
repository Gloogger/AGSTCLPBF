function Qc = constantPower(P, betaCtrl)
    cc = cCoefficient(P, betaCtrl, P.Ta);
    Qc = cc/P.etaCtrlNom*P.Ar;
end