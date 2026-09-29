function PSI_ExportIndividualPhasePanels(full_maps, names, titles, cmin, cmax, params, out_dir)
    fprintf('    exporting independent full-cell phase images to: %s\n', out_dir);
    for ii = 1:numel(names)
        base_full = fullfile(out_dir, sprintf('%02d_%s_fullCell', ii, names{ii}));
        PSI_ExportSinglePhaseImageOnly(full_maps{ii}, titles{ii}, base_full, cmin, cmax, params);
    end
end
