function p = PSI_setDefaultLESCParams(p)
    if ~isfield(p, 'lesc') || ~isstruct(p.lesc)
        p.lesc = struct();
    end
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'phase_model', 'synthetic_LESC');
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'sieve_pore_radius_px', [2.0, 2.0]);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'sem_grain_noise', 0.010);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'wrinkle_height_factor', 0.10);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'phase_smooth_sigma_px', 0.45);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'background_amp', 1.00);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'cell_amp', 0.95);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'rim_amp', 0.90);
    p.lesc = PSI_setFieldIfMissing(p.lesc, 'amp_noise_level', 0.005);
end
