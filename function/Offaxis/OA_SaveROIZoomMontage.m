function OA_SaveROIZoomMontage(save_path, maps, names, roi, clim_phase, cmap, params)
    panel_px = params.plot.direct_panel_px;
    gap = params.plot.direct_gap_px;
    ncol = 3; nrow = 2;
    canvas = uint8(255 * ones(nrow*panel_px + (nrow-1)*gap, ncol*panel_px + (ncol-1)*gap, 3));
    for ii = 1:numel(maps)
        crop = maps{ii}(roi.r1:roi.r2, roi.c1:roi.c2);
        rgb = OA_ScalarToRGB(crop, clim_phase, cmap);
        rgb = imresize(rgb, [panel_px panel_px], 'nearest');
        rr = floor((ii-1)/ncol); cc = mod(ii-1,ncol);
        r0 = rr*(panel_px+gap)+1; c0 = cc*(panel_px+gap)+1;
        canvas(r0:r0+panel_px-1, c0:c0+panel_px-1, :) = rgb;
    end
    imwrite(canvas, fullfile(save_path, sprintf('D_ROI_zoom_fullpitch_%dnm.png', round(roi.target_fullpitch_nm))));
    imwrite(canvas, fullfile(save_path, sprintf('D_ROI_zoom_fullpitch_%dnm.tif', round(roi.target_fullpitch_nm))));

    fid = fopen(fullfile(save_path, sprintf('D_ROI_zoom_fullpitch_%dnm_info.txt', round(roi.target_fullpitch_nm))), 'w');
    fprintf(fid, 'ROI zoom comparison.\n');
    fprintf(fid, 'Panel order: '); fprintf(fid, '%s; ', names{:}); fprintf(fid, '\n');
    fprintf(fid, 'ROI target full-pitch %.3f nm at theta %.3f deg.\n', roi.target_fullpitch_nm, roi.theta_deg);
    fprintf(fid, 'Rows [%d %d], cols [%d %d].\n', roi.r1, roi.r2, roi.c1, roi.c2);
    fprintf(fid, 'Phase clim [%.6g %.6g] rad.\n', clim_phase(1), clim_phase(2));
    fclose(fid);
end
