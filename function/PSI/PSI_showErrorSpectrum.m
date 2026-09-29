function PSI_showErrorSpectrum(errImg, dx, analysisMask, ttl)
    [crop, dxLocal] = PSI_cropMaskedError(errImg, dx, analysisMask);
    [P, FX_um, FY_um, ~] = PSI_errorPowerSpectrum(crop, dxLocal);

    nexttile;
    imagesc(FX_um(1,:), FY_um(:,1), log10(P + eps));
    axis image;
    set(gca,'YDir','normal');
    colormap(gca, PSI_natureSequentialMap(256));
    colorbar;
    xlabel('f_x (cycles/\mum)');
    ylabel('f_y (cycles/\mum)');
    title(ttl,'Interpreter','tex');
    xlim([-5 5]);
    ylim([-5 5]);
end
