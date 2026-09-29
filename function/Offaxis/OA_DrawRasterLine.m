function img = OA_DrawRasterLine(img, x1, y1, x2, y2, color, lw)
    x1 = double(x1); y1 = double(y1); x2 = double(x2); y2 = double(y2);
    n = max(2, ceil(max(abs(x2-x1), abs(y2-y1))));
    xs = round(linspace(x1,x2,n)); ys = round(linspace(y1,y2,n));
    rad = max(0, floor(lw/2));
    for ii = 1:n
        rr = ys(ii)-rad:ys(ii)+rad; cc = xs(ii)-rad:xs(ii)+rad;
        rr = rr(rr>=1 & rr<=size(img,1)); cc = cc(cc>=1 & cc<=size(img,2));
        for kk = 1:3
            img(rr,cc,kk) = uint8(255*color(kk));
        end
    end
end
