function x_res = OA_EstimateResolutionAtThreshold(x_nm, y, threshold)
    x_nm = x_nm(:); y = y(:);
    valid = isfinite(x_nm) & isfinite(y);
    x_nm = x_nm(valid); y = y(valid);
    if isempty(x_nm)
        x_res = NaN;
        return;
    end
    [x_nm, order] = sort(x_nm, 'ascend');
    y = y(order);
    idx = find(y >= threshold, 1, 'first');
    if isempty(idx)
        x_res = NaN;
    elseif idx == 1
        x_res = x_nm(1);
    else
        x1 = x_nm(idx-1); x2 = x_nm(idx);
        y1 = y(idx-1); y2 = y(idx);
        if abs(y2-y1) < eps
            x_res = x2;
        else
            x_res = x1 + (threshold-y1) * (x2-x1) / (y2-y1);
        end
    end
end
