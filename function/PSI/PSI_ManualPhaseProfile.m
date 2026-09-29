function PSI_ManualPhaseProfile(A,params)
% One line selected on GT, sampled at identical coordinates in all methods.
% Original full-cell RMSE/PSNR/Pearson calculations are unchanged.
% No manual pore masks, amplitude rescaling, or additional offset fitting.
    names={'GT','Conventional QPM','Sparse conventional QPM','HoloWF', ...
        'Sparse-HoloWF','HoloSIM','Sparse-HoloSIM'};
    colors=[0 0 0; .85 .40 .12; .85 .40 .12; .24 .62 .57; .24 .62 .57; .15 .40 .76; .15 .40 .76];
    styles={'-','--','-','--','-','--','-'};
    width=1;
    if isfield(params,'profile') && isfield(params.profile,'width_px')
        width=params.profile.width_px;
    end
    assert(isscalar(width)&&isfinite(width)&&width>=1&&mod(width,2)==1, ...
        'params.profile.width_px must be a positive odd integer.');
    for k=1:7
        A{k}=double(gather(A{k}));
        assert(isreal(A{k})&&ismatrix(A{k})&&all(isfinite(A{k}(:))),'Invalid phase array.');
        assert(isequal(size(A{k}),size(A{1})),'Phase grids must match.');
    end
    GT=A{1}; sz=size(GT); limits=[min(GT(:)) max(GT(:))];
    assert(diff(limits)>0,'GT must not be constant.');
    out=fullfile(params.save_path,['Manual_profile_' datestr(now,'yyyymmdd_HHMMSS')]);
    if ~exist(out,'dir'), mkdir(out); end
    h=figure('Color','w','Name','Select ONE profile line on GT','Position',[80 80 950 800]);
    ax=axes('Parent',h); imagesc(ax,GT,limits); axis(ax,'image'); colormap(ax,jet(256));
    cb=colorbar(ax); ylabel(cb,'Phase (rad)');
    title(ax,'Draw one line through adjacent pores; adjust endpoints, then double-click');
    r=drawline(ax,'Color',[1 0 1]); wait(r);
    if ~isgraphics(h) || ~isvalid(r), return; end
    xy=r.Position;
    dxy=xy(2,:)-xy(1,:); len=norm(dxy);
    assert(len>0,'Profile line must have nonzero length.');
    n=max(2,ceil(2*len)+1); t=linspace(0,1,n)';
    x=xy(1,1)+t*dxy(1); y=xy(1,2)+t*dxy(2);
    normal=[-dxy(2) dxy(1)]/len; w=-(width-1)/2:(width-1)/2;
    X=x+normal(1)*w; Y=y+normal(2)*w;
    assert(all(X(:)>=1 & X(:)<=sz(2) & Y(:)>=1 & Y(:)<=sz(1)), ...
        'Profile strip crosses the image edge; choose an interior line or reduce width.');
    distance=t*hypot(dxy(1)*params.dx,dxy(2)*params.dy)*1e9;
    values=zeros(n,7);
    for k=1:7, values(:,k)=mean(interp2(A{k},X,Y,'linear'),2); end
    profile=struct('line_xy_pixels',xy,'width_pixels',width, ...
        'distance_nm',distance,'phase_rad',values,'method_names',{names}, ...
        'dx_m',params.dx,'dy_m',params.dy,'interpolation','bilinear');
    save(fullfile(out,'profile_results.mat'),'profile');
    T=array2table([distance values],'VariableNames',{'Distance_nm','GT','QPM', ...
        'Sparse_QPM','HoloWF','Sparse_HoloWF','HoloSIM','Sparse_HoloSIM'});
    writetable(T,fullfile(out,'profile_values.csv'));
    % Replace interactive ROI with an ordinary line for reliable export.
    delete(r); hold(ax,'on'); plot(ax,xy(:,1),xy(:,2),'m-','LineWidth',1.5);
    text(ax,xy(1,1),xy(1,2),'Start','Color','m','FontWeight','bold');
    title(ax,'GT phase and selected profile');
    PSI_ProfileSaveFigure(h,out,'GT_profile_location');

    h=figure('Color','w','Position',[40 40 1600 800]);
    tiledlayout(h,2,4,'TileSpacing','compact','Padding','compact');
    for k=1:7
        ax=nexttile; imagesc(ax,A{k},limits); axis(ax,'image'); axis(ax,'off');
        colormap(ax,jet(256)); hold(ax,'on');
        plot(ax,xy(:,1),xy(:,2),'m-','LineWidth',1);
        title(ax,names{k},'Interpreter','none'); colorbar(ax);
    end
    sgtitle('Phase (rad); same display range and profile coordinates');
    PSI_ProfileSaveFigure(h,out,'All_maps_profile_location');

    lo=min(values(:)); hi=max(values(:)); pad=max((hi-lo)*.06,1e-6);
    h=figure('Color','w','Position',[80 80 1050 600]); ax=axes('Parent',h); hold(ax,'on');
    for k=1:7
        plot(ax,distance,values(:,k),'Color',colors(k,:), ...
            'LineStyle',styles{k},'LineWidth',1.6);
    end
    xlabel(ax,'Distance (nm)'); ylabel(ax,'Phase (rad)');
    title(ax,sprintf('Same-line phase comparison; averaging width = %d pixel(s)',width));
    legend(ax,names,'Interpreter','none','Location','eastoutside','Box','off');
    set(ax,'FontName','Arial','FontSize',11,'Box','off');
    xlim(ax,[0 distance(end)]); ylim(ax,[lo-pad hi+pad]);
    PSI_ProfileSaveFigure(h,out,'Profile_all_methods');

    h=figure('Color','w','Position',[40 70 1500 480]);
    tiledlayout(h,1,3,'TileSpacing','compact','Padding','compact');
    for j=1:3
        ax=nexttile; hold(ax,'on'); ids=[1 2*j 2*j+1];
        for k=ids
            plot(ax,distance,values(:,k),'Color',colors(k,:), ...
                'LineStyle',styles{k},'LineWidth',1.6);
        end
        xlabel(ax,'Distance (nm)'); ylabel(ax,'Phase (rad)');
        legend(ax,names(ids),'Interpreter','none','Location','best','Box','off');
        set(ax,'FontName','Arial','FontSize',10,'Box','off');
        xlim(ax,[0 distance(end)]); ylim(ax,[lo-pad hi+pad]);
    end
    sgtitle('GT and paired reconstructions before/after sparse refinement');
    PSI_ProfileSaveFigure(h,out,'Profile_paired_methods');
    fprintf('Manual profile results saved to: %s\n',out);
end
