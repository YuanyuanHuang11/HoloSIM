function img = OA_DrawDashedRasterLine(img, x1, y1, x2, y2, color, lw, dash_len, gap_len)
    x1 = double(x1); y1 = double(y1); x2 = double(x2); y2 = double(y2);
    total_len = hypot(x2-x1, y2-y1);
    if total_len < 1
        img = OA_DrawRasterLine(img, x1, y1, x2, y2, color, lw);
        return;
    end
    ux = (x2-x1)/total_len; uy = (y2-y1)/total_len;
    pos = 0;
    while pos < total_len
        seg1 = pos;
        seg2 = min(total_len, pos + dash_len);
        xs = x1 + ux*seg1; ys = y1 + uy*seg1;
        xe = x1 + ux*seg2; ye = y1 + uy*seg2;
        img = OA_DrawRasterLine(img, xs, ys, xe, ye, color, lw);
        pos = pos + dash_len + gap_len;
    end
end
