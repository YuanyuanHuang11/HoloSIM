function val = PSI_getReconField(params, fieldName, defaultVal)
    if isfield(params, 'recon') && isfield(params.recon, fieldName) && ~isempty(params.recon.(fieldName))
        val = params.recon.(fieldName);
    else
        val = defaultVal;
    end
end
