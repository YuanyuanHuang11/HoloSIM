function T = PSI_computeThresholdTable(fullPitchNm, thresholds, curveNames, curves)
    nCurve = numel(curves);
    nThr = numel(thresholds);

    Curve = strings(nCurve*nThr,1);
    Threshold = nan(nCurve*nThr,1);
    ThresholdPercent = nan(nCurve*nThr,1);
    FirstCrossingPitch_nm = nan(nCurve*nThr,1);
    StableCrossingPitch_nm = nan(nCurve*nThr,1);
    RetentionAt130nm = nan(nCurve*nThr,1);
    RetentionAt150nm = nan(nCurve*nThr,1);
    RetentionAt200nm = nan(nCurve*nThr,1);
    Meets130nm = false(nCurve*nThr,1);
    Meets150nm = false(nCurve*nThr,1);
    Meets200nm = false(nCurve*nThr,1);

    row = 0;
    for cc = 1:nCurve
        R = curves{cc};
        R130 = PSI_interpRetention(fullPitchNm, R, 130);
        R150 = PSI_interpRetention(fullPitchNm, R, 150);
        R200 = PSI_interpRetention(fullPitchNm, R, 200);

        for tt = 1:nThr
            row = row + 1;
            tau = thresholds(tt);

            Curve(row) = string(curveNames{cc});
            Threshold(row) = tau;
            ThresholdPercent(row) = 100*tau;
            FirstCrossingPitch_nm(row) = PSI_thresholdPitchFirst(fullPitchNm, R, tau);
            StableCrossingPitch_nm(row) = PSI_thresholdPitchStable(fullPitchNm, R, tau);

            RetentionAt130nm(row) = R130;
            RetentionAt150nm(row) = R150;
            RetentionAt200nm(row) = R200;

            Meets130nm(row) = isfinite(R130) && R130 >= tau;
            Meets150nm(row) = isfinite(R150) && R150 >= tau;
            Meets200nm(row) = isfinite(R200) && R200 >= tau;
        end
    end

    T = table(Curve, Threshold, ThresholdPercent, ...
        FirstCrossingPitch_nm, StableCrossingPitch_nm, ...
        RetentionAt130nm, RetentionAt150nm, RetentionAt200nm, ...
        Meets130nm, Meets150nm, Meets200nm);
end
