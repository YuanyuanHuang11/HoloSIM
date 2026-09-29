function [I, failed, msg] = SIM_realSIMReadoutFixedParams_LSEC(Iin, params, simParams, doNormalize)
    if nargin < 4
        doNormalize = false;
    end

    Iin = double(Iin);
    if doNormalize
        Iin = Iin - min(Iin(:));
        if max(Iin(:)) > 0
            Iin = Iin / max(Iin(:));
        end
    end

    failed = false;
    msg = "";
    try
        I = SIM_ReconstructSIMHologramFixedParams_LSEC(Iin, params, simParams);
        if ~isequal(size(I), [params.N params.N])
            % This fallback should rarely be used; it is only to keep the
            % sweep robust if external SIM helper functions return a slightly
            % different array size.
            I = imresize(I, [params.N params.N], 'bicubic');
        end
        if any(~isfinite(I(:)))
            failed = true;
            msg = "non-finite fixed-parameter SIM output";
        end
    catch ME
        failed = true;
        msg = string(ME.message);
        I = nan(params.N, params.N);
    end

    if isfield(params, 'recon') && isfield(params.recon, 'holo_denoise_sigma_px') && ...
            params.recon.holo_denoise_sigma_px > 0 && ~failed
        I = imgaussfilt(I, params.recon.holo_denoise_sigma_px);
    end
end
