function [clim_phase, phase_ticks] = PSI_computeSharedPhaseClimTicks(result)
    vals = [result.GT_phi(:); result.phase_QPM(:); result.phase_HoloSIM(:)];
    vals = vals(isfinite(vals));

    if isempty(vals)
        clim_phase = [0 1.5];
        phase_ticks = [0 0.5 1.0 1.5];
        return;
    end

    % Use robust percentiles to avoid a single noisy pixel setting the range,
    % but keep zero as the lower bound whenever all relevant values are near
    % or above zero.
    lo = prctile(vals, 0.2);
    hi = prctile(vals, 99.8);

    if lo > -0.05
        lo = 0;
    else
        lo = floor(lo * 10) / 10;
    end
    hi = ceil(hi * 10) / 10;

    if hi <= lo || ~isfinite(hi) || ~isfinite(lo)
        lo = 0;
        hi = ceil(max(vals) * 10) / 10;
        if hi <= 0 || ~isfinite(hi)
            hi = 1.5;
        end
    end

    clim_phase = [lo, hi];

    % Clean, complete tick set.  About 4-6 ticks are most readable in the
    % exported small colorbar.
    span = hi - lo;
    if span <= 1.2
        step = 0.25;
    elseif span <= 2.5
        step = 0.5;
    else
        step = 1.0;
    end
    first_tick = ceil(lo / step) * step;
    last_tick  = floor(hi / step) * step;
    phase_ticks = first_tick:step:last_tick;
    if isempty(phase_ticks) || abs(phase_ticks(1)-lo) > 1e-9
        phase_ticks = [lo, phase_ticks];
    end
    if abs(phase_ticks(end)-hi) > 1e-9
        phase_ticks = [phase_ticks, hi];
    end
    phase_ticks = unique(round(phase_ticks * 1e6) / 1e6, 'stable');
end
