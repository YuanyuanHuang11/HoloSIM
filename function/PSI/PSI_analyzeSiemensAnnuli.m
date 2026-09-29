function A = PSI_analyzeSiemensAnnuli(img,GT,S)
    r_axis = linspace(GT.inner_radius_m+4*S.dx, GT.star_radius_m-4*S.dx, 300);
    fp = 2*pi*r_axis/GT.num_line_pairs*1e9;
    mod_amp = nan(size(r_axis));
    cx = S.N/2 + 1;
    cy = S.N/2 + 1;
    nT = 4096;
    th = linspace(0,2*pi,nT+1); th(end)=[];
    [Xp,Yp] = meshgrid(1:S.N,1:S.N);
    for ii = 1:numel(r_axis)
        rr = r_axis(ii)/S.dx;
        stack = zeros(5,nT); c = 0;
        for dr = -2:2
            tmp = interp2(Xp,Yp,double(img),cx+(rr+dr)*cos(th),cy+(rr+dr)*sin(th),'linear',NaN);
            if nnz(isfinite(tmp)) > 0.9*numel(tmp)
                c = c + 1;
                stack(c,:) = tmp;
            end
        end
        if c > 0
            prof = mean(stack(1:c,:),1);
            prof = prof - mean(prof,'omitnan');
            F = fft(prof)/numel(prof);
            mod_amp(ii) = 2*abs(F(GT.num_line_pairs+1));
        end
    end
    A.r_axis = r_axis;
    A.full_pitch_nm = fp;
    A.mod_amp = mod_amp;
end
