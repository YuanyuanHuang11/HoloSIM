function [phase_flat, amplitude, object_wave] = PSI_DemodulatePhaseShift4(hologram4, params)
    % Enhanced four-step PSI demodulation for LESC phase-amplitude targets.
    % Key improvements:
    %   1) optional phase-frame balancing to reduce frame-to-frame intensity mismatch;
    %   2) no DCT unwrapping for LESC when phase range is safely below pi;
    %   3) robust quadratic background fitting using the synthetic outer-cell mask.

    I0   = double(hologram4(:,:,1));
    I90  = double(hologram4(:,:,2));
    I180 = double(hologram4(:,:,3));
    I270 = double(hologram4(:,:,4));
    [Nx, Ny] = size(I0);

    frames = cat(3, I0, I90, I180, I270);

    % Equalize residual global brightness differences between the four phase-shift frames.
    if isfield(params, 'recon') && isfield(params.recon, 'phase_frame_balance') && params.recon.phase_frame_balance
        if isfield(params.recon, 'bg_fit_mask') && isequal(size(params.recon.bg_fit_mask), [Nx, Ny]) && nnz(params.recon.bg_fit_mask) > 100
            balance_mask = params.recon.bg_fit_mask;
        else
            balance_mask = true(Nx, Ny);
        end
        med_vals = zeros(1,4);
        for kk = 1:4
            tmp = frames(:,:,kk);
            med_vals(kk) = median(tmp(balance_mask), 'omitnan');
        end
        target_med = median(med_vals(med_vals > 0));
        if ~isempty(target_med) && isfinite(target_med) && target_med > 0
            for kk = 1:4
                if med_vals(kk) > 0 && isfinite(med_vals(kk))
                    frames(:,:,kk) = frames(:,:,kk) * (target_med / med_vals(kk));
                end
            end
        end
    end

    I0   = frames(:,:,1);
    I90  = frames(:,:,2);
    I180 = frames(:,:,3);
    I270 = frames(:,:,4);

    % For I(delta)=|O+R*exp(i*delta)|^2, with delta=[0, pi/2, pi, 3pi/2]:
    % I0-I180       = 4*real(O*conj(R))
    % I90-I270      = 4*imag(O*conj(R))
    % Therefore the physically correct complex carrier is
    % complex_carrier = (I0-I180) + i*(I90-I270).
    % The opposite sign gives the conjugated object wave and can invert the
    % reconstructed phase for positive-phase LESC targets.
    complex_carrier = (I0 - I180) + 1i * (I90 - I270);

    if SP_ShouldApplyComplexSparse(params)
        complex_carrier = SP_SparseComplexCarrierRefine(complex_carrier, params);
    end

    [x, y] = meshgrid((-Ny/2:Ny/2-1) * params.dx, (-Nx/2:Nx/2-1) * params.dy);
    ref_phase = 2*pi*params.fx_ref*(x*cos(params.alpha) + y*sin(params.alpha));
    object_wave = complex_carrier .* exp(1i * ref_phase);

    amplitude = abs(object_wave);
    if max(amplitude(:)) > 0
        amplitude = amplitude / max(amplitude(:));
    end

    phase_wrapped = angle(object_wave);

    % LESC phase range in the synthetic target is below pi, so using wrapped
    % phase directly avoids DCT unwrapping ramps and small-pore smearing.
    use_unwrap = false;
    if isfield(params, 'recon') && isfield(params.recon, 'use_unwrap')
        use_unwrap = params.recon.use_unwrap;
    end

    if use_unwrap
        if isfield(params, 'lesc') || isfield(params, 'siemens')
            unwrap_mask = true(size(phase_wrapped));
        else
            amp_norm = amplitude / max(amplitude(:) + eps);
            thresh = graythresh(amp_norm);
            unwrap_mask = amp_norm > thresh;
            if nnz(unwrap_mask) < 100
                unwrap_mask = true(size(amp_norm));
            end
        end
        phase_est = PSI_unwrap_phase_2D_masked(phase_wrapped, unwrap_mask);
    else
        phase_est = phase_wrapped;
    end

    [Ny_dim, Nx_dim] = size(phase_est);
    [X_grid, Y_grid] = meshgrid(1:Nx_dim, 1:Ny_dim);

    bg_mask = PSI_GetReconstructionBackgroundMask(params, [Ny_dim, Nx_dim]);
    Phase_background_surf = PSI_FitQuadraticBackgroundRobust(phase_est, bg_mask, X_grid, Y_grid, params);
    phase_flat = phase_est - Phase_background_surf;
    phase_flat = phase_flat - mean(phase_flat(bg_mask), 'omitnan');

    % Clean only the external background. Do not force pores inside the cell to
    % zero, otherwise pore recovery would be artificially improved.
    if isfield(params, 'recon') && isfield(params.recon, 'set_outer_background_to_zero') && params.recon.set_outer_background_to_zero
        if isfield(params.recon, 'mask_cell') && isequal(size(params.recon.mask_cell), size(phase_flat))
            outer_bg_mask = PSI_GetOuterBackgroundOnlyMask(params.recon.mask_cell);
            phase_flat(outer_bg_mask) = 0;
        end
    end
end
