function roi = OA_ComputeSiemensROI(GT, params, target_fp_nm, theta_deg, roi_size_px)
    Nlp = GT.siemens.num_line_pairs;
    radius_m = target_fp_nm * 1e-9 * Nlp / (2*pi);
    cx = params.N/2 + 1 + (radius_m / params.dx) * cosd(theta_deg);
    cy = params.N/2 + 1 + (radius_m / params.dy) * sind(theta_deg);
    half = floor(roi_size_px/2);
    c1 = max(1, round(cx) - half); c2 = min(params.N, round(cx) + half - 1);
    r1 = max(1, round(cy) - half); r2 = min(params.N, round(cy) + half - 1);
    roi = struct('r1',r1,'r2',r2,'c1',c1,'c2',c2,'cx',cx,'cy',cy,'radius_m',radius_m, ...
                 'target_fullpitch_nm',target_fp_nm,'theta_deg',theta_deg);
end
