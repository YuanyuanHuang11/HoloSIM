function labels = PSI_formatColorbarTickLabels(vals)
    labels = cell(size(vals));
    for ii = 1:numel(vals)
        v = vals(ii);
        if abs(v - round(v)) < 1e-10
            labels{ii} = sprintf('%d', round(v));
        elseif abs(v*10 - round(v*10)) < 1e-10
            labels{ii} = sprintf('%.1f', v);
        elseif abs(v*100 - round(v*100)) < 1e-10
            labels{ii} = sprintf('%.2f', v);
        else
            labels{ii} = sprintf('%.3g', v);
        end
    end
end
