function [P, FX_um, FY_um, FR_um] = PSI_errorPowerSpectrum(crop, dx)
    [ny,nx] = size(crop);
    F = fftshift(fft2(crop));
    P = abs(F).^2;
    P = P ./ max(P(:) + eps);

    fx = (-nx/2:nx/2-1)/(nx*dx) / 1e6;  % cycles/um
    fy = (-ny/2:ny/2-1)/(ny*dx) / 1e6;  % cycles/um
    [FX_um,FY_um] = meshgrid(fx,fy);
    FR_um = sqrt(FX_um.^2 + FY_um.^2);
end
