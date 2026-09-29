function PSI_ExportPublicationFigureFast_LSEC(fig_handle, base_path, plot_style)
    [out_dir, ~, ~] = fileparts(base_path);
    if ~isempty(out_dir) && ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    if isfield(plot_style, 'disable_matlab_figure_export') && plot_style.disable_matlab_figure_export
        warning('MATLAB figure export skipped for %s because disable_matlab_figure_export=true. Direct-raster exporters are used instead.', base_path);
        return;
    end

    png_file = [base_path '.png'];
    if isfield(plot_style, 'curve_export_dpi')
        dpi = plot_style.curve_export_dpi;
    elseif isfield(plot_style, 'export_dpi')
        dpi = plot_style.export_dpi;
    else
        dpi = 600;
    end

    % Do not let MATLAB graphics infrastructure warnings stop the pipeline.
    % Some MATLAB sessions fail in drawnow/print with ViewModel-related
    % warnings.  The safer raster exporters above are used for image panels;
    % this function remains for curve/profile figures only.
    try
        PSI_ApplyPublicationStyle(fig_handle, plot_style);
    catch ME
        warning('ApplyPublicationStyle skipped because MATLAB graphics infrastructure is unstable: %s', ME.message);
    end

    try
        set(fig_handle, 'Color', 'w', 'InvertHardcopy', 'off');
    catch
    end

    export_ok = false;

    % First attempt: software-friendly painters renderer.  It is slower for
    % dense images but more robust than OpenGL when the figure backend is
    % partially broken.
    try
        set(fig_handle, 'Renderer', 'painters');
        print(fig_handle, png_file, '-dpng', sprintf('-r%d', dpi));
        export_ok = true;
    catch ME1
        warning('Painters print export failed: %s', ME1.message);
    end

    % Second attempt: OpenGL print without an explicit drawnow call.
    if ~export_ok
        try
            set(fig_handle, 'Renderer', 'opengl');
            print(fig_handle, png_file, '-dpng', '-opengl', sprintf('-r%d', dpi));
            export_ok = true;
        catch ME2
            warning('OpenGL print export failed: %s', ME2.message);
        end
    end

    % Last fallback: saveas.  Avoid getframe/exportgraphics here because
    % they often call the same broken ViewModel infrastructure.
    if ~export_ok
        try
            saveas(fig_handle, png_file);
            export_ok = true;
        catch ME3
            warning('saveas fallback export failed: %s', ME3.message);
        end
    end

    if ~export_ok
        warning('Figure export skipped for %s. Direct-raster image panels should still be available.', base_path);
    end
end
