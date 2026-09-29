function outer_bg_mask = PSI_GetOuterBackgroundOnlyMask(mask_cell)
    % Return only the external background connected to the image boundary.
    % Internal pores/holes inside the cell are preserved and are not forced to zero.
    mask_cell = logical(mask_cell);
    mask_filled = imfill(mask_cell, 'holes');
    outer_bg_mask = ~mask_filled;
end
