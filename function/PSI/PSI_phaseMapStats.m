function T = PSI_phaseMapStats(names, imgs, objMask, bgMask, phaseStep)
    n = numel(imgs);
    MeanObj = nan(n,1); MedianObj = nan(n,1); P95Obj = nan(n,1); P99Obj = nan(n,1);
    MaxObj = nan(n,1); MinObj = nan(n,1); ObjStd = nan(n,1);
    MeanBg = nan(n,1); MedianBg = nan(n,1); BgStd = nan(n,1);
    OvershootFrac = nan(n,1); OvershootMax = nan(n,1);
    UndershootFrac = nan(n,1); UndershootMin = nan(n,1);

    for ii = 1:n
        im = double(imgs{ii});

        obj = im(objMask & isfinite(im));
        bg  = im(bgMask & isfinite(im));

        if ~isempty(obj)
            MeanObj(ii) = mean(obj,'omitnan');
            MedianObj(ii) = median(obj,'omitnan');
            P95Obj(ii) = PSI_localPercentile(obj,95);
            P99Obj(ii) = PSI_localPercentile(obj,99);
            MaxObj(ii) = max(obj);
            MinObj(ii) = min(obj);
            ObjStd(ii) = std(obj,'omitnan');

            OvershootFrac(ii) = mean(obj > phaseStep);
            OvershootMax(ii) = max(obj) - phaseStep;
            UndershootFrac(ii) = mean(obj < 0);
            UndershootMin(ii) = min(obj);
        end

        if ~isempty(bg)
            MeanBg(ii) = mean(bg,'omitnan');
            MedianBg(ii) = median(bg,'omitnan');
            BgStd(ii) = std(bg,'omitnan');
        end
    end

    T = table(names(:), MeanObj, MedianObj, P95Obj, P99Obj, MaxObj, MinObj, ObjStd, ...
        MeanBg, MedianBg, BgStd, OvershootFrac, OvershootMax, UndershootFrac, UndershootMin, ...
        'VariableNames', {'MapName','MeanObj','MedianObj','P95Obj','P99Obj','MaxObj','MinObj','StdObj', ...
        'MeanBg','MedianBg','StdBg','OvershootFrac_gtPhaseStep','OvershootMax_minusPhaseStep', ...
        'UndershootFrac_below0','UndershootMin'});
end
