function tf = SP_ShouldApplyComplexSparse(params)
    tf = false;
    if isfield(params, 'recon') && isfield(params.recon, 'enable_complex_sparse')
        tf = logical(params.recon.enable_complex_sparse);
    end
end
