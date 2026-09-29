function PSI_ExportPublicationFigureFast(fig_handle, base_path, plot_style)
    PSI_ApplyPublicationStyle(fig_handle, plot_style);
    drawnow limitrate nocallbacks;

    [out_dir, ~, ~] = fileparts(base_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    png_file = [base_path '.png'];
    if isfield(plot_style, 'curve_export_dpi')
        dpi = plot_style.curve_export_dpi;
    elseif isfield(plot_style, 'export_dpi')
        dpi = plot_style.export_dpi;
    else
        dpi = 600;
    end

    set(fig_handle, 'Color', 'w', 'InvertHardcopy', 'off', 'Renderer', 'opengl');
    try
        print(fig_handle, png_file, '-dpng', '-opengl', sprintf('-r%d', dpi));
    catch ME
        warning('Fast print export failed: %s', ME.message);
        try
            frame = getframe(fig_handle);
            imwrite(frame.cdata, png_file);
        catch ME2
            warning('Fallback getframe export failed: %s', ME2.message);
        end
    end
end
