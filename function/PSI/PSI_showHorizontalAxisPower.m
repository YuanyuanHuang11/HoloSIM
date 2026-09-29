function PSI_showHorizontalAxisPower(errImg, dx, analysisMask, ttl)
    [crop, dxLocal] = PSI_cropMaskedError(errImg, dx, analysisMask);
    [P, FX_um, FY_um, ~] = PSI_errorPowerSpectrum(crop, dxLocal);

    band = abs(FY_um) <= 0.08;
    fx = FX_um(1,:);
    pow = sum(P .* band, 1, 'omitnan');
    pow = pow ./ max(pow, [], 'omitnan');

    nexttile;
    plot(fx, pow, 'k-', 'LineWidth', 1.8);
    xlim([-5 5]);
    ylim([0 1.05]);
    grid on;
    xlabel('f_x (cycles/\mum)');
    ylabel('Normalized power');
    title(ttl,'Interpreter','tex');
end
