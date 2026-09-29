function OA_ApplyPhaseMapColormapAndColorbar(ax, cmap_phase, phase_ticks)
    colormap(ax, cmap_phase);
    cb = colorbar(ax);
    cb.Ticks = phase_ticks;
    cb.TickLabels = arrayfun(@OA_FormatTickLabel, phase_ticks, 'UniformOutput', false);
    cb.TickDirection = 'in';
    cb.Color = 'k';
    cb.FontName = 'Arial';
    cb.FontSize = 9;
    cb.LineWidth = 0.8;
    cb.Label.String = 'Phase (rad)';
    cb.Label.FontName = 'Arial';
    cb.Label.Color = 'k';
end
