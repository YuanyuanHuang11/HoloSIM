function [crop, dxLocal] = PSI_cropMaskedError(errImg, dx, analysisMask)
    errImg = double(errImg);
    dxLocal = dx;

    if nargin < 3 || isempty(analysisMask) || nnz(analysisMask) < 100
        analysisMask = isfinite(errImg);
    end

    [yy,xx] = find(analysisMask & isfinite(errImg));
    if isempty(xx)
        crop = errImg;
        crop(~isfinite(crop)) = 0;
        crop = crop - mean(crop(:),'omitnan');
        return;
    end

    pad = 32;
    y1 = max(1, min(yy)-pad); y2 = min(size(errImg,1), max(yy)+pad);
    x1 = max(1, min(xx)-pad); x2 = min(size(errImg,2), max(xx)+pad);

    crop = errImg(y1:y2, x1:x2);
    m = analysisMask(y1:y2, x1:x2) & isfinite(crop);

    medVal = median(crop(m), 'omitnan');
    crop(~isfinite(crop)) = medVal;
    crop(~m) = medVal;
    crop = crop - medVal;

    % Smooth window to reduce FFT edge leakage from the crop boundary.
    wy = hann(size(crop,1));
    wx = hann(size(crop,2));
    W = wy * wx.';
    crop = crop .* W;
end
