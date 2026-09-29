function PSI_ExportPublicationFigure_Multi(fig_handle, base_path, plot_style, pdf_content_type)
    %#ok<INUSD>
    % Backwards-compatible wrapper. To avoid MATLAB hanging in
    % exportgraphics()/waitForFigureReady, all routine exports are routed to
    % the fast PNG path. Set plot_style.export_fig/export_pdf manually and
    % call custom export code only when absolutely required.
    PSI_ExportPublicationFigureFast(fig_handle, base_path, plot_style);
end
