function [thetaDeg, prof, actualPitchNm] = PSI_annularProfileAtPitch(img, GT, S, targetPitchNm)
    % Extract an azimuthal annular intensity profile at a target full pitch.
    rTarget = targetPitchNm * 1e-9 * GT.num_line_pairs / (2*pi);
    rTarget = min(max(rTarget, GT.inner_radius_m + 4*S.dx), GT.star_radius_m - 4*S.dx);
    actualPitchNm = 2*pi*rTarget / GT.num_line_pairs * 1e9;

    cx = S.N/2 + 1;
    cy = S.N/2 + 1;
    rr = rTarget / S.dx;
    nT = 2048;
    th = linspace(0, 2*pi, nT+1);
    th(end) = [];
    [Xp,Yp] = meshgrid(1:S.N, 1:S.N);

    stack = nan(5, nT);
    c = 0;
    for dr = -2:2
        tmp = interp2(Xp, Yp, double(img), cx + (rr+dr)*cos(th), cy + (rr+dr)*sin(th), 'linear', NaN);
        if nnz(isfinite(tmp)) > 0.9*numel(tmp)
            c = c + 1;
            stack(c,:) = tmp;
        end
    end
    if c == 0
        prof = nan(1,nT);
    else
        prof = mean(stack(1:c,:), 1, 'omitnan');
        prof = prof - mean(prof, 'omitnan');
    end
    thetaDeg = th * 180/pi;
end
