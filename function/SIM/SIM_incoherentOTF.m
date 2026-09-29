function O = SIM_incoherentOTF(FR,fc)
    rho = FR/fc;
    O = zeros(size(FR));
    idx = rho <= 1;
    r = rho(idx);
    O(idx) = (2/pi)*(acos(r)-r.*sqrt(max(0,1-r.^2)));
    O(~isfinite(O)) = 0;
end
