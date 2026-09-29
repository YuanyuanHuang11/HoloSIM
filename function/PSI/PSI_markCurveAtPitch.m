function PSI_markCurveAtPitch(x, y, pitchNm, colorVal)
    yq = interp1(x(:), y(:), pitchNm, 'linear', NaN);
    if isfinite(yq)
        plot(pitchNm, yq, 'o', 'MarkerSize', 3.8, 'LineWidth', 1.45, ...
            'MarkerFaceColor','w', 'MarkerEdgeColor', colorVal, ...
            'HandleVisibility','off');
    end
end
