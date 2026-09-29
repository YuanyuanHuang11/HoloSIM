function SIM_PlotHoloSIMVsQPMNatureSet(result, params, file_base)
    ps = params.plot;

    % Nature-style sequential phase colormap. Avoid MATLAB jet/rainbow for
    % final figures because it is not perceptually uniform and can introduce
    % artificial contrast bands.
    cmap_phase = PSI_naturePhaseColormap(256);
    cmap_amp = gray(256);

    % Error maps are displayed as absolute phase error, using a sequential
    % purple-to-yellow colormap similar to the requested example colorbar.
    cmap_err = PSI_naturePurpleGreenYellow(256);

    % One fixed color scale for all phase panels and one fixed color scale
    % for all absolute-error panels. This makes the comparison visually fair.
    clim_phase = [0, params.siemens.phase_step * 1.50];
    clim_amp   = [0, 1];
    clim_err   = [0, 0.75];
    phase_ticks = params.plot.phase_colorbar_ticks;
    phase_ticks = phase_ticks(phase_ticks >= clim_phase(1) & phase_ticks <= clim_phase(2));

    err_QPM_abs = abs(result.err_QPM);
    err_HoloSIM_abs = abs(result.err_HoloSIM);

    panelData = { ...
        result.GT_phi,          result.phase_QPM,      result.phase_HoloSIM; ...
        result.GT_ref.amp,      err_QPM_abs,           err_HoloSIM_abs};

    panelTitles = { ...
        'Ground truth phase',   'Conventional QPM',    'HoloSIM QPM'; ...
        'Sample amplitude',     'QPM |error|',         'HoloSIM |error|'};

    panelCmaps = { ...
        cmap_phase, cmap_phase, cmap_phase; ...
        cmap_amp,   cmap_err,   cmap_err};

    panelClims = { ...
        clim_phase, clim_phase, clim_phase; ...
        clim_amp,   clim_err,   clim_err};

    panelNames = { ...
        'GT_phase', 'QPM_phase', 'HoloSIM_phase'; ...
        'Sample_amplitude', 'QPM_abs_error', 'HoloSIM_abs_error'};

    %% Complete comparison figure
    fig = figure('Color','w', ...
        'Units','centimeters', ...
        'Position',[2 2 18.2 10.7]);

    axW = 0.235;
    axH = 0.345;
    x0 = [0.055, 0.345, 0.635];
    yTop = 0.565;
    yBot = 0.115;

    ax = gobjects(2,3);
    for rr = 1:2
        if rr == 1
            yy = yTop;
        else
            yy = yBot;
        end
        for cc = 1:3
            ax(rr,cc) = axes('Parent', fig, 'Position', [x0(cc), yy, axW, axH]);
            imagesc(ax(rr,cc), panelData{rr,cc});
            axis(ax(rr,cc), 'image');
            axis(ax(rr,cc), 'off');
            colormap(ax(rr,cc), panelCmaps{rr,cc});
            caxis(ax(rr,cc), panelClims{rr,cc});
            title(ax(rr,cc), panelTitles{rr,cc}, ...
                'FontName', ps.font_name, ...
                'FontSize', ps.font_size_title, ...
                'FontWeight', 'normal', ...
                'Color', 'k');
        end
    end

    cbPhase = colorbar(ax(1,3));
    cbPhase.Units = 'normalized';
    cbPhase.Position = [0.912, yTop, 0.015, axH];
    cbPhase.Label.String = 'Phase (rad)';
    cbPhase.Ticks = phase_ticks;
    PSI_styleColorbar_Multi(cbPhase, ps);

    cbErr = colorbar(ax(2,3));
    cbErr.Units = 'normalized';
    cbErr.Position = [0.912, yBot, 0.015, axH];
    cbErr.Label.String = '|Error| (rad)';
    cbErr.Ticks = [0, 0.2, 0.4, 0.6];
    PSI_styleColorbar_Multi(cbErr, ps);

    PSI_ExportPublicationFigureFast(fig, [file_base '_full_comparison'], ps);
    if isfield(ps, 'close_fig_after_export') && ps.close_fig_after_export
        close(fig);
    end

    %% Individual panels, exported without titles and without scale bars
    if isfield(ps, 'save_individual_panels') && ps.save_individual_panels
        for rr = 1:2
            for cc = 1:3
                PSI_ExportSingleImagePanel(panelData{rr,cc}, panelCmaps{rr,cc}, ...
                    panelClims{rr,cc}, panelTitles{rr,cc}, ...
                    [file_base '_' panelNames{rr,cc}], ps);
            end
        end
    end

    %% Standalone colorbars for manual layout in Illustrator/PowerPoint/etc.
    if isfield(ps, 'save_standalone_colorbars') && ps.save_standalone_colorbars
        PSI_ExportStandaloneColorbar(cmap_phase, clim_phase, 'Phase (rad)', ...
            [file_base '_colorbar_phase'], ps, phase_ticks);

        PSI_ExportStandaloneColorbar(cmap_amp, clim_amp, 'Amplitude', ...
            [file_base '_colorbar_amplitude'], ps, [0 0.5 1.0]);

        PSI_ExportStandaloneColorbar(cmap_err, clim_err, '|Error| (rad)', ...
            [file_base '_colorbar_error'], ps, [0 0.2 0.4 0.6]);
    end
end
