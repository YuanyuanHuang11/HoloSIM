function img = PSI_SetRasterPixelDisk(img, x, y, radius_px, color)
    h = size(img, 1); w = size(img, 2); xc = round(x); yc = round(y); r = max(1, round(radius_px));
    xlo = max(1, xc-r); xhi = min(w, xc+r); ylo = max(1, yc-r); yhi = min(h, yc+r);
    if xlo > xhi || ylo > yhi, return; end
    [xx, yy] = meshgrid(xlo:xhi, ylo:yhi); mask = (xx - xc).^2 + (yy - yc).^2 <= r^2;
    patch = img(ylo:yhi, xlo:xhi, :);
    for cc = 1:3
        tmp = patch(:,:,cc); tmp(mask) = color(cc); patch(:,:,cc) = tmp;
    end
    img(ylo:yhi, xlo:xhi, :) = patch;
end
