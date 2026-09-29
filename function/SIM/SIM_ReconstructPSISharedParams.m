function [Dsum_phase4, simParams] = SIM_ReconstructPSISharedParams(I_phase4, params)
% Calibrate on the first PSI raw stack; reuse frequencies, phases, Wiener
% coefficients, modulation factors, shift corrections and merge parameters.
% Uses the bundled backward-compatible PCM/SIM interfaces.
    names = {'PCMseparateF','PCMfilteringF','SIMimagesF'};
    for ii=1:numel(names)
        expected=fullfile(fileparts(mfilename('fullpath')),[names{ii} '.m']);
        assert(strcmpi(which(names{ii}),expected), ...
            'Wrong %s on MATLAB path. Use the bundled function/SIM version: %s', ...
            names{ii},expected);
    end
    assert(size(I_phase4,3)==4, 'Expected four PSI holograms.');
    w = params.N;
    fc = params.dx*1e9 * (2*params.NA_SIM*w)/(params.SIM_lambda*1e9);
    [PSFo,~] = PsfOtf(w,params.NA_SIM);
    OTFo = OTF(w,w,0,0,fc);
    H = OTF(w/2,w/2,0,0,fc);
    k2 = w*params.dx*1e9/params.sim.illum_period_nm;
    NoiseLevel = 100/params.sim.snr;
    Dsum_phase4 = zeros(w,w,4);
    simParams = struct('reference_phase_index',1,'OTFo_recon',H);
    phaseErrors = [];
    separated = cell(1,3);
    filtered = cell(1,3);
    for kk=1:4
        fprintf('    -> shared-parameter SIM: PSI frame %d/4\n',kk);
        [a1,a2,a3,b1,b2,b3,c1,c2,c3,~,~,phaseErrors] = ...
            SIMimagesF(k2,double(I_phase4(:,:,kk)),PSFo,OTFo,0.8,NoiseLevel,0,phaseErrors);
        raw = {a1,a2,a3;b1,b2,b3;c1,c2,c3};
        for d=1:3
            for j=1:3
                raw{d,j}=imresize(raw{d,j},0.5,'bicubic','Antialiasing',true);
            end
        end
        if kk==1
            fprintf('       calibrating separation and merge parameters once\n');
            for d=1:3
                [fo,fp,fm,k,sep] = PCMseparateF(raw{d,1},raw{d,2},raw{d,3},H);
                separated{d}={fo,fp,fm};
                simParams.direction(d).separation=sep;
                simParams.direction(d).k=k;
            end
            fCent=(separated{1}{1}+separated{2}{1}+separated{3}{1})/3;
            simParams.OBJparaA=OBJpowerPara(fCent,H);
        else
            for d=1:3
                [fo,fp,fm] = PCMseparateF(raw{d,1},raw{d,2},raw{d,3},H, ...
                    simParams.direction(d).separation);
                separated{d}={fo,fp,fm};
            end
        end
        for d=1:3
            f=separated{d};
            if kk==1
                filterCache=[];
            else
                filterCache=simParams.direction(d).filter;
            end
            [fo,fp,fm,~,~,~,M,doubleSize,filterCache]=PCMfilteringF( ...
                f{1},f{2},f{3},H,simParams.OBJparaA,simParams.direction(d).k,filterCache);
            filtered{d}={fo,fp,fm};
            if kk==1
                simParams.direction(d).filter=filterCache;
                simParams.direction(d).M=M;
                simParams.direction(d).doubleSize=doubleSize;
            else
                assert(isequal(doubleSize,simParams.direction(d).doubleSize), ...
                    'PCM filtering dimensions changed; shared-parameter merge aborted.');
            end
        end
        if kk==1
            simParams.OTFo_double=OTFdoubling(H,simParams.direction(1).doubleSize);
        end
        A=filtered{1}; B=filtered{2}; C=filtered{3};
        [Fsum,~,~]=MergingHeptaletsF(A{1},A{2},A{3},B{1},B{2},B{3},C{1},C{2},C{3}, ...
            simParams.direction(1).M,simParams.direction(2).M,simParams.direction(3).M, ...
            1,1,1,1,1,1,1,1,1,simParams.direction(1).k,simParams.direction(2).k, ...
            simParams.direction(3).k,simParams.OBJparaA,simParams.OTFo_double);
        D=real(ifft2(fftshift(Fsum)));
        assert(isequal(size(D),[w,w]),'Unexpected SIM output dimensions.');
        assert(all(isfinite(D(:))),'SIM reconstruction returned nonfinite values.');
        Dsum_phase4(:,:,kk)=D;
    end
    simParams.phaseErrors=phaseErrors;
end
