function OA_OverlaySiemensCircles(ax, GT, params, line_spec, line_width)
    if nargin < 4, line_spec = 'w--'; end
    if nargin < 5, line_width = 0.8; end
    if ~isfield(GT, 'siemens'), return; end

    center_x = params.N/2 + 1;
    center_y = params.N/2 + 1;
    tt = linspace(0, 2*pi, 400);

    hold(ax, 'on');
    radii_m = GT.siemens.ring_radius_m(:);
    for ii = 1:numel(radii_m)
        rr = radii_m(ii) / params.dx;
        plot(ax, center_x + rr*cos(tt), center_y + rr*sin(tt), line_spec, 'LineWidth', line_width);
    end

    % 额外叠加 Siemens star 有效外边界
    rr_outer = GT.siemens.star_radius_m / params.dx;
    plot(ax, center_x + rr_outer*cos(tt), center_y + rr_outer*sin(tt), 'w-', 'LineWidth', 1.0);
end
