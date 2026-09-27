function [alphaNext, nuNext] = updateAGSTCState(P, A, Qraw, alpha, nu)
    C = P.AGSTC;
    sigma = A - P.Ar;
    
    betaST = 2*C.epsilonST*alpha;
    nuDot = -0.5*betaST*sign(sigma);
    
    if C.useSaturation && C.useAntiWindup
        if (Qraw > P.Qsat && nuDot > 0) || (Qraw < 0 && nuDot < 0)
            nuDot = 0;
        end
    end
    
    if alpha <= C.kappaMin
        alphaDot = C.etaMin;
    elseif abs(sigma) > C.varpi
        alphaDot = C.rhoUp;
    else
        alphaDot = -C.rhoDown;
    end
    
    alphaNext = alpha + P.dt*alphaDot;
    alphaNext = min(max(alphaNext, C.kappaMin), C.kappaMax);
    nuNext = nu + P.dt*nuDot;
end