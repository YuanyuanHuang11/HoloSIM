function img = OA_DrawPolyline(img, px, py, color, lw)
    if numel(px) < 2, return; end
    for ii = 1:(numel(px)-1)
        img = OA_DrawRasterLine(img, px(ii), py(ii), px(ii+1), py(ii+1), color, lw);
    end
end
