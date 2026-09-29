function T = PSI_artifactSpectrumStats(name, errImg, dx, analysisMask)
    % Quantify whether the phase-error spectrum is directionally concentrated.
    %
    % For vertical stripe artifacts in image space, the Fourier power tends
    % to concentrate near the horizontal frequency axis: |fy| ~ 0 and fx ~= 0.
    % This diagnostic compares that horizontal-axis power to the total
    % non-DC spectral power inside the cropped analysis region.

    [crop, dxLocal] = PSI_cropMaskedError(errImg, dx, analysisMask);
    [P, FX_um, FY_um, FR_um] = PSI_errorPowerSpectrum(crop, dxLocal);

    nonDC = FR_um > 0.15 & isfinite(P);
    horizontalBand = nonDC & abs(FY_um) <= 0.08;  % cycles/um band around horizontal axis
    verticalBand   = nonDC & abs(FX_um) <= 0.08;  % cycles/um band around vertical axis

    totalPower = sum(P(nonDC), 'omitnan');
    if totalPower <= 0 || ~isfinite(totalPower)
        horizFrac = NaN;
        vertFrac = NaN;
    else
        horizFrac = sum(P(horizontalBand), 'omitnan') / totalPower;
        vertFrac  = sum(P(verticalBand), 'omitnan') / totalPower;
    end

    P2 = P;
    P2(~nonDC) = -Inf;
    [peakPower, idx] = max(P2(:), [], 'omitnan');
    if isfinite(peakPower)
        peakFx = FX_um(idx);
        peakFy = FY_um(idx);
        peakFr = FR_um(idx);
        if peakFr > 0
            peakFullPitchNm = 1000 / peakFr;
        else
            peakFullPitchNm = NaN;
        end
        peakAngleDeg = atan2d(peakFy, peakFx);
    else
        peakFx = NaN; peakFy = NaN; peakFr = NaN;
        peakFullPitchNm = NaN; peakAngleDeg = NaN;
    end

    rmsErr = sqrt(mean(crop(:).^2, 'omitnan'));
    maxAbsErr = max(abs(crop(:)), [], 'omitnan');

    T = table(string(name), rmsErr, maxAbsErr, horizFrac, vertFrac, ...
        peakFx, peakFy, peakFr, peakFullPitchNm, peakAngleDeg, ...
        'VariableNames', {'ErrorMap','RMS_error_rad','MaxAbs_error_rad', ...
        'HorizontalAxisPowerFraction_verticalStripeIndex', ...
        'VerticalAxisPowerFraction_horizontalStripeIndex', ...
        'DominantPeak_fx_cycPerUm','DominantPeak_fy_cycPerUm', ...
        'DominantPeak_fr_cycPerUm','DominantPeak_fullPitch_nm', ...
        'DominantPeak_angle_deg'});
end
