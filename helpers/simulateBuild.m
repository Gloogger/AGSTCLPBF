function S = simulateBuild(P, betaPlant, controllerName, Qff)
    if nargin < 4
        Qff = [];
    end

    t = 0:P.dt:P.tEnd;
    N = numel(t);
    A = zeros(1,N);          % true plant area
    A_noisy = zeros(1,N);    % noisy measured area
    A_ctrl = zeros(1,N);     % area signal actually used by controller
    Q = zeros(1,N);
    Qraw = nan(1,N);
    Tinit = zeros(1,N);
    betaTrace = zeros(1,N);
    agstcAlpha = nan(1,N);
    agstcNu = nan(1,N);
    agstcU = nan(1,N);
    A(1) = P.A0;
    areaNoise = makeAreaNoise(P, N);

    if controllerName == "AGSTC"
        agstcAlpha(1) = P.AGSTC.kappa0;
        agstcNu(1) = P.AGSTC.nu0;
    end

    QEnd = nan(1, P.nTracks);

    for n = 1:N
        tn = t(n);

        if n > 1
            prevTrack = trackIndex(P, t(n-1));
            thisTrack = trackIndex(P, tn);
            if thisTrack > prevTrack
                QEnd(prevTrack) = Q(n-1);
            end
        end

        Tinit(n) = initialTemperature(P, tn, QEnd, P.etaPlantTrue);
        betaTrace(n) = betaAt(betaPlant, tn);

        A_noisy(n) = A(n) + areaNoise(n);
        if P.areaNoise.clipNonnegative
            A_noisy(n) = max(0, A_noisy(n));
        end

        if P.areaNoise.useForControl
            A_ctrl(n) = A_noisy(n);
        else
            A_ctrl(n) = A(n);
        end

        switch controllerName
            case "prop_feedback"
                Q(n) = proportionalControl(P, A_ctrl(n), tn, QEnd, P.betaNom, 1.0);

            case "prop_feedback_fig67"
                if tn < P.tau
                    gainScale = 1.0;
                else
                    gainScale = P.fig67FeedbackGainScaleAfterTrack1;
                end
                Q(n) = proportionalControl(P, A_ctrl(n), tn, QEnd, P.betaNom, gainScale);

            case "feedforward"
                if isempty(Qff)
                    error('The feedforward controller requires Qff.t and Qff.Q.');
                end
                Q(n) = interp1(Qff.t, Qff.Q, tn, 'linear', 'extrap');

            case "constant"
                Q(n) = constantPower(P, P.betaNom);

            case "smc"
                Q(n) = robustSMC(P, A_ctrl(n), tn, QEnd);

            case "smc_sat"
                Q(n) = min(robustSMC(P, A_ctrl(n), tn, QEnd), P.Qsat);

            case "AGSTC"
                [Q(n), Qraw(n), agstcU(n)] = AGSTC(P, A_ctrl(n), tn, QEnd, ...
                    agstcAlpha(n), agstcNu(n));

            otherwise
                error('Unknown controller: %s', controllerName);
        end

        Q(n) = max(Q(n), 0);

        if n < N
            dA = plantDynamics(P, A(n), Q(n), betaTrace(n), Tinit(n));
            A(n+1) = max(0, A(n) + P.dt*dA);

            if controllerName == "AGSTC"
                [agstcAlpha(n+1), agstcNu(n+1)] = updateAGSTCState(P, ...
                    A_ctrl(n), Qraw(n), agstcAlpha(n), agstcNu(n));
            end
        end
    end

    S.t = t;
    S.A = A;                  % true plant area
    S.A_noisy = A_noisy;      % noisy measured area
    S.A_control = A_ctrl;     % signal used by feedback controllers
    S.areaNoise = areaNoise;  % additive noise realization in mm^2
    S.Q = Q;
    S.Qraw = Qraw;
    S.Tinit = Tinit;
    S.beta = betaTrace;
    S.AGSTC.alpha = agstcAlpha;
    S.AGSTC.nu = agstcNu;
    S.AGSTC.u = agstcU;
end