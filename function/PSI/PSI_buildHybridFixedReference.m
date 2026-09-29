function I_ref = PSI_buildHybridFixedReference(I_phase4_norm, params)
    % Build a fixed SIM reference that is less smoothed than mean_fixed but
    % less stripe-sensitive than rms_fixed. Each PSI frame is normalized only
    % for reference estimation, not for final demodulation.
    stack = double(I_phase4_norm);
    for kk = 1:size(stack,3)
        stack(:,:,kk) = PSI_normalizeReferenceFrame(stack(:,:,kk));
    end

    I_mean = mean(stack, 3);
    I_std  = std(stack, 0, 3);
    if isfield(params, 'sim') && isfield(params.sim, 'hybrid_ref_std_weight')
        alpha = params.sim.hybrid_ref_std_weight;
    else
        alpha = 0.25;
    end
    I_ref = I_mean + alpha * I_std;
    I_ref = PSI_normalizeReferenceFrame(I_ref);

    if isfield(params, 'sim') && isfield(params.sim, 'hybrid_ref_smooth_px')
        sig = params.sim.hybrid_ref_smooth_px;
    else
        sig = 0;
    end
    if sig > 0
        try
            I_ref = imgaussfilt(I_ref, sig);
            I_ref = PSI_normalizeReferenceFrame(I_ref);
        catch
        end
    end
end
