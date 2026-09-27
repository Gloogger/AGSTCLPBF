function Ti = initialTemperature(P, t, QEnd, etaForThermalHistory)
    [i, ~, X, Y] = trackState(P, t);
    Ti = P.Ta;
    
    for j = 1:(i-1)
        Qj = QEnd(j);
        if isnan(Qj) || Qj == 0
            continue;
        end
    
        if mod(j,2) == 1
            direction = 1;
            xEnd = P.L;
        else
            direction = -1;
            xEnd = 0;
        end
    
        Xj = xEnd + direction*(P.v*(t - j*P.tau) + P.hSP*(i - j));
        Yj = (j-1)*P.hSP;
        Zj = 0; Z = 0;
    
        Rj = sqrt((X - Xj)^2 + (Y - Yj)^2 + (Z - Zj)^2);
        Rj = max(Rj, 1e-12);
        wj = -abs(X - Xj);
    
        Ti = Ti + etaForThermalHistory *Qj/(2*pi*P.k*Rj)*exp(-P.v*(wj + Rj)/(2*P.a));
    end
end