function cmap = PSI_natureSequentialMap(n)
    % Soft sequential map: dark navy -> blue -> teal -> pale sand.
    if nargin < 1, n = 256; end
    anchors = [
        PSI_hex2rgb('#081D2D')
        PSI_hex2rgb('#1E6F7A')
        PSI_hex2rgb('#5BA9A6')
        PSI_hex2rgb('#E9D8A6')
        PSI_hex2rgb('#FFF7E6')
    ];
    cmap = interp1(linspace(0,1,size(anchors,1)), anchors, linspace(0,1,n), 'pchip');
    cmap = max(min(cmap,1),0);
end
