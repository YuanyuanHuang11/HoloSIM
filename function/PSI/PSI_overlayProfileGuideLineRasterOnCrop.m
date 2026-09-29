function rgb = PSI_overlayProfileGuideLineRasterOnCrop(rgb, profile_line, ix, iy)
    if ~isfield(profile_line, 'row_index') || isempty(ix) || isempty(iy), return; end
    row_global = profile_line.row_index;
    row_local = row_global - min(iy) + 1;
    if row_local < 1 || row_local > numel(iy), return; end
    if isfield(profile_line, 'x_index_range') && ~isempty(profile_line.x_index_range)
        x_range = profile_line.x_index_range;
    else
        x_range = ix;
    end
    x1_local = min(x_range) - min(ix) + 1; x2_local = max(x_range) - min(ix) + 1;
    x1_local = min(max(x1_local, 1), numel(ix)); x2_local = min(max(x2_local, 1), numel(ix));
    tile_h = size(rgb, 1); tile_w = size(rgb, 2);
    yy = round(row_local / numel(iy) * tile_h);
    xx1 = round(x1_local / numel(ix) * tile_w); xx2 = round(x2_local / numel(ix) * tile_w);
    rgb = PSI_DrawRasterDashedLine(rgb, xx1, yy, xx2, yy, [1 1 1], [0 0 0], max(2, round(tile_h * 0.0022)));
end
