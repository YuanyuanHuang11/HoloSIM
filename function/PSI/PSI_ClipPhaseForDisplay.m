function img_show = PSI_ClipPhaseForDisplay(img, cmin, cmax, params)
    img_show = img;
    if isfield(params, 'display')
        img_show = min(max(img_show, cmin), cmax);
    end
end
