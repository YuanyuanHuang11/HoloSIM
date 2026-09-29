function OA_SaveSiemensTwoToneGT(save_path, GT_phi, GT_ref, params)
    dark = params.plot.siemens_dark_color;
    bright = params.plot.siemens_bright_color;
    phase_map = double(GT_phi);
    lo = 0;
    if isfield(GT_ref, 'siemens') && isfield(GT_ref.siemens, 'phase_step_rad')
        hi = GT_ref.siemens.phase_step_rad;
    else
        hi = max(phase_map(:));
    end
    if hi <= lo, hi = max(phase_map(:)); end

    % Use the same phase display range for the two-tone GT preview and its colorbar.
    if isfield(params.plot, 'use_fixed_phase_clim') && params.plot.use_fixed_phase_clim
        cb_clim = params.plot.fixed_phase_clim;
        ticks = params.plot.fixed_phase_ticks;
    else
        cb_clim = [lo hi];
        ticks = unique([lo, 0.5*hi, hi]);
    end

    t = (phase_map - cb_clim(1)) / max(cb_clim(2) - cb_clim(1), eps);
    t = min(max(t, 0), 1);

    rgb = zeros([size(t), 3], 'uint8');
    for kk = 1:3
        channel = dark(kk) * (1 - t) + bright(kk) * t;
        rgb(:,:,kk) = uint8(255 * channel);
    end
    imwrite(rgb, fullfile(save_path, 'S_Siemens_star_twoTone_GT.png'));
    imwrite(rgb, fullfile(save_path, 'S_Siemens_star_twoTone_GT.tif'));

    cmap = zeros(256,3);
    for ii = 1:256
        a = (ii-1)/255;
        cmap(ii,:) = dark*(1-a) + bright*a;
    end
    OA_SaveStandaloneColorbarSmart(save_path, 'S_Siemens_star_twoTone_colorbar', ...
        cmap, cb_clim, ticks, 'Phase (rad)', params);

    fid = fopen(fullfile(save_path, 'S_Siemens_star_twoTone_colorbar_info.txt'), 'w');
    fprintf(fid, 'Two-tone Siemens phase colorbar.\n');
    fprintf(fid, 'Color range: %.6g to %.6g rad.\n', cb_clim(1), cb_clim(2));
    fprintf(fid, 'Ticks: '); fprintf(fid, '%.6g ', ticks); fprintf(fid, '\n');
    fclose(fid);
end
