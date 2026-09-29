function Dsum = SIM_ReconstructSIMHologram(I_in, params)
    w = params.N;
    pixel_size_nm = params.dx * 1e9;
    lambda_nm = params.SIM_lambda * 1e9;
    illum_period_nm = params.sim.illum_period_nm;
  
    NoiseLevel = 100 / params.sim.snr;

    [PSFo,~] = PsfOtf(w, params.NA_SIM);
    fc = pixel_size_nm * (2 * params.NA_SIM * w) / lambda_nm;
    OTFo = OTF(w, w, 0, 0, fc);

    Io = zeros(w, w);
    Io(1:w, 1:w) = I_in;
    DIo = double(Io);

    k2 = w * pixel_size_nm / illum_period_nm;
    ModFac = 0.8;
    [S1a, S2a, S3a, S1b, S2b, S3b, S1c, S2c, S3c, ~, ~] = ...
        SIMimagesF(k2, DIo, PSFo, OTFo, ModFac, NoiseLevel, 0);

    scale = 0.5;
    S1a_d = imresize(S1a, scale, 'bicubic', 'Antialiasing', true);
    S2a_d = imresize(S2a, scale, 'bicubic', 'Antialiasing', true);
    S3a_d = imresize(S3a, scale, 'bicubic', 'Antialiasing', true);
    S1b_d = imresize(S1b, scale, 'bicubic', 'Antialiasing', true);
    S2b_d = imresize(S2b, scale, 'bicubic', 'Antialiasing', true);
    S3b_d = imresize(S3b, scale, 'bicubic', 'Antialiasing', true);
    S1c_d = imresize(S1c, scale, 'bicubic', 'Antialiasing', true);
    S2c_d = imresize(S2c, scale, 'bicubic', 'Antialiasing', true);
    S3c_d = imresize(S3c, scale, 'bicubic', 'Antialiasing', true);

    OTFo_recon = OTF(w/2, w/2, 0, 0, fc);

    [fAo,fAp,fAm,kA] = PCMseparateF(S1a_d, S2a_d, S3a_d, OTFo_recon);
    [fBo,fBp,fBm,kB] = PCMseparateF(S1b_d, S2b_d, S3b_d, OTFo_recon);
    [fCo,fCp,fCm,kC] = PCMseparateF(S1c_d, S2c_d, S3c_d, OTFo_recon);
    fCent = (fAo + fBo + fCo)/3;
    OBJparaA = OBJpowerPara(fCent, OTFo_recon);

    [fAof,fApf,fAmf,~,~,~,Ma,DoubleMatSize] = PCMfilteringF(fAo,fAp,fAm,OTFo_recon,OBJparaA,kA);
    [fBof,fBpf,fBmf,~,~,~,Mb,~]             = PCMfilteringF(fBo,fBp,fBm,OTFo_recon,OBJparaA,kB);
    [fCof,fCpf,fCmf,~,~,~,Mc,~]             = PCMfilteringF(fCo,fCp,fCm,OTFo_recon,OBJparaA,kC);
    OTFo_double = OTFdoubling(OTFo_recon, DoubleMatSize);

    [Fsum,~,~] = MergingHeptaletsF(fAof,fApf,fAmf, fBof,fBpf,fBmf, fCof,fCpf,fCmf, ...
                                   Ma,Mb,Mc, 1,1,1, 1,1,1, 1,1,1, kA,kB,kC, OBJparaA, OTFo_double);
    Dsum = real(ifft2(fftshift(Fsum)));

    % finterxy = 1;
    % fidelity0 = 500; %保真度，越低则越平滑
    % fidelity_z0 = 1; %z轴保真度，各项同性默认为1
    % sparsity0 = 1; %稀疏度
    % backg0 = 0;
    % iter = 3;
    % pixel = 32.5*10^-9;
    % wavelength = 488* 10^-9;
    % NA = 1.2;
    % 
    % Ipsf = kernel(pixel, wavelength, NA, 0, min(size(Dsum,1),size(Dsum,2)));
    % 
    % Dsum = abs(single(fourierInterpolation(Dsum,[finterxy],'lateral')));
    % % data_fI2 = data_fI2./max(max(data_fI2(:)));
    % 
    % [Dsum] = sparse_main(abs(Dsum),fidelity0,fidelity_z0,sparsity0,100,backg0);
    % 
    % % for i = 1:size(Dsum,3)
    % % Dsum(:,:,i) = RL3D(Dsum(:,:,i),Ipsf,iter,1);
    % % end
    % Dsum = abs(Dsum);
end
