function PSI_ExportWorkflowFigure(fig_handle, base_path, plot_style, sparse_style)
    PSI_PoreExportEMF(fig_handle, base_path);
    drawnow;
    do_png = true;
    do_pdf = false;
    do_fig = false;
    if isfield(sparse_style, 'workflow_export_png'), do_png = sparse_style.workflow_export_png; end
    if isfield(sparse_style, 'workflow_export_pdf'), do_pdf = sparse_style.workflow_export_pdf; end
    if isfield(sparse_style, 'workflow_export_fig'), do_fig = sparse_style.workflow_export_fig; end

    if do_fig
        try
            savefig(fig_handle, [base_path '.fig']);
        catch
            saveas(fig_handle, [base_path '.fig']);
        end
    end
    if do_png
        try
            exportgraphics(fig_handle, [base_path '.png'], 'Resolution', plot_style.export_dpi, 'BackgroundColor', 'white');
        catch
            print(fig_handle, [base_path '.png'], '-dpng', sprintf('-r%d', plot_style.export_dpi));
        end
    end
    if do_pdf
        try
            exportgraphics(fig_handle, [base_path '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
        catch
            set(fig_handle, 'PaperPositionMode', 'auto');
            print(fig_handle, [base_path '.pdf'], '-dpdf', '-painters');
        end
    end
end
