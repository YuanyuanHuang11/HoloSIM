function cmap = PSI_natureDivergingMap(n)
    % Soft blue-white-red diverging map for residual/error panels.
    if nargin < 1, n = 256; end
    anchors = [
        PSI_hex2rgb('#2C5AA0')
        PSI_hex2rgb('#78A6C8')
        PSI_hex2rgb('#F7F7F7')
        PSI_hex2rgb('#E39A6D')
        PSI_hex2rgb('#A8322D')
    ];
    cmap = interp1(linspace(0,1,size(anchors,1)), anchors, linspace(0,1,n), 'pchip');
    cmap = max(min(cmap,1),0);
end
