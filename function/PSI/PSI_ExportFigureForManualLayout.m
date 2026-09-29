function PSI_ExportFigureForManualLayout(fig_handle, base_path, plot_style)
    PSI_PoreExportEMF(fig_handle, base_path);
    drawnow;
    if isfield(plot_style, 'individual_export_fig') && plot_style.individual_export_fig
        try
            savefig(fig_handle, [base_path '.fig']);
        catch
            saveas(fig_handle, [base_path '.fig']);
        end
    end
    if isfield(plot_style, 'individual_export_png') && plot_style.individual_export_png
        try
            exportgraphics(fig_handle, [base_path '.png'], 'Resolution', plot_style.export_dpi, 'BackgroundColor', 'white');
        catch
            print(fig_handle, [base_path '.png'], '-dpng', sprintf('-r%d', plot_style.export_dpi));
        end
    end
    if isfield(plot_style, 'individual_export_pdf') && plot_style.individual_export_pdf
        try
            exportgraphics(fig_handle, [base_path '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
        catch
            set(fig_handle, 'PaperPositionMode', 'auto');
            print(fig_handle, [base_path '.pdf'], '-dpdf', '-painters');
        end
    end
end
