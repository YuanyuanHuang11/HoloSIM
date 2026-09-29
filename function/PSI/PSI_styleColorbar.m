function PSI_styleColorbar(cb, ps)
    % Publication colorbar: black ticks/text, inward ticks and complete box.
    cb.FontName = ps.font_name;
    cb.FontSize = ps.font_size_axis;
    cb.Color = 'k';
    cb.LineWidth = ps.axis_line_width;
    cb.TickDirection = 'in';
    try
        cb.Box = 'on';
    catch
    end
    cb.Label.FontName = ps.font_name;
    cb.Label.FontSize = ps.font_size_label;
    cb.Label.Color = 'k';
    cb.Label.FontWeight = 'normal';
end
