function SIM_PlotHoloSIMVsQPMLocalZooms(result, params, file_base)
    % LESC-specific local zoom around the highest-phase center. The same
    % dashed line used for the profile is overlaid to connect maps and curve.
    ps = params.plot;
    max_fov = (params.N/2) * params.dx;

    if isfield(result, 'center_profile') && isfield(result.center_profile, 'peak_xy_m')
        center = result.center_profile.peak_xy_m;
    else
        center = [0, 0];
    end
    half_w = 0.34 * max_fov;

    xvec = result.GT_ref.x(1,:);
    yvec = result.GT_ref.y(:,1);
    ix = find(xvec >= center(1)-half_w & xvec <= center(1)+half_w);
    iy = find(yvec >= center(2)-half_w & yvec <= center(2)+half_w);
    if isempty(ix) || isempty(iy)
        ix = 1:params.N;
        iy = 1:params.N;
    end

    [clim_phase, phase_ticks] = PSI_computeSharedPhaseClimTicks(result);
    cmap_phase = jet(256);

    if PSI_GetPlotField(ps, 'use_safe_raster_zoom', true)
        panels = {result.GT_phi, result.phase_QPM, result.phase_HoloSIM};
        titles = {'GT: LESC center', 'Conventional QPM', 'HoloSIM QPM'};
        PSI_ExportLocalZoomRaster(panels, titles, ix, iy, clim_phase, cmap_phase, ...
            [file_base '_LESC_high_phase_center'], result, ps);
        return;
    end

    fig = figure('Color','w', 'Units','centimeters', 'Position',[2 2 17.2 5.8]);
    axW = 0.265;
    axH = 0.70;
    y0 = 0.18;
    x0 = [0.065 0.365 0.665];

    panels = {result.GT_phi, result.phase_QPM, result.phase_HoloSIM};
    titles = {'GT: LESC center', 'Conventional QPM', 'HoloSIM QPM'};

    ax = gobjects(1,3);
    for k = 1:3
        ax(k) = axes('Parent',fig,'Position',[x0(k) y0 axW axH]);
        imagesc(ax(k), panels{k}(iy,ix));
        axis(ax(k),'image'); axis(ax(k),'off');
        title(ax(k), titles{k});
        colormap(ax(k), cmap_phase); caxis(ax(k), clim_phase);
        if isfield(result, 'profile_line')
            PSI_overlayProfileGuideLineOnCrop(ax(k), result.profile_line, ix, iy);
        end
    end

    cb = colorbar(ax(3));
    cb.Units = 'normalized';
    cb.Position = [0.930 y0 0.014 axH];
    cb.Label.String = 'Phase (rad)';
    cb.Ticks = phase_ticks;
    PSI_styleColorbar(cb, ps);

    for k = 1:numel(ax)
        ax(k).Title.FontName = ps.font_name;
        ax(k).Title.FontSize = ps.font_size_title;
        ax(k).Title.FontWeight = 'normal';
    end

    PSI_ExportPublicationFigureFast_LSEC(fig, [file_base '_LESC_high_phase_center'], ps);
    if isfield(ps, 'close_fig_after_export') && ps.close_fig_after_export
        close(fig);
    end
end
