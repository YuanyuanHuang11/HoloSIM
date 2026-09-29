function H = NF_propagationTF(FX,FY,lambda_eff,z)
    term = 1 - (lambda_eff*FX).^2 - (lambda_eff*FY).^2;
    k = 2*pi/lambda_eff;
    H = zeros(size(term));
    prop = term >= 0;
    H(prop) = exp(1i*k*z*sqrt(term(prop)));
    H(~prop) = exp(-k*z*sqrt(-term(~prop)));
end
