function phi = PSI_subtractBackground(phi, bgMask)
    if nargin < 2 || isempty(bgMask) || nnz(bgMask) < 100
        phi = phi - median(phi(:), 'omitnan');
    else
        phi = phi - median(phi(bgMask), 'omitnan');
    end
end
