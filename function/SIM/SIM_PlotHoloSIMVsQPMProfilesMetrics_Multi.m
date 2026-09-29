function SIM_PlotHoloSIMVsQPMProfilesMetrics_Multi(result, params, file_base)
    % Profiles-only figure for publication.
    % Show only the vertical- and horizontal-grating phase profiles.
    % Styling is simplified to resemble a clean Nature-style line plot:
    % no top/right frame lines, thinner curves, and restrained typography.

    ps = params.plot;

    % Nature-style restrained colors
    % GT 改为灰色
    colGT   = [0.45 0.45 0.45];
    colHolo = [0.00 0.45 0.74];
    colQPM  = [0.85 0.33 0.00];

    fig = figure('Color','w', ...
        'Units','centimeters', ...
        'Position',[2 2 19.5 5.8]);

    axW = 0.405;
    axH = 0.70;
    y0 = 0.18;
    xLeft = 0.065;
    xRight = 0.520;

    % ------------------------------------------------------------------
    % a. Vertical grating profile
    % ------------------------------------------------------------------
    ax1 = axes('Parent', fig, 'Position', [xLeft y0 0.85*axW axH]);
    hold(ax1, 'on');

    sp1 = result.stripe_profiles.vertical_grating;
    PSI_plotStripeProfile(ax1, sp1, colGT, colHolo, colQPM, ps);

    title(ax1, 'Vertical grating profile', ...
        'FontName', ps.font_name, ...
        'FontSize', ps.font_size_title, ...
        'FontWeight', 'normal');

    xlabel(ax1, 'Lateral position (nm)');
    ylabel(ax1, 'Phase (rad)');
    PSI_FormatProfileAxesNature_Multi(ax1, ps);

    % ------------------------------------------------------------------
    % b. Horizontal grating profile
    % ------------------------------------------------------------------
    ax2 = axes('Parent', fig, 'Position', [xRight y0 1.15*axW axH]);
    hold(ax2, 'on');

    sp2 = result.stripe_profiles.horizontal_grating;
    PSI_plotStripeProfile(ax2, sp2, colGT, colHolo, colQPM, ps);

    title(ax2, 'Horizontal grating profile', ...
        'FontName', ps.font_name, ...
        'FontSize', ps.font_size_title, ...
        'FontWeight', 'normal');

    xlabel(ax2, 'Lateral position (nm)');
    ylabel(ax2, 'Phase (rad)');
    PSI_FormatProfileAxesNature_Multi(ax2, ps);

    % ------------------------------------------------------------------
    % Legend: only in panel 1, manual placement in upper-right blank region
    % ------------------------------------------------------------------
    lgd = legend(ax1, {'GT','HoloSIM','Conventional QPM'}, ...
        'Location', 'none');

    PSI_FormatLegendNature(lgd, ps);

    % 手动放到第一幅图右上角空白区域，避免与曲线重叠
    % 这个位置是按当前版式专门调过的
    ax1Pos = ax1.Position;
    lgd.Units = 'normalized';
    lgd.Position = [ax1Pos(1) + 0.78*ax1Pos(3), ...
                    ax1Pos(2) + 0.74*ax1Pos(4), ...
                    0.16, 0.14];
    lgd.Box = 'off';

    try
        lgd.ItemTokenSize = [10 7];
    catch
    end

    PSI_ExportPublicationFigureFast(fig, file_base, ps);

    if isfield(ps, 'close_fig_after_export') && ps.close_fig_after_export
        close(fig);
    end
end
