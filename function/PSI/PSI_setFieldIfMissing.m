function s = PSI_setFieldIfMissing(s, fieldName, defaultValue)
    if ~isfield(s, fieldName) || isempty(s.(fieldName))
        s.(fieldName) = defaultValue;
    end
end
