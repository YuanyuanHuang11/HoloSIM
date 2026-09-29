function [px, py] = PSI_MapCurveToRaster(x, y, xmin, xmax, ymin, ymax, x1, x2, y1, y2)
    px = x1 + (x - xmin) ./ (xmax - xmin + eps) * (x2 - x1);
    py = y2 - (y - ymin) ./ (ymax - ymin + eps) * (y2 - y1);
end
