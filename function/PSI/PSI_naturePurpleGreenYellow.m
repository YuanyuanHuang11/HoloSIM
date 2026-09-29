function cmap = PSI_naturePurpleGreenYellow(n)
    if nargin < 1
        n = 256;
    end

    % Sequential colormap for absolute error maps.
    % Low error: deep purple; high error: yellow.
    anchors = [
        0.25 0.00 0.33
        0.23 0.18 0.55
        0.13 0.43 0.72
        0.10 0.66 0.55
        0.55 0.82 0.30
        0.99 0.92 0.12
    ];

    x_anchor = linspace(0, 1, size(anchors, 1));
    xq = linspace(0, 1, n);

    cmap = zeros(n, 3);
    for cc = 1:3
        cmap(:,cc) = interp1(x_anchor, anchors(:,cc), xq, 'pchip');
    end

    cmap = min(max(cmap, 0), 1);
end
