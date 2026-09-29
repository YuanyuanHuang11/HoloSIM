function complex_out = SP_SparseComplexCarrierRefine(complex_in, params)
    % Residual sparse refinement for demodulated complex fields.
    %
    % The demodulated complex field is written as
    %       U = A * exp(1i*phi) = real(U) + 1i*imag(U).
    % Direct sparse processing of the full real/imaginary components can
    % reshape large low-frequency phase structures, especially the high-phase
    % nucleus-like region. Therefore this function first separates a smooth
    % low-frequency complex baseline from a high-frequency complex residual:
    %       U = U_low + U_res.
    % Only U_res is sparsified. The low-frequency baseline is preserved.
    %
    % sparse_main() is treated as a real non-negative operator. The signed
    % real and imaginary residual channels are therefore split into positive
    % and negative components, processed separately, and then recombined.

    complex_raw = double(complex_in);

    valid = isfinite(real(complex_raw)) & isfinite(imag(complex_raw));
    if nnz(valid) < 10
        complex_out = complex_raw;
        return;
    end

    % ------------------------ parameters -------------------------------
    fidelity0    = 1500;
    fidelity_z0  = 1;
    sparsity0    = 0.05;
    backg0       = 0;
    sparse_iter  = 20;
    blend        = 0.15;
    sigma_low_px = 8;

    if isfield(params, 'sparse')
        if isfield(params.sparse, 'fidelity'),     fidelity0    = params.sparse.fidelity;     end
        if isfield(params.sparse, 'fidelity_z'),   fidelity_z0  = params.sparse.fidelity_z;   end
        if isfield(params.sparse, 'sparsity'),     sparsity0    = params.sparse.sparsity;     end
        if isfield(params.sparse, 'backg'),        backg0       = params.sparse.backg;        end
        if isfield(params.sparse, 'iter'),         sparse_iter  = params.sparse.iter;         end
        if isfield(params.sparse, 'sparse_iter'),  sparse_iter  = params.sparse.sparse_iter;  end
        if isfield(params.sparse, 'blend'),        blend        = params.sparse.blend;        end
        if isfield(params.sparse, 'sigma_low_px'), sigma_low_px = params.sparse.sigma_low_px; end
    end

    blend = min(max(double(blend), 0), 1);
    sigma_low_px = max(double(sigma_low_px), 0.5);

    % Replace invalid samples only for filtering. Restore them at the end.
    complex_work = complex_raw;
    complex_work(~valid) = 0;

    % ---------------- low-frequency complex baseline --------------------
    % Mask-normalized Gaussian filtering avoids low-pass leakage from invalid
    % pixels if any NaN/Inf values are present.
    w = double(valid);
    den = imgaussfilt(w, sigma_low_px) + eps;

    Cr = real(complex_work);
    Ci = imag(complex_work);
    Cr_low = imgaussfilt(Cr .* w, sigma_low_px) ./ den;
    Ci_low = imgaussfilt(Ci .* w, sigma_low_px) ./ den;
    complex_low = Cr_low + 1i * Ci_low;

    % Only the high-frequency residual is sparsified.
    complex_res = complex_work - complex_low;
    complex_res(~valid) = 0;

    Rr = real(complex_res);
    Ri = imag(complex_res);

    valid_r = isfinite(Rr) & valid;
    valid_i = isfinite(Ri) & valid;
    if nnz(valid_r) < 10 || nnz(valid_i) < 10
        complex_out = complex_raw;
        return;
    end

    scale_r = prctile(abs(Rr(valid_r)), 99) + eps;
    scale_i = prctile(abs(Ri(valid_i)), 99) + eps;

    if ~isfinite(scale_r) || scale_r <= eps || ~isfinite(scale_i) || scale_i <= eps
        complex_out = complex_raw;
        return;
    end

    Rrn = Rr / scale_r;
    Rin = Ri / scale_i;

    Rr_pos = max(Rrn, 0);
    Rr_neg = max(-Rrn, 0);
    Ri_pos = max(Rin, 0);
    Ri_neg = max(-Rin, 0);

    % ---------------- sparse processing of signed residual --------------
    Rr_pos_s = sparse_main(single(Rr_pos), fidelity0, fidelity_z0, sparsity0, sparse_iter, backg0);
    Rr_neg_s = sparse_main(single(Rr_neg), fidelity0, fidelity_z0, sparsity0, sparse_iter, backg0);
    Ri_pos_s = sparse_main(single(Ri_pos), fidelity0, fidelity_z0, sparsity0, sparse_iter, backg0);
    Ri_neg_s = sparse_main(single(Ri_neg), fidelity0, fidelity_z0, sparsity0, sparse_iter, backg0);

    Rr_sparse = scale_r * (double(Rr_pos_s) - double(Rr_neg_s));
    Ri_sparse = scale_i * (double(Ri_pos_s) - double(Ri_neg_s));
    complex_res_sparse = Rr_sparse + 1i * Ri_sparse;
    complex_res_sparse(~valid) = complex_res(~valid);

    % Recombine: preserve low-frequency phase/thickness, modify residual only.
    complex_candidate = complex_low + complex_res_sparse;
    complex_candidate(~valid) = complex_raw(~valid);

    complex_out = (1 - blend) * complex_raw + blend * complex_candidate;
    complex_out(~valid) = complex_raw(~valid);

    if SP_ShouldExportSparseWorkflowMaterials(params)
        SP_ExportSparseWorkflowMaterials(complex_raw, complex_low, complex_res, complex_res_sparse, complex_out, valid, params);
    end

    if isfield(params, 'sparse') && isfield(params.sparse, 'debug') && params.sparse.debug
        branch_name = 'complex field residual';
        if isfield(params.sparse, 'branch'), branch_name = params.sparse.branch; end
        dphi = angle(complex_out .* conj(complex_raw));
        fprintf('    residual sparse refine [%s]: blend=%.3f, sigma=%.2f px, fidelity=%.1f, sparsity=%.3f, iter=%d, mean|dphi|=%.4g rad\n', ...
            branch_name, blend, sigma_low_px, fidelity0, sparsity0, sparse_iter, mean(abs(dphi(valid)), 'omitnan'));
    end
end
