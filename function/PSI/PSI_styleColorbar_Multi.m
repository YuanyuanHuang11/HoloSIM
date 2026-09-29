function PSI_styleColorbar_Multi(cb, ps)
    % Compact Nature-style colorbar: black ticks/text, normal-weight label,
    % light frame, and inward ticks for small multipanel figures.
    cb.FontName = ps.font_name;
    cb.FontSize = ps.font_size_axis;
    cb.Color = 'k';
    cb.LineWidth = ps.axis_line_width;
    cb.TickDirection = 'in';
    try
        cb.Box = 'off';
    catch
    end
    cb.Label.FontName = ps.font_name;
    cb.Label.FontSize = ps.font_size_label;
    cb.Label.Color = 'k';
    cb.Label.FontWeight = 'normal';
end
