function mask = PSI_BuildMaskFromCropRect(sz, crop_rect)
    mask = false(sz);
    x1 = max(1, round(crop_rect(1)));
    y1 = max(1, round(crop_rect(2)));
    x2 = min(sz(2), round(crop_rect(1) + crop_rect(3) - 1));
    y2 = min(sz(1), round(crop_rect(2) + crop_rect(4) - 1));
    mask(y1:y2, x1:x2) = true;
end
