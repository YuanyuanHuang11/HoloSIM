function SIM_PlotHoloSIMVsQPMLocalZooms_Multi(result, params, file_base)
    ps = params.plot;
    N = params.N;
    max_fov = (N/2) * params.dx;

    % ROI centers approximately match structures created in GetFringeSet_FourPhase2.
    roi_defs = { ...
        'upper grating bars', [0.05*max_fov, 0.40*max_fov], 0.32*max_fov; ...
        'lower fine dots',    [0.60*max_fov, -0.55*max_fov], 0.28*max_fov; ...
        'concentric rings',   [0.60*max_fov, 0.60*max_fov], 0.32*max_fov};

    for ir = 1:size(roi_defs,1)
        name = roi_defs{ir,1};
        center = roi_defs{ir,2};
        half_w = roi_defs{ir,3};

        xvec = result.GT_ref.x(1,:);
        yvec = result.GT_ref.y(:,1);
        ix = find(xvec >= center(1)-half_w & xvec <= center(1)+half_w);
        iy = find(yvec >= center(2)-half_w & yvec <= center(2)+half_w);

        fig = figure('Color','w', 'Units','centimeters', 'Position',[2 2 17.2 5.8]);
        axW = 0.265; axH = 0.70; y0 = 0.18; x0 = [0.065 0.365 0.665];
        clim_phase = [0, params.siemens.phase_step * 1.50];
        cmap_phase = PSI_naturePhaseColormap(256);
        phase_ticks = params.plot.phase_colorbar_ticks;
        phase_ticks = phase_ticks(phase_ticks >= clim_phase(1) & phase_ticks <= clim_phase(2));

        ax1 = axes('Parent',fig,'Position',[x0(1) y0 axW axH]);
        imagesc(ax1, result.GT_phi(iy,ix)); axis(ax1,'image'); axis(ax1,'off');
        title(ax1, ['GT: ' name]); colormap(ax1, cmap_phase); caxis(ax1, clim_phase);

        ax2 = axes('Parent',fig,'Position',[x0(2) y0 axW axH]);
        imagesc(ax2, result.phase_QPM(iy,ix)); axis(ax2,'image'); axis(ax2,'off');
        title(ax2, 'Conventional QPM'); colormap(ax2, cmap_phase); caxis(ax2, clim_phase);

        ax3 = axes('Parent',fig,'Position',[x0(3) y0 axW axH]);
        imagesc(ax3, result.phase_HoloSIM(iy,ix)); axis(ax3,'image'); axis(ax3,'off');
        title(ax3, 'HoloSIM QPM'); colormap(ax3, cmap_phase); caxis(ax3, clim_phase);

        cb = colorbar(ax3);
        cb.Units = 'normalized'; cb.Position = [0.930 y0 0.014 axH];
        cb.Label.String = 'Phase (rad)'; cb.Ticks = phase_ticks; PSI_styleColorbar_Multi(cb, ps);

        axes_list = [ax1 ax2 ax3];
        for k = 1:numel(axes_list)
            axes_list(k).Title.FontName = ps.font_name;
            axes_list(k).Title.FontSize = ps.font_size_title;
            axes_list(k).Title.FontWeight = 'normal';
        end

        safe_name = regexprep(name, '[^a-zA-Z0-9]+', '_');
        PSI_ExportPublicationFigure_Multi(fig, [file_base '_' safe_name], ps, 'image');
        if isfield(ps, 'close_fig_after_export') && ps.close_fig_after_export
            close(fig);
        end
    end
end
