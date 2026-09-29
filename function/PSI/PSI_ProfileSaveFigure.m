function PSI_ProfileSaveFigure(fig,out,stem)
    % Avoid forced drawnow on complex image/colorbar figures; it can trigger
    % MarkedDirty/graphics-tree update errors.
    try, savefig(fig,fullfile(out,[stem '.fig'])); catch, end
    try
        exportgraphics(fig,fullfile(out,[stem '.png']),'Resolution',300,'BackgroundColor','white');
    catch
        print(fig,fullfile(out,[stem '.png']),'-dpng','-r300');
    end
    % EMF only for the actual profile curves. Raster map panels stay PNG.
    if strcmp(stem,'Profile_all_methods') || strcmp(stem,'Profile_paired_methods')
        PSI_PoreExportEMF(fig,fullfile(out,stem));
    end
end
