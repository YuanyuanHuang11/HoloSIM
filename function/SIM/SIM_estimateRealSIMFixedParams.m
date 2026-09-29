function simParams = SIM_estimateRealSIMFixedParams(I_ref, params)
    % Estimate SIM reconstruction parameters once from a reference hologram.
    [S1a,S2a,S3a,S1b,S2b,S3b,S1c,S2c,S3c,OTFo_recon] = SIM_makeSIMRawStackDownsampled_Star(I_ref, params);

    [fAo,fAp,fAm,kA] = PCMseparateF(S1a,S2a,S3a,OTFo_recon);
    [fBo,fBp,fBm,kB] = PCMseparateF(S1b,S2b,S3b,OTFo_recon);
    [fCo,fCp,fCm,kC] = PCMseparateF(S1c,S2c,S3c,OTFo_recon);

    fCent = (fAo+fBo+fCo)/3;
    OBJparaA = OBJpowerPara(fCent,OTFo_recon);

    [~,~,~,~,~,~,Ma,DoubleMatSize] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
    [~,~,~,~,~,~,Mb,~]             = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
    [~,~,~,~,~,~,Mc,~]             = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);

    simParams = struct();
    simParams.kA = kA;
    simParams.kB = kB;
    simParams.kC = kC;
    simParams.OBJparaA = OBJparaA;
    simParams.Ma = Ma;
    simParams.Mb = Mb;
    simParams.Mc = Mc;
    simParams.DoubleMatSize = DoubleMatSize;
    simParams.OTFo_recon = OTFo_recon;
    simParams.OTFo_double = OTFdoubling(OTFo_recon,DoubleMatSize);
end
