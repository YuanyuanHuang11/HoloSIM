function PSI_ExportWorkflowPhaseBeforeAfterPairImageOnly(phase_before, phase_after, base_path)
    rgb1 = ind2rgb(gray2ind(mat2gray(double(phase_before), [-pi pi]), 256), jet(256));
    rgb2 = ind2rgb(gray2ind(mat2gray(double(phase_after),  [-pi pi]), 256), jet(256));

    gap = 255 * ones(size(rgb1,1), max(6, round(0.03*size(rgb1,2))), 3, 'uint8');
    rgb1_u8 = im2uint8(rgb1);
    rgb2_u8 = im2uint8(rgb2);
    pair_u8 = cat(2, rgb1_u8, gap, rgb2_u8);
    imwrite(pair_u8, [base_path '.png']);
end
