function img = OA_DrawCircleMarker(img, cx, cy, radius, edge_color, fill_color, lw)
    [H,W,~] = size(img);
    cx = round(cx); cy = round(cy); radius = round(radius);
    [xx,yy] = meshgrid(max(1,cx-radius-2):min(W,cx+radius+2), max(1,cy-radius-2):min(H,cy+radius+2));
    d = sqrt((xx-cx).^2 + (yy-cy).^2);
    fill_mask = d <= radius;
    edge_mask = d <= radius & d >= radius-lw;
    rows = max(1,cy-radius-2):min(H,cy+radius+2);
    cols = max(1,cx-radius-2):min(W,cx+radius+2);
    for kk = 1:3
        patch = img(rows, cols, kk);
        patch(fill_mask) = uint8(255*fill_color(kk));
        patch(edge_mask) = uint8(255*edge_color(kk));
        img(rows, cols, kk) = patch;
    end
end
