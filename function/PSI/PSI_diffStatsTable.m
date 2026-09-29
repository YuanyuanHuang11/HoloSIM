function T = PSI_diffStatsTable(name, diffImg, objMask, bgMask, starMask)
    regions = ["Object"; "Background"; "Star_all"];
    masks = {objMask, bgMask, starMask};

    MeanDiff = nan(3,1); MedianDiff = nan(3,1); P95Abs = nan(3,1);
    P99Abs = nan(3,1); MaxAbs = nan(3,1); RMS = nan(3,1); StdDiff = nan(3,1);

    for ii = 1:3
        m = masks{ii};
        v = diffImg(m & isfinite(diffImg));
        if ~isempty(v)
            MeanDiff(ii) = mean(v,'omitnan');
            MedianDiff(ii) = median(v,'omitnan');
            av = abs(v);
            P95Abs(ii) = PSI_localPercentile(av,95);
            P99Abs(ii) = PSI_localPercentile(av,99);
            MaxAbs(ii) = max(av);
            RMS(ii) = sqrt(mean(v.^2,'omitnan'));
            StdDiff(ii) = std(v,'omitnan');
        end
    end

    Name = repmat(string(name), 3, 1);
    T = table(Name, regions, MeanDiff, MedianDiff, StdDiff, RMS, P95Abs, P99Abs, MaxAbs, ...
        'VariableNames', {'CheckName','Region','MeanDiff','MedianDiff','StdDiff','RMSDiff','P95AbsDiff','P99AbsDiff','MaxAbsDiff'});
end
