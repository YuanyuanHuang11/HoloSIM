function PSI_overlayProfileGuideLineOnCrop(ax, profile_line, ix, iy)
    hold(ax, 'on');
    if ~isfield(profile_line, 'row_index') || ~isfield(profile_line, 'x_index_range')
        return;
    end
    row = profile_line.row_index;
    if row < min(iy) || row > max(iy)
        return;
    end
    yLocal = row - min(iy) + 1;
    xLineGlobal = profile_line.x_index_range;
    xLineGlobal = xLineGlobal(xLineGlobal >= min(ix) & xLineGlobal <= max(ix));
    if isempty(xLineGlobal)
        xLineGlobal = ix;
    end
    xLocal = [min(xLineGlobal) max(xLineGlobal)] - min(ix) + 1;
    plot(ax, xLocal, [yLocal yLocal], 'w--', 'LineWidth', 1.1, 'HandleVisibility', 'off');
    plot(ax, xLocal, [yLocal yLocal], 'k--', 'LineWidth', 0.45, 'HandleVisibility', 'off');
end
