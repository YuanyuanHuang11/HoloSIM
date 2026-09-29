function [x,y,FX,FY,FR] = NF_makeGrids(N,dx)
    ax = (-N/2:N/2-1)*dx;
    [x,y] = meshgrid(ax, ax);
    f = (-N/2:N/2-1)/(N*dx);
    [FX,FY] = meshgrid(f, f);
    FR = sqrt(FX.^2 + FY.^2);
end
