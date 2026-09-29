function op=SIM_BuildWidefieldOTF(p)
% Analytic fluorescence OTF used only by the existing HoloWF baseline.
    N=p.N; assert(mod(N,2)==0,'Even grid required.');
    f=(-N/2:N/2-1)/(N*p.dx); [fx,fy]=meshgrid(f,f);
    rho=hypot(fx,fy)/(2*p.NA_SIM/p.SIM_lambda);
    H=zeros(N); m=rho<1;
    H(m)=(2/pi)*(acos(rho(m))-rho(m).*sqrt(1-rho(m).^2));
    op.H=ifftshift(H); op.N=N;
end
