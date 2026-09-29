function T = PSI_computeTwoPointThresholdTable(sep_nm, dipThresholds, methodLabels, dipFrac)
    nMethod = numel(methodLabels);
    nThr = numel(dipThresholds);

    Method = strings(nMethod*nThr,1);
    DipThreshold = nan(nMethod*nThr,1);
    DipThresholdPercent = nan(nMethod*nThr,1);
    StableResolution_nm = nan(nMethod*nThr,1);
    DipAt100nm = nan(nMethod*nThr,1);
    DipAt130nm = nan(nMethod*nThr,1);
    DipAt150nm = nan(nMethod*nThr,1);

    row = 0;
    for im = 1:nMethod
        d = dipFrac(:,im);
        for it = 1:nThr
            row = row + 1;
            tau = dipThresholds(it);
            Method(row) = string(methodLabels{im});
            DipThreshold(row) = tau;
            DipThresholdPercent(row) = 100*tau;
            StableResolution_nm(row) = PSI_twoPointStableResolution(sep_nm, d, tau);
            DipAt100nm(row) = interp1(sep_nm, d, 100, 'linear', NaN);
            DipAt130nm(row) = interp1(sep_nm, d, 130, 'linear', NaN);
            DipAt150nm(row) = interp1(sep_nm, d, 150, 'linear', NaN);
        end
    end

    T = table(Method, DipThreshold, DipThresholdPercent, StableResolution_nm, ...
        DipAt100nm, DipAt130nm, DipAt150nm);
end
