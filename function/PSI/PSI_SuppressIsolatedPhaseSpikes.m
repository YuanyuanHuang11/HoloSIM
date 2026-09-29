function phi_out = PSI_SuppressIsolatedPhaseSpikes(phi, strength, thresh_mad, med_radius)
    % Replace only isolated impulse-like phase outliers with a local median.
    % This is deliberately conservative: connected pore edges are preserved,
    % while one- to few-pixel PSI hot spots are attenuated.
    if nargin < 2 || isempty(strength), strength = 0.8; end
    if nargin < 3 || isempty(thresh_mad), thresh_mad = 7.0; end
    if nargin < 4 || isempty(med_radius), med_radius = 1; end
    phi = double(phi);
    phi_out = phi;
    k = 2*max(1,round(med_radius)) + 1;
    try
        med = medfilt2(phi, [k k], 'symmetric');
    catch
        med = phi;
        return;
    end
    diffv = phi - med;
    finiteDiff = diffv(isfinite(diffv));
    if numel(finiteDiff) < 100
        return;
    end
    sigmaGlobal = 1.4826 * median(abs(finiteDiff - median(finiteDiff, 'omitnan')), 'omitnan');
    if ~isfinite(sigmaGlobal) || sigmaGlobal <= 0
        return;
    end
    spike = abs(diffv) > thresh_mad * sigmaGlobal;
    spike = spike & isfinite(phi) & isfinite(med);
    % Keep only isolated/small connected spike groups; do not process pore rims.
    try
        cc = bwconncomp(spike, 8);
        keep = false(size(spike));
        for ii = 1:cc.NumObjects
            if numel(cc.PixelIdxList{ii}) <= 3
                keep(cc.PixelIdxList{ii}) = true;
            end
        end
        spike = keep;
    catch
        neighborCount = conv2(double(spike), ones(3), 'same');
        spike = spike & (neighborCount <= 3);
    end
    phi_out(spike) = (1-strength) * phi(spike) + strength * med(spike);
end
