function y = PSI_smoothColumnVector(x, win)
    x = double(x(:)).';
    win = max(1, round(win));
    if mod(win,2) == 0
        win = win + 1;
    end
    if win <= 1
        y = x;
        return;
    end
    try
        y = smoothdata(x, 'movmedian', win, 'omitnan');
        y = smoothdata(y, 'movmean', win, 'omitnan');
    catch
        kernel = ones(1, win) / win;
        y = conv(x, kernel, 'same');
    end
end
