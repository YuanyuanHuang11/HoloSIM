function val = PSI_GetPlotField(plot_style, field_name, default_val)
    if isfield(plot_style, field_name)
        val = plot_style.(field_name);
    else
        val = default_val;
    end
end
