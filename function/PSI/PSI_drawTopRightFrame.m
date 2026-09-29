function PSI_drawTopRightFrame(ax, lineWidth)
    % Draw visual top and right frame lines without top/right tick marks.
    if nargin < 2, lineWidth = 0.75; end
    if ~isgraphics(ax, 'axes'), return; end
    delete(findobj(ax, 'Tag', 'TopRightFrameLine'));
    xl = xlim(ax);
    yl = ylim(ax);
    if strcmpi(ax.XDir, 'reverse')
        xRight = xl(1);
    else
        xRight = xl(2);
    end
    if strcmpi(ax.YDir, 'reverse')
        yTop = yl(1);
    else
        yTop = yl(2);
    end
    holdState = ishold(ax);
    hold(ax, 'on');
    hTop = line(ax, xl, [yTop yTop], 'Color','k', 'LineWidth',lineWidth, ...
        'Clipping','off', 'HandleVisibility','off', 'Tag','TopRightFrameLine');
    hRight = line(ax, [xRight xRight], yl, 'Color','k', 'LineWidth',lineWidth, ...
        'Clipping','off', 'HandleVisibility','off', 'Tag','TopRightFrameLine');
    try
        hTop.Annotation.LegendInformation.IconDisplayStyle = 'off';
        hRight.Annotation.LegendInformation.IconDisplayStyle = 'off';
    catch
    end
    if ~holdState, hold(ax, 'off'); end
    xlim(ax, xl);
    ylim(ax, yl);
end
