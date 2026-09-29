function PSI_showModulationMapNature(img, ttl, climVals)
    imagesc(img);
    axis image off;
    colormap(gca, PSI_natureDivergingMap(256));
    caxis(climVals);
    title(ttl,'Interpreter','tex');
end
