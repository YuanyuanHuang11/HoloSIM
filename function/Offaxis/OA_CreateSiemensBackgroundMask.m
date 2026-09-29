function bg_mask = OA_CreateSiemensBackgroundMask(GT, params)
    if isfield(GT, 'r') && isfield(GT, 'siemens')
        margin_m = params.recon.bg_margin_px * params.dx;
        bg_mask = GT.r > (GT.siemens.star_radius_m + margin_m);
    else
        bg_mask = false(params.N, params.N);
        m = max(20, params.recon.bg_margin_px);
        bg_mask(1:m,:) = true; bg_mask(end-m+1:end,:) = true;
        bg_mask(:,1:m) = true; bg_mask(:,end-m+1:end) = true;
    end
end
