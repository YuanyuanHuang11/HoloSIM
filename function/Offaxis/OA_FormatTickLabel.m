function s = OA_FormatTickLabel(v)
    if abs(v - round(v)) < 1e-10
        s = sprintf('%d', round(v));
    elseif abs(v*10 - round(v*10)) < 1e-10
        s = sprintf('%.1f', v);
    else
        s = sprintf('%.2g', v);
    end
end
