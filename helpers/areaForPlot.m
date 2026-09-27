function Aplot = areaForPlot(P, S)
    plotSignal = 'true';
    if isfield(P, 'areaNoise') && isfield(P.areaNoise, 'plotSignal')
        plotSignal = char(lower(string(P.areaNoise.plotSignal)));
    end
    
    switch plotSignal
        case {'true', 'clean', 'plant', 'a'}
            Aplot = S.A;
        case {'noisy', 'measured', 'a_noisy'}
            if isfield(S, 'A_noisy')
                Aplot = S.A_noisy;
            else
                Aplot = S.A;
            end
        case {'control', 'controller', 'ctrl', 'a_control'}
            if isfield(S, 'A_control')
                Aplot = S.A_control;
            else
                Aplot = S.A;
            end
        otherwise
            error('Unknown P.areaNoise.plotSignal: %s. Use "true", "noisy", or "control".', plotSignal);
    end
end