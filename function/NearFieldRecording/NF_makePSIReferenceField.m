function ref = NF_makePSIReferenceField(x, y, S, k)
    % Reference field for four-step PSI.
    % Default is pure on-axis PSI: no lateral carrier and only temporal phase shift.
    % If S.ref.use_lateral_carrier is set true and S.ref.lateral_frequency > 0,
    % theta_deg controls the in-plane carrier direction. For the present pure-PSI
    % simulations, lateral_frequency = 0, so theta = 0 and 180 deg are identical.
    delta = S.phase_shifts(k);
    theta_deg = 0;
    f_ref = 0;
    useCarrier = false;

    if isfield(S,'ref')
        if isfield(S.ref,'theta_deg'), theta_deg = S.ref.theta_deg; end
        if isfield(S.ref,'lateral_frequency'), f_ref = S.ref.lateral_frequency; end
        if isfield(S.ref,'use_lateral_carrier'), useCarrier = logical(S.ref.use_lateral_carrier); end
    end

    if ~useCarrier
        f_ref = 0;
    end

    lateralPhase = 2*pi*f_ref*(x*cosd(theta_deg) + y*sind(theta_deg));
    ref = exp(1i*(lateralPhase + delta));
end
