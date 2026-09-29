function Y=SIM_FixedWidefield(X,op)
    B=real(ifft2(fft2(X).*op.H));
    Y=(B(1:2:end,1:2:end,:)+B(2:2:end,1:2:end,:)+ ...
       B(1:2:end,2:2:end,:)+B(2:2:end,2:2:end,:))/4;
end
