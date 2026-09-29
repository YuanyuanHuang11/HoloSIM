function OA_PrintSiemensCalibrationInfo(GT)
    if ~isfield(GT, 'siemens')
        return;
    end

    Nlp = GT.siemens.num_line_pairs;
    fprintf('    -> Siemens star 标定信息：%d spokes，%d line pairs。\n', ...
        GT.siemens.num_spokes, Nlp);
    fprintf('       半径 r 处 full-pitch = 2*pi*r/%d；half-pitch = full-pitch/2。\n', Nlp);
    fprintf('       有效星靶半径 %.2f um；中心 %.0f nm 内不参与分辨率判读。\n', ...
        GT.siemens.star_radius_m*1e6, GT.siemens.inner_radius_m*1e9);

    fp_nm = GT.siemens.ring_fullpitch_nm(:);
    rr_um = GT.siemens.ring_radius_m(:) * 1e6;
    for ii = 1:numel(fp_nm)
        if GT.siemens.ring_radius_m(ii) > GT.siemens.inner_radius_m && ...
           GT.siemens.ring_radius_m(ii) < GT.siemens.star_radius_m
            fprintf('       full-pitch %6.1f nm <=> radius %6.3f um。\n', fp_nm(ii), rr_um(ii));
        end
    end
end
