function [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,OTFo_recon] = SIM_makeSIMRawStackDownsampled_Star(I_in, params)
    w = params.N;
    pixel_size_nm = params.dx * 1e9;
    lambda_nm = params.SIM_lambda * 1e9;
    illum_period_nm = params.sim.illum_period_nm;
    SNR = params.sim.snr;
    NoiseLevel = 100 / SNR;

    [PSFo,~] = PsfOtf(w, params.NA_SIM);
    fc = pixel_size_nm * (2 * params.NA_SIM * w) / lambda_nm;
    OTFo = OTF(w, w, 0, 0, fc);

    DIo = double(I_in);
    k2 = w * pixel_size_nm / illum_period_nm;
    ModFac = 0.8;
    [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,~,~] = SIMimagesF(k2,DIo,PSFo,OTFo,ModFac,NoiseLevel,0);

    scale = params.sim.camera_downsample_scale;
    S1a = SIM_cameraPixelIntegrateDownsample_Star(S1a,scale);
    S2a = SIM_cameraPixelIntegrateDownsample_Star(S2a,scale);
    S3a = SIM_cameraPixelIntegrateDownsample_Star(S3a,scale);
    S1b = SIM_cameraPixelIntegrateDownsample_Star(S1b,scale);
    S2b = SIM_cameraPixelIntegrateDownsample_Star(S2b,scale);
    S3b = SIM_cameraPixelIntegrateDownsample_Star(S3b,scale);
    S1c = SIM_cameraPixelIntegrateDownsample_Star(S1c,scale);
    S2c = SIM_cameraPixelIntegrateDownsample_Star(S2c,scale);
    S3c = SIM_cameraPixelIntegrateDownsample_Star(S3c,scale);

    wr = size(S1a,1);
    OTFo_recon = OTF(wr, wr, 0, 0, fc);
end
