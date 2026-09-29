function [cmin, cmax] = PSI_DeterminePhaseDisplayCLim(GT_phi, phase_WF, phase_SIM, params)
    mode = 'robust-reference';
    if isfield(params, 'display') && isfield(params.display, 'phase_clim_mode')
        mode = params.display.phase_clim_mode;
    end

    switch lower(mode)
        case 'manual'
            clim = params.display.phase_clim_manual;
            cmin = clim(1); cmax = clim(2);
        otherwise
            vals = [GT_phi(:); phase_WF(:); phase_SIM(:)];
            vals = vals(isfinite(vals));
            pct = [0.5 99.5];
            if isfield(params.display, 'phase_clim_percentile')
                pct = params.display.phase_clim_percentile;
            end
            cmin = prctile(vals, pct(1));
            cmax = prctile(vals, pct(2));
            if ~isfinite(cmin) || ~isfinite(cmax) || cmax <= cmin
                cmin = min(vals); cmax = max(vals);
            end
    end
end
