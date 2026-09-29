function img = PSI_drawSimpleBitmapText(img, text_str, x0, y0, scale, color_rgb)
    % Minimal built-in bitmap text renderer for digits and common colorbar
    % symbols.  This avoids insertText and all figure backends.
    if nargin < 5 || isempty(scale)
        scale = 4;
    end
    if nargin < 6 || isempty(color_rgb)
        color_rgb = [0 0 0];
    end
    text_str = char(text_str);
    cursor_x = round(x0);
    y0 = round(y0);
    for kk = 1:numel(text_str)
        ch = text_str(kk);
        pat = PSI_bitmapPattern5x7(ch);
        if isempty(pat)
            cursor_x = cursor_x + 4 * scale;
            continue;
        end
        glyph = kron(double(pat), ones(scale, scale));
        [gh, gw] = size(glyph);
        x1 = cursor_x;
        x2 = cursor_x + gw - 1;
        y1 = y0;
        y2 = y0 + gh - 1;
        if x2 >= 1 && y2 >= 1 && x1 <= size(img,2) && y1 <= size(img,1)
            xs = max(1, x1):min(size(img,2), x2);
            ys = max(1, y1):min(size(img,1), y2);
            gx = xs - x1 + 1;
            gy = ys - y1 + 1;
            mask = glyph(gy, gx) > 0;
            for cc = 1:3
                plane = img(ys, xs, cc);
                plane(mask) = uint8(round(255 * color_rgb(cc)));
                img(ys, xs, cc) = plane;
            end
        end
        cursor_x = cursor_x + gw + scale;
    end
end
