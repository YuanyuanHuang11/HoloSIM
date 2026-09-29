function OA_SaveDirectOffaxisPanels(save_path, GT_phi, phase_WF, phase_alpha0_Y, phase_alpha90_X, phase_avg, phase_fused, clim_phase, phase_ticks, GT_ref, params)
    cmap = OA_GetPhaseColormap(params);
    names = {'GT_phase','WF_QPM_phase','alpha0_Yfreq_SIM_phase','alpha90_Xfreq_SIM_phase','average_fusion_phase','frequency_fusion_phase'};
    maps = {GT_phi, phase_WF, phase_alpha0_Y, phase_alpha90_X, phase_avg, phase_fused};
    for ii = 1:numel(maps)
        rgb = OA_ScalarToRGB(maps{ii}, clim_phase, cmap);
        imwrite(rgb, fullfile(save_path, [names{ii} '.png']));
        imwrite(rgb, fullfile(save_path, [names{ii} '.tif']));
    end

    % 2x3 montage without using MATLAB figure/print/exportgraphics.
    panel_px = 900;
    gap = 18;
    white = uint8(255 * ones(2*panel_px + gap, 3*panel_px + 2*gap, 3));
    for ii = 1:6
        rgb = imresize(OA_ScalarToRGB(maps{ii}, clim_phase, cmap), [panel_px panel_px], 'bicubic');
        rr = floor((ii-1)/3);
        cc = mod(ii-1,3);
        r0 = rr*(panel_px+gap)+1;
        c0 = cc*(panel_px+gap)+1;
        white(r0:r0+panel_px-1, c0:c0+panel_px-1, :) = rgb;
    end
    imwrite(white, fullfile(save_path, 'A_offaxis_SIM_QPM_full_comparison.png'));
    imwrite(white, fullfile(save_path, 'A_offaxis_SIM_QPM_full_comparison.tif'));

    % Standalone colorbar. Prefer MATLAB figure + Arial font for publication style;
    % fall back to direct raster text if graphics backend fails.
    OA_SaveStandaloneColorbarSmart(save_path, 'A_offaxis_SIM_QPM_phase_colorbar', ...
        cmap, clim_phase, phase_ticks, 'Phase (rad)', params);

    fid = fopen(fullfile(save_path, 'A_offaxis_SIM_QPM_direct_export_info.txt'), 'w');
    fprintf(fid, 'Direct imwrite export; no figure/print/exportgraphics was used.\n');
    fprintf(fid, 'Phase clim: [%.6g %.6g] rad\n', clim_phase(1), clim_phase(2));
    fprintf(fid, 'Off-axis filter SIM: to-DC = %.3g, ortho/away = %.3g.\n', params.recon.offaxis_multi_to_dc_SIM, params.recon.offaxis_multi_ortho_SIM);
    fprintf(fid, 'Phase unwrapping enabled = %d.\n', isfield(params.recon,'use_phase_unwrap') && params.recon.use_phase_unwrap);
    fprintf(fid, 'Phase ticks: ');
    fprintf(fid, '%.6g ', phase_ticks);
    fprintf(fid, '\nPanel order: GT, WF-QPM, alpha0-Yfreq, alpha90-Xfreq, average fusion, frequency fusion.\n');
    fprintf(fid, 'Direction convention: alpha0 carrier is on fx axis; usable off-axis bandwidth is mainly extended along fy, so alpha0 is Y-frequency enhanced.\n');
    fprintf(fid, 'Fusion weights: alpha90/X-enhanced result uses cos^2(theta) near fx axis; alpha0/Y-enhanced result uses sin^2(theta) near fy axis.\n');
    fclose(fid);
end
