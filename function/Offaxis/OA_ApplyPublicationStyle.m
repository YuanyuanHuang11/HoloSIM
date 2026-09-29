function OA_ApplyPublicationStyle(fig_handle, plot_style)
    set(fig_handle, 'Color', 'w', 'InvertHardcopy', 'off');

    obj_font = findall(fig_handle, '-property', 'FontName');
    for kk = 1:numel(obj_font)
        try
            set(obj_font(kk), 'FontName', plot_style.font_name);
        catch
        end
    end

    axes_list = findall(fig_handle, 'Type', 'axes');
    for kk = 1:numel(axes_list)
        try
            set(axes_list(kk), ...
                'Color', 'w', ...
                'FontName', plot_style.font_name, ...
                'FontSize', plot_style.font_size_axis, ...
                'LineWidth', plot_style.axis_line_width, ...
                'XColor', 'k', ...
                'YColor', 'k', ...
                'Box', 'on', ...
                'Layer', 'top');
            axes_list(kk).GridAlpha = plot_style.grid_alpha;
        catch
        end
    end

    legend_list = findall(fig_handle, 'Type', 'legend');
    for kk = 1:numel(legend_list)
        try
            PSI_FormatLegend_OA(legend_list(kk), plot_style);
        catch
        end
    end
end
