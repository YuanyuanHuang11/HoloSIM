function [px, py] = OA_MapCurveXY(xx, yy, xlim_in, ylim_in, width, height, left, right, top, bottom)
    px = left + (xx - xlim_in(1)) ./ max(eps, xlim_in(2)-xlim_in(1)) .* (width-left-right);
    py = height-bottom - (yy - ylim_in(1)) ./ max(eps, ylim_in(2)-ylim_in(1)) .* (height-top-bottom);
end
