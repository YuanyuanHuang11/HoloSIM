function OA_SaveStandaloneColorbarSmart(save_path, file_stem, cmap, clim_in, ticks, label_str, params)
    use_fig = isfield(params, 'plot') && isfield(params.plot, 'use_figure_for_colorbar') && params.plot.use_figure_for_colorbar;
    if use_fig
        try
            OA_SaveStandaloneColorbarArial(save_path, file_stem, cmap, clim_in, ticks, label_str, params);
            return;
        catch ME
            warning('Arial colorbar export failed (%s). Falling back to direct raster colorbar.', ME.message);
        end
    end
    cb = OA_MakeLabeledColorbar(cmap, clim_in, ticks, 1200, 420, label_str);
    imwrite(cb, fullfile(save_path, [file_stem '.png']));
    imwrite(cb, fullfile(save_path, [file_stem '.tif']));
end
