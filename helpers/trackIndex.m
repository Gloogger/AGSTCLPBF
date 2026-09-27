function i = trackIndex(P, t)
    i = floor(t/P.tau) + 1;
    i = min(max(i, 1), P.nTracks);
end