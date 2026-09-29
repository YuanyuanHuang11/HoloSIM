function PSI_overlayProfileGuideLine(ax, profile_line, img_size)
    hold(ax, 'on');
    if isfield(profile_line, 'row_index') && isfield(profile_line, 'x_index_range')
        xidx = profile_line.x_index_range;
        if isempty(xidx)
            xidx = 1:img_size(2);
        end
        yidx = profile_line.row_index;
        plot(ax, [min(xidx) max(xidx)], [yidx yidx], 'w--', ...
            'LineWidth', 1.1, 'HandleVisibility', 'off');
        plot(ax, [min(xidx) max(xidx)], [yidx yidx], 'k--', ...
            'LineWidth', 0.45, 'HandleVisibility', 'off');
    end
end
