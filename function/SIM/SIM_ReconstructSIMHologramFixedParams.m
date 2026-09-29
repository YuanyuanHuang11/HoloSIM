function Dsum = SIM_ReconstructSIMHologramFixedParams(I_in, params, simParams)
    % Reconstruct a hologram using the fixed SIM parameters estimated from
    % a reference image. This keeps kA/kB/kC, OBJparaA, and merge/filter
    % geometry fixed for all phase-shifted holograms.
    [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,OTFo_recon] = SIM_makeSIMRawStackDownsampled_Star(I_in, params);

    [fAo,fAp,fAm,~] = PCMseparateF(S1a,S2a,S3a,OTFo_recon);
    [fBo,fBp,fBm,~] = PCMseparateF(S1b,S2b,S3b,OTFo_recon);
    [fCo,fCp,fCm,~] = PCMseparateF(S1c,S2c,S3c,OTFo_recon);

    kA = simParams.kA;
    kB = simParams.kB;
    kC = simParams.kC;
    OBJparaA = simParams.OBJparaA;

    [fAof,fApf,fAmf,~,~,~,~,DoubleMatSizeA] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
    [fBof,fBpf,fBmf,~,~,~,~,DoubleMatSizeB] = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
    [fCof,fCpf,fCmf,~,~,~,~,DoubleMatSizeC] = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);

    % Use the fixed merge masks/geometry estimated from the reference image.
    % This is important for PSI: all four phase-shifted holograms should be
    % merged by the same Fourier-space operator.
    Ma = simParams.Ma;
    Mb = simParams.Mb;
    Mc = simParams.Mc;

    % Prefer fixed merge OTF/geometry. If the helper function returns a
    % different matrix size, use the fixed one anyway unless dimensions fail.
    OTFo_double = simParams.OTFo_double;

    try
        [Fsum,~,~] = MergingHeptaletsF(fAof,fApf,fAmf, ...
                                       fBof,fBpf,fBmf, ...
                                       fCof,fCpf,fCmf, ...
                                       Ma,Mb,Mc, ...
                                       1,1,1, 1,1,1, 1,1,1, ...
                                       kA,kB,kC,OBJparaA,OTFo_double);
    catch ME
        warning('Fixed Ma/Mb/Mc merge failed (%s). Falling back to current merge masks.', ME.message);
        [~,~,~,~,~,~,Ma_cur,DoubleMatSizeCur] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
        [~,~,~,~,~,~,Mb_cur,~]                = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
        [~,~,~,~,~,~,Mc_cur,~]                = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);
        OTFo_double_cur = OTFdoubling(OTFo_recon,DoubleMatSizeCur);
        [Fsum,~,~] = MergingHeptaletsF(fAof,fApf,fAmf, ...
                                       fBof,fBpf,fBmf, ...
                                       fCof,fCpf,fCmf, ...
                                       Ma_cur,Mb_cur,Mc_cur, ...
                                       1,1,1, 1,1,1, 1,1,1, ...
                                       kA,kB,kC,OBJparaA,OTFo_double_cur);
    end
    Dsum = real(ifft2(fftshift(Fsum)));
end
