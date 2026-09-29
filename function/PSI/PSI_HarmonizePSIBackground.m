function D = PSI_HarmonizePSIBackground(D, bg_mask, strength)
    % Match the background DC level of the four SIM-reconstructed PSI frames.
    % This does not estimate different SIM operators; it only removes additive
    % frame-to-frame offsets that otherwise leak into the four-step phase.
    if nargin < 3 || isempty(strength)
        strength = 1.0;
    end
    if isempty(bg_mask) || ~isequal(size(bg_mask), size(D(:,:,1))) || nnz(bg_mask) < 100
        bg_mask = true(size(D(:,:,1)));
    end
    nFrames = size(D,3);
    medVals = nan(1,nFrames);
    for kk = 1:nFrames
        vals = D(:,:,kk);
        vals = vals(bg_mask & isfinite(vals));
        if ~isempty(vals)
            medVals(kk) = median(vals, 'omitnan');
        end
    end
    if any(~isfinite(medVals))
        return;
    end
    targetMed = median(medVals, 'omitnan');
    for kk = 1:nFrames
        D(:,:,kk) = D(:,:,kk) - strength * (medVals(kk) - targetMed);
    end
end
