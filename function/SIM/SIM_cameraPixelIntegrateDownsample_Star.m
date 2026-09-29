function Icam = SIM_cameraPixelIntegrateDownsample_Star(Ihi, scale)
    % Camera pixel integration model for downsampling.
    %
    % For the current simulation, the object/SIM grid is 32.5 nm and the
    % camera pixel is 65 nm, so scale = 0.5 and each camera pixel integrates
    % a 2 x 2 high-resolution block.
    %
    % This is physically closer to a finite camera pixel than bicubic
    % interpolation. It also avoids interpolation-induced directional
    % artifacts when the SIM carrier is close to the sampling limit.

    Ihi = double(Ihi);

    if abs(scale - 1) < 1e-12
        Icam = Ihi;
        return;
    end

    factor = round(1/scale);
    if factor < 1 || abs(scale - 1/factor) > 1e-12
        error(['cameraPixelIntegrateDownsample currently requires scale = 1/integer. ', ...
               'Current scale = %.12g.'], scale);
    end

    [ny, nx] = size(Ihi);
    ny2 = floor(ny/factor) * factor;
    nx2 = floor(nx/factor) * factor;

    if ny2 ~= ny || nx2 ~= nx
        warning('Cropping image from %d x %d to %d x %d for integer pixel integration.', ...
            ny, nx, ny2, nx2);
    end

    Icrop = Ihi(1:ny2, 1:nx2);

    % Block average over factor x factor high-resolution pixels.
    % MATLAB reshape order:
    % [factor, ny/factor, factor, nx/factor] -> average dimensions 1 and 3.
    I4 = reshape(Icrop, factor, ny2/factor, factor, nx2/factor);
    Icam = squeeze(mean(mean(I4, 1), 3));

    % squeeze can return a row vector for degenerate cases. Ensure 2D shape.
    Icam = reshape(Icam, ny2/factor, nx2/factor);
end
