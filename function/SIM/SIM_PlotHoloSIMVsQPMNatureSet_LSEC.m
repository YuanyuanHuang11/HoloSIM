function SIM_PlotHoloSIMVsQPMNatureSet_LSEC(result, params, file_base)
    ps = params.plot;

    % Phase panels use MATLAB jet, as requested.  The same fixed color
    % limits are applied to GT, conventional QPM and HoloSIM.
    cmap_phase = jet(256);
    cmap_amp = gray(256);

    % Error maps are displayed as absolute phase error, using a sequential
    % purple-to-yellow colormap similar to the requested example colorbar.
    cmap_err = PSI_naturePurpleGreenYellow(256);

    % One fixed color scale for all phase panels and one fixed color scale
    % for all absolute-error panels.  The phase range is designed from the
    % joint finite values of GT, conventional QPM and HoloSIM so that all
    % three phase maps are directly comparable.
    [clim_phase, phase_ticks] = PSI_computeSharedPhaseClimTicks(result);
    clim_amp   = [0, 1];
    clim_err   = [0, 0.75];

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
    % The full 2-by-3 comparison is exported by direct raster composition by
    % default.  This avoids MATLAB graphics-infrastructure failures such as
    % "Unable to load figure infrastructure" / missing ViewModel during
    % print(), drawnow(), getframe(), exportgraphics(), or savefig().  The
    % individual panels and standalone colorbars below are also direct
    % imwrite exports.
    use_safe_raster = isfield(ps, 'use_safe_raster_comparison') && ps.use_safe_raster_comparison;
    if use_safe_raster
        PSI_ExportFullComparisonRaster(panelData, panelCmaps, panelClims, panelTitles, panelNames, ...
            [file_base '_full_comparison'], ps, result);
    else
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
                if isfield(result, 'profile_line') && rr == 1
                    PSI_overlayProfileGuideLine(ax(rr,cc), result.profile_line, size(panelData{rr,cc}));
                end
            end
        end

        cbPhase = colorbar(ax(1,3));
        cbPhase.Units = 'normalized';
        cbPhase.Position = [0.912, yTop, 0.015, axH];
        cbPhase.Label.String = 'Phase (rad)';
        cbPhase.Ticks = phase_ticks;
        PSI_styleColorbar(cbPhase, ps);

        cbErr = colorbar(ax(2,3));
        cbErr.Units = 'normalized';
        cbErr.Position = [0.912, yBot, 0.015, axH];
        cbErr.Label.String = '|Error| (rad)';
        cbErr.Ticks = [0, 0.2, 0.4, 0.6];
        PSI_styleColorbar(cbErr, ps);

        PSI_ExportPublicationFigureFast_LSEC(fig, [file_base '_full_comparison'], ps);
        if isfield(ps, 'close_fig_after_export') && ps.close_fig_after_export
            close(fig);
        end
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
        PSI_ExportStandaloneColorbar_LSEC(cmap_phase, clim_phase, 'Phase (rad)', ...
            [file_base '_colorbar_phase'], ps, phase_ticks);

        PSI_ExportStandaloneColorbar_LSEC(cmap_amp, clim_amp, 'Amplitude', ...
            [file_base '_colorbar_amplitude'], ps, [0 0.5 1.0]);

        PSI_ExportStandaloneColorbar_LSEC(cmap_err, clim_err, '|Error| (rad)', ...
            [file_base '_colorbar_error'], ps, [0 0.2 0.4 0.6]);
    end
end
