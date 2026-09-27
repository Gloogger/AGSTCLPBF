function [i, s, X, Y] = trackState(P, t)
    i = trackIndex(P, t);
    s = P.v*(t - (i-1)*P.tau);
    s = min(max(s, 0), P.L);
    
    if mod(i,2) == 1
        X = s;
    else
        X = P.L - s;
    end
    Y = (i-1)*P.hSP;
end