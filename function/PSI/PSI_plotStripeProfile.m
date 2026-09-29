function PSI_plotStripeProfile(ax, sp, colGT, colHolo, colQPM, ps)
    x = sp.axis_nm(:);

    % Thinner lines, closer to journal-style line profiles
    lwGT   = 0.80;
    lwReco = 0.80;

    plot(ax, x, sp.GT(:),      '-', 'Color', colGT,   'LineWidth', lwGT);
    plot(ax, x, sp.HoloSIM(:), '-', 'Color', colHolo, 'LineWidth', lwReco);
    plot(ax, x, sp.QPM(:),     '-', 'Color', colQPM,  'LineWidth', lwReco);

    xlim(ax, [min(x) max(x)]);

    allY = [sp.GT(:); sp.HoloSIM(:); sp.QPM(:)];
    allY = allY(isfinite(allY));

    if isempty(allY)
        ylim(ax, [-0.1 1.8]);
    else
        yMin = min(allY);
        yMax = max(allY);
        pad = max(0.04, 0.08 * (yMax - yMin + eps));
        ylim(ax, [yMin - pad, yMax + pad]);
    end
end
