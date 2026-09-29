function I_ref = PSI_normalizeReferenceFrame(I_ref)
    % Normalize a fixed-operator reference frame without changing its spatial
    % structure. This avoids scale-dependent behavior in SIM parameter
    % estimation when the reference is mean/RMS/phase1 based.
    I_ref = double(I_ref);
    I_ref = I_ref - min(I_ref(:));
    max_val = max(I_ref(:));
    if max_val > 0 && isfinite(max_val)
        I_ref = I_ref / max_val;
    end
end
