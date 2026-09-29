function Icam = SIM_cameraPixelIntegrateDownsample(Ihi, scale)
    % Camera pixel integration model for downsampling.
    % For scale = 0.5, each output camera pixel is the average of a 2 x 2
    % block on the high-resolution simulation grid.
    Ihi = double(Ihi);

    if abs(scale - 1) < 1e-12
        Icam = Ihi;
        return;
    end

    factor = round(1 / scale);
    if factor < 1 || abs(scale - 1/factor) > 1e-12
        error('cameraPixelIntegrateDownsample requires scale = 1/integer. Current scale = %.12g.', scale);
    end

    [ny,nx] = size(Ihi);
    ny2 = floor(ny/factor) * factor;
    nx2 = floor(nx/factor) * factor;
    Icrop = Ihi(1:ny2, 1:nx2);

    I4 = reshape(Icrop, factor, ny2/factor, factor, nx2/factor);
    Icam = squeeze(mean(mean(I4, 1), 3));
    Icam = reshape(Icam, ny2/factor, nx2/factor);
end
