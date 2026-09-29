function Iout = SIM_applyTheorySIMReadout(Iin,FR,S)
    % Known-operator theoretical SIM readout for two-point simulation.
    %
    % The film-plane hologram is first limited by an effective linear-SIM
    % support. If S.sim.theory_compensation = 'wiener', the reconstructed
    % transfer is modeled as H_eff^2/(H_eff^2 + beta), i.e. a bounded Wiener
    % compensation of the known SIM OTF. This preserves supported spatial
    % frequencies much better than applying the forward OTF H_eff alone.
    fc_det = 2*S.NA_SIM/S.SIM_lambda;                 % cycles/m
    f_illum = 1/(S.sim.illum_period_nm*1e-9);         % cycles/m
    fc_sim = fc_det + f_illum;                        % cycles/m

    switch lower(S.sim.theory_otf_shape)
        case 'hard'
            H = double(FR <= fc_sim);
        otherwise
            H = SIM_incoherentOTF(FR, fc_sim);
    end

    if isfield(S,'sim') && isfield(S.sim,'min_support')
        H(H < S.sim.min_support) = 0;
    end

    compMode = 'none';
    if isfield(S,'sim') && isfield(S.sim,'theory_compensation')
        compMode = lower(char(S.sim.theory_compensation));
    end

    switch compMode
        case 'none'
            T = H;
        case 'wiener'
            beta = 2e-3;
            if isfield(S,'sim') && isfield(S.sim,'wiener_beta')
                beta = S.sim.wiener_beta;
            end
            T = (H.^2) ./ (H.^2 + beta);
            T(H <= 0) = 0;
        case 'ideal_support'
            T = double(FR <= fc_sim);
        otherwise
            error('Unknown S.sim.theory_compensation: %s', compMode);
    end

    % Keep DC gain exactly one to avoid a global hologram offset change.
    [~,idx0] = min(FR(:));
    if T(idx0) ~= 0
        T = T ./ T(idx0);
    end

    Iout = real(ifft2(fft2(double(Iin)).*fftshift(T)));
end
