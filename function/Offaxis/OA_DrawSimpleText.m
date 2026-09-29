function img = OA_DrawSimpleText(img, x, y, txt, scale, color)
    txt = char(txt);
    cursor = x;
    for ii = 1:numel(txt)
        ch = txt(ii);
        bm = OA_SimpleFont5x7(ch);
        if isempty(bm)
            cursor = cursor + 4*scale;
            continue;
        end
        [h,w] = size(bm);
        for rr = 1:h
            for cc = 1:w
                if bm(rr,cc)
                    r1 = y + (rr-1)*scale;
                    c1 = cursor + (cc-1)*scale;
                    r2 = min(size(img,1), r1+scale-1);
                    c2 = min(size(img,2), c1+scale-1);
                    if r1 >= 1 && c1 >= 1 && r1 <= size(img,1) && c1 <= size(img,2)
                        for kk = 1:3
                            img(r1:r2,c1:c2,kk) = uint8(color(kk));
                        end
                    end
                end
            end
        end
        cursor = cursor + (w+1)*scale;
    end
end
