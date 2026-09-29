function rgb = PSI_hex2rgb(hex)
    % Convert '#RRGGBB' to MATLAB RGB triplet in [0, 1].
    if isstring(hex), hex = char(hex); end
    if startsWith(hex, '#'), hex = hex(2:end); end
    if numel(hex) ~= 6
        error('hex2rgb expects color format #RRGGBB.');
    end
    rgb = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
end
