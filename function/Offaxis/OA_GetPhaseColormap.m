function cmap = OA_GetPhaseColormap(params)
    if isfield(params, 'plot') && isfield(params.plot, 'phase_cmap_mode') ...
            && strcmpi(params.plot.phase_cmap_mode, 'nature_yellowgreen')

        % Nature-style yellow-green phase colormap.
        % Low phase: cyan-green; middle: yellow-green; high phase: warm yellow.
        dark   = [42, 222, 205] / 255;
        mid    = [178, 234,  72] / 255;
        bright = [255, 238,  40] / 255;

        n = 256;
        x = linspace(0,1,n)';
        cmap = zeros(n,3);
        for ii = 1:n
            if x(ii) < 0.58
                a = x(ii) / 0.58;
                cmap(ii,:) = dark*(1-a) + mid*a;
            else
                a = (x(ii)-0.58) / 0.42;
                cmap(ii,:) = mid*(1-a) + bright*a;
            end
        end

    elseif isfield(params, 'plot') && isfield(params.plot, 'phase_cmap_mode') ...
            && strcmpi(params.plot.phase_cmap_mode, 'nature_teal_cream')

        dark   = params.plot.siemens_dark_color;
        mid    = [38, 128, 128] / 255;
        bright = params.plot.siemens_bright_color;
        n = 256;
        x = linspace(0,1,n)';
        cmap = zeros(n,3);
        for ii = 1:n
            if x(ii) < 0.55
                a = x(ii) / 0.55;
                cmap(ii,:) = dark*(1-a) + mid*a;
            else
                a = (x(ii)-0.55) / 0.45;
                cmap(ii,:) = mid*(1-a) + bright*a;
            end
        end

    else
        cmap = jet(256);
    end
end
