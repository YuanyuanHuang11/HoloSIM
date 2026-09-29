function PSI_PrintLESCCalibrationInfo(GT, params)
    if ~isfield(GT, 'lesc')
        return;
    end
    fprintf('    -> LESC target: synthetic phase-amplitude morphology.\n');
    fprintf('       phase range: [%.3f, %.3f] rad.\n', min(GT.phi(:)), max(GT.phi(:)));
    fprintf('       cell pixels: %d / %d.\n', nnz(GT.mask_cell), numel(GT.mask_cell));
    fprintf('       ROI center: [%.2f, %.2f] um; half-width %.2f um.\n', ...
        params.display.roi_center_um(1), params.display.roi_center_um(2), params.display.roi_halfwidth_um);
end
