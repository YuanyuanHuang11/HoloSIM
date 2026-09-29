function Dsum = SIM_PostprocessSIMHologram(Dsum, params)
    if isfield(params, 'recon') && isfield(params.recon, 'holo_denoise_sigma_px') && params.recon.holo_denoise_sigma_px > 0
        Dsum = imgaussfilt(Dsum, params.recon.holo_denoise_sigma_px);
    end
    if isfield(params, 'recon') && isfield(params.recon, 'destripe_SIM_holograms') && params.recon.destripe_SIM_holograms
        if isfield(params.recon, 'bg_fit_mask')
            bg_mask = params.recon.bg_fit_mask;
        else
            bg_mask = true(size(Dsum));
        end
        % Dsum = RemoveColumnStripeBias(Dsum, bg_mask, params.recon.holo_destripe_smooth_px, params.recon.holo_destripe_strength);
    end
end
