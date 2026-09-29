function [img_crop, crop_rect, cx_local, cy_local] = PSI_CropWindowByCenterUm(img, params, center_um, halfwidth_um)
    cx = params.N/2 + 1 + center_um(1) * 1e-6 / params.dx;
    cy = params.N/2 + 1 + center_um(2) * 1e-6 / params.dy;
    halfwidth_px = max(8, round(halfwidth_um * 1e-6 / params.dx));

    x1 = max(1, round(cx - halfwidth_px));
    x2 = min(params.N, round(cx + halfwidth_px));
    y1 = max(1, round(cy - halfwidth_px));
    y2 = min(params.N, round(cy + halfwidth_px));

    img_crop = img(y1:y2, x1:x2);
    crop_rect = [x1, y1, x2 - x1 + 1, y2 - y1 + 1];
    cx_local = cx - x1 + 1;
    cy_local = cy - y1 + 1;
end
