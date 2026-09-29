function [I,failed,msg] = SIM_realSIMReadoutFixedParams(Iin,S,simParams,doNormalize)
    if nargin < 4, doNormalize = false; end
    Iin = double(Iin);
    if doNormalize
        Iin = Iin - min(Iin(:));
        if max(Iin(:)) > 0, Iin = Iin/max(Iin(:)); end
    end
    failed = false;
    msg = "";
    try
        I = SIM_ReconstructSIMHologramFixedParams(Iin,S,simParams);
        if ~isequal(size(I),[S.N S.N])
            I = imresize(I,[S.N S.N],'bicubic');
        end
        if any(~isfinite(I(:)))
            failed = true;
            msg = "non-finite fixed-param SIM output";
        end
    catch ME
        failed = true;
        msg = string(ME.message);
        I = nan(S.N,S.N);
    end
    if isfield(S,'recon') && isfield(S.recon,'holo_denoise_sigma_px') && S.recon.holo_denoise_sigma_px>0 && ~failed
        I = imgaussfilt(I,S.recon.holo_denoise_sigma_px);
    end
end
