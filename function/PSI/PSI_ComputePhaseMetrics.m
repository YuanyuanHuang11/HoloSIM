function metrics = PSI_ComputePhaseMetrics(GT_phi, recon_phi, mask_obj, phase_step)
    err = recon_phi - GT_phi;
    err_obj = err(mask_obj);

    metrics.rmse_rad = sqrt(mean(err_obj(:).^2, 'omitnan'));
    metrics.mae_rad = mean(abs(err_obj(:)), 'omitnan');
    metrics.corr_obj = PSI_SafeCorr(GT_phi(mask_obj), recon_phi(mask_obj));

    gt_std = std(GT_phi(mask_obj), 0, 'omitnan');
    recon_std = std(recon_phi(mask_obj), 0, 'omitnan');
    if gt_std > 1e-12
        metrics.phase_std_retention = recon_std / gt_std;
    else
        metrics.phase_std_retention = NaN;
    end

    if phase_step > 0
        metrics.nrmse = metrics.rmse_rad / phase_step;
    else
        metrics.nrmse = NaN;
    end
end
