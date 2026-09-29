function [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,OTFo_recon] = SIM_makeSIMRawStackDownsampled(I_in, params)
    w = params.N;
    pixel_size_nm = params.dx * 1e9;
    lambda_nm = params.SIM_lambda * 1e9;

    if isfield(params, 'sim') && isfield(params.sim, 'illum_period_nm')
        illum_period_nm = params.sim.illum_period_nm;
    else
        illum_period_nm = 250;
    end

    if isfield(params, 'sim') && isfield(params.sim, 'snr')
        SNR = params.sim.snr;
    else
        SNR = 100;
    end
    NoiseLevel = 100 / SNR;

    if isfield(params, 'sim') && isfield(params.sim, 'mod_factor')
        ModFac = params.sim.mod_factor;
    else
        ModFac = 0.8;
    end

    [PSFo,~] = PsfOtf(w, params.NA_SIM);
    fc = pixel_size_nm * (2 * params.NA_SIM * w) / lambda_nm;
    OTFo = OTF(w, w, 0, 0, fc);

    DIo = double(I_in);
    k2 = w * pixel_size_nm / illum_period_nm;

    [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,~,~] = ...
        SIMimagesF(k2, DIo, PSFo, OTFo, ModFac, NoiseLevel, 0);

    if isfield(params, 'sim') && isfield(params.sim, 'camera_downsample_scale')
        scale = params.sim.camera_downsample_scale;
    else
        scale = 0.5;
    end

    % Camera pixel integration replaces bicubic interpolation. This models
    % finite camera-pixel area integration and reduces interpolation artifacts
    % for high-frequency Siemens-star structures.
    S1a = SIM_cameraPixelIntegrateDownsample(S1a, scale);
    S2a = SIM_cameraPixelIntegrateDownsample(S2a, scale);
    S3a = SIM_cameraPixelIntegrateDownsample(S3a, scale);
    S1b = SIM_cameraPixelIntegrateDownsample(S1b, scale);
    S2b = SIM_cameraPixelIntegrateDownsample(S2b, scale);
    S3b = SIM_cameraPixelIntegrateDownsample(S3b, scale);
    S1c = SIM_cameraPixelIntegrateDownsample(S1c, scale);
    S2c = SIM_cameraPixelIntegrateDownsample(S2c, scale);
    S3c = SIM_cameraPixelIntegrateDownsample(S3c, scale);

    wr = size(S1a, 1);
    OTFo_recon = OTF(wr, wr, 0, 0, fc);
end
