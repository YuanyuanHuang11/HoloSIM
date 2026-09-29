function phi = PSI_phaseFromFieldWithBackground(U,bgMask)
    if nargin<2 || isempty(bgMask) || nnz(bgMask)<100
        bgMask = true(size(U));
    end
    phi = angle(U * exp(-1i*angle(mean(U(bgMask)))));
end
