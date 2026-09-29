function PSI_ExportPublicationFigure(fig_handle, base_path, plot_style)
    % EMF is kept for vector-friendly plots only. Large raster image mosaics
    % are intentionally not sent through -dmeta/-painters because that is slow
    % and can trigger graphics-tree update errors in MATLAB.
    if isempty(findall(fig_handle, 'Type', 'image'))
        PSI_PoreExportEMF(fig_handle, base_path);
    end
    if (~isfield(plot_style, 'export_fig') || ~plot_style.export_fig) && ...
       (~isfield(plot_style, 'export_png') || ~plot_style.export_png) && ...
       (~isfield(plot_style, 'export_pdf') || ~plot_style.export_pdf)
        fprintf('    figure export skipped for %s.\n', base_path);
        return;
    end
    PSI_ApplyPublicationStyle_Sparse(fig_handle, plot_style);
    drawnow;

    fig_file = [base_path '.fig'];
    png_file = [base_path '.png'];
    pdf_file = [base_path '.pdf'];

    if isfield(plot_style, 'export_fig') && plot_style.export_fig
        try
            savefig(fig_handle, fig_file);
        catch
            saveas(fig_handle, fig_file);
        end
    end

    if isfield(plot_style, 'export_png') && plot_style.export_png
        try
            exportgraphics(fig_handle, png_file, ...
                'Resolution', plot_style.export_dpi, ...
                'BackgroundColor', 'white');
        catch
            print(fig_handle, png_file, '-dpng', sprintf('-r%d', plot_style.export_dpi));
        end
    end

    if isfield(plot_style, 'export_pdf') && plot_style.export_pdf
        try
            exportgraphics(fig_handle, pdf_file, ...
                'ContentType', 'vector', ...
                'BackgroundColor', 'white');
        catch
            set(fig_handle, 'PaperPositionMode', 'auto');
            print(fig_handle, pdf_file, '-dpdf', '-painters');
        end
    end
end
