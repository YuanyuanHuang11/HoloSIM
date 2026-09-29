function cmap = PSI_naturePhaseColormap(n)
    if nargin < 1
        n = 256;
    end

    % Perceptually smoother sequential map for phase panels.
    % Low phase: deep navy; mid phase: blue/teal; high phase: yellow/orange.
    % This avoids the strong artificial red/green transitions of jet while
    % keeping high phase visually prominent for printed figures.
    anchors = [
        0.05 0.07 0.22   % deep navy
        0.07 0.22 0.48   % blue
        0.05 0.45 0.67   % cyan-blue
        0.10 0.66 0.55   % teal
        0.55 0.78 0.30   % yellow-green
        0.98 0.78 0.18   % warm yellow
        0.88 0.32 0.13   % orange-red, only at highest phase
    ];

    x_anchor = linspace(0, 1, size(anchors, 1));
    xq = linspace(0, 1, n);
    cmap = zeros(n, 3);
    for cc = 1:3
        cmap(:,cc) = interp1(x_anchor, anchors(:,cc), xq, 'pchip');
    end
    cmap = min(max(cmap, 0), 1);
end
