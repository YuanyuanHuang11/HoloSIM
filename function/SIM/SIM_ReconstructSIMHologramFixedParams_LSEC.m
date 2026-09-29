function Dsum = SIM_ReconstructSIMHologramFixedParams_LSEC(I_in, params, simParams)
    % Reconstruct one hologram using fixed SIM parameters estimated from a
    % reference hologram. This keeps the PSI operator consistent across the
    % four phase shifts.
    [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,OTFo_recon] = SIM_makeSIMRawStackDownsampled(I_in, params);

    [fAo,fAp,fAm,~] = PCMseparateF(S1a,S2a,S3a,OTFo_recon);
    [fBo,fBp,fBm,~] = PCMseparateF(S1b,S2b,S3b,OTFo_recon);
    [fCo,fCp,fCm,~] = PCMseparateF(S1c,S2c,S3c,OTFo_recon);

    kA = simParams.kA;
    kB = simParams.kB;
    kC = simParams.kC;
    OBJparaA = simParams.OBJparaA;

    [fAof,fApf,fAmf,~,~,~,~,~] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
    [fBof,fBpf,fBmf,~,~,~,~,~] = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
    [fCof,fCpf,fCmf,~,~,~,~,~] = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);

    try
        [Fsum,~,~] = MergingHeptaletsF(fAof,fApf,fAmf, ...
                                       fBof,fBpf,fBmf, ...
                                       fCof,fCpf,fCmf, ...
                                       simParams.Ma,simParams.Mb,simParams.Mc, ...
                                       1,1,1, 1,1,1, 1,1,1, ...
                                       kA,kB,kC,OBJparaA,simParams.OTFo_double);
    catch ME
        warning('Fixed SIM merge failed (%s). Falling back to current-frame merge masks.', ME.message);
        [~,~,~,~,~,~,Ma_cur,DoubleMatSizeCur] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
        [~,~,~,~,~,~,Mb_cur,~]                = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
        [~,~,~,~,~,~,Mc_cur,~]                = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);
        OTFo_double_cur = OTFdoubling(OTFo_recon, DoubleMatSizeCur);
        [Fsum,~,~] = MergingHeptaletsF(fAof,fApf,fAmf, ...
                                       fBof,fBpf,fBmf, ...
                                       fCof,fCpf,fCmf, ...
                                       Ma_cur,Mb_cur,Mc_cur, ...
                                       1,1,1, 1,1,1, 1,1,1, ...
                                       kA,kB,kC,OBJparaA,OTFo_double_cur);
    end

    Dsum = real(ifft2(fftshift(Fsum)));
end
