function PSI_PrintMetricVector(prefix, names, vals)
    fprintf('%s:', prefix);
    for kk = 1:numel(vals)
        fprintf(' %s=%.4f', names{kk}, vals(kk));
        if kk < numel(vals)
            fprintf(',');
        end
    end
    fprintf('\n');
end
