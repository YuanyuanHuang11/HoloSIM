function PSI_showMap(img,ttl,climVals)
    nexttile;
    imagesc(img);
    axis image off;
    colormap(gca, PSI_natureSequentialMap(256));
    caxis(climVals);
    title(ttl,'Interpreter','tex');
end
