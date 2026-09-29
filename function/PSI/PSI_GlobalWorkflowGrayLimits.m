function clim = PSI_GlobalWorkflowGrayLimits(img_cell, prc)
    vals = [];
    for kk = 1:numel(img_cell)
        tmp = double(img_cell{kk});
        tmp = tmp(isfinite(tmp));
        vals = [vals; tmp(:)]; %#ok<AGROW>
    end
    if isempty(vals)
        clim = [0 1];
        return;
    end
    clim = [prctile(vals, prc(1)), prctile(vals, prc(2))];
    if ~all(isfinite(clim)) || clim(2) <= clim(1)
        clim = [min(vals), max(vals)];
    end
    if ~all(isfinite(clim)) || clim(2) <= clim(1)
        clim = [0 1];
    end
end
