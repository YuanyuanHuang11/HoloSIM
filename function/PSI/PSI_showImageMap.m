function PSI_showImageMap(img,ttl,climVals)
    nexttile;
    imagesc(img);
    axis image off;
    colormap(gca, PSI_natureSequentialMap(256));
    if ~isempty(climVals)
        caxis(climVals);
    else
        caxis(PSI_robustClim(img, [1 99]));
    end
    title(ttl,'Interpreter','tex');
end
