function SP_ExportSparseWorkflowMaterials(complex_raw, complex_low, complex_res, complex_res_sparse, complex_out, valid, params)
    out_dir = params.sparse.workflow_dir;
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end

    branch_name = 'Sparse HoloSIM';
    if isfield(params.sparse, 'branch') && ~isempty(params.sparse.branch)
        branch_name = params.sparse.branch;
    end
    fprintf('    exporting Sparse-HoloSIM workflow materials [%s] to: %s', branch_name, out_dir);

    amp_raw = abs(complex_raw);
    amp_low = abs(complex_low);
    amp_res = abs(complex_res);
    amp_res_sparse = abs(complex_res_sparse);
    amp_out = abs(complex_out);
    phase_before = angle(complex_raw);
    phase_after = angle(complex_out);

    data_file = fullfile(out_dir, 'Sparse_HoloSIM_workflow_intermediate_data.mat');
    save(data_file, 'complex_raw', 'complex_low', 'complex_res', 'complex_res_sparse', 'complex_out', ...
        'amp_raw', 'amp_low', 'amp_res', 'amp_res_sparse', 'amp_out', 'phase_before', 'phase_after', ...
        'valid', 'params', '-v7.3');

    % Export each workflow panel as a clean image only, without axes or embedded
    % colorbars. Standalone grayscale and phase colorbars are exported separately.
    PSI_ExportWorkflowImageOnly(amp_raw,        fullfile(out_dir, '01_raw_complex_amplitude_absU'),          'gray', [1 99],   []);
    PSI_ExportWorkflowImageOnly(amp_low,        fullfile(out_dir, '02_low_frequency_baseline_absUlow'),      'gray', [1 99],   []);
    PSI_ExportWorkflowImageOnly(amp_res,        fullfile(out_dir, '03_high_frequency_residual_absUres'),     'gray', [1 99],   []);
    PSI_ExportWorkflowImageOnly(amp_res_sparse, fullfile(out_dir, '04_sparse_residual_absUres_sparse'),      'gray', [1 99],   []);
    PSI_ExportWorkflowImageOnly(amp_out,        fullfile(out_dir, '05_recombined_complex_field_absUout'),    'gray', [1 99],   []);
    PSI_ExportWorkflowImageOnly(phase_before,   fullfile(out_dir, '06_phase_before_sparse'),                 'jet',  [], [-pi pi]);
    PSI_ExportWorkflowImageOnly(phase_after,    fullfile(out_dir, '07_phase_after_sparse'),                  'jet',  [], [-pi pi]);

    % Also export a clean side-by-side before/after phase pair for convenient manual layout.
    PSI_ExportWorkflowPhaseBeforeAfterPairImageOnly(phase_before, phase_after, ...
        fullfile(out_dir, '08_phase_before_after_sparse_pair'));

    % Export standalone colorbars for manual figure assembly.
    gray_lo_hi = PSI_GlobalWorkflowGrayLimits({amp_raw, amp_low, amp_res, amp_res_sparse, amp_out}, [1 99]);
    PSI_ExportWorkflowStandaloneColorbar(fullfile(out_dir, '09_workflow_grayscale_colorbar'), 'gray', gray_lo_hi, 'Amplitude', true, params);
    PSI_ExportWorkflowStandaloneColorbar(fullfile(out_dir, '10_workflow_phase_colorbar'), 'jet', [-pi pi], 'Phase (rad)', false, params);
end
