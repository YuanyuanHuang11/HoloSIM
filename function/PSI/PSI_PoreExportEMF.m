function PSI_PoreExportEMF(fig,base_path)
    persistent platformWarning
    if ~ispc
        if isempty(platformWarning)
            warning('Native EMF export requires Windows MATLAB. Other exports are retained.');
            platformWarning=true;
        end
        return;
    end
    try
        set(fig,'PaperPositionMode','auto');
        print(fig,[base_path '.emf'],'-dmeta');
    catch ME
        warning('EMF export failed: %s (%s)',base_path,ME.message);
        fid=fopen([base_path '_EMF_export_failed.txt'],'w');
        if fid>=0, fprintf(fid,'%s',ME.message); fclose(fid); end
    end
end
