function PSI_safeSaveFigure_TP(fig, filename, S)
    % Robust figure saving for MATLAB environments where print/exportgraphics
    % or savefig can hang/corrupt files. Default mode is 'pngscreen', which
    % captures the on-screen rendered figure using getframe + imwrite.

    if nargin < 3
        S = struct();
    end

    closeAfter = true;
    saveMode = 'pngscreen';
    if isfield(S,'plot')
        if isfield(S.plot,'closeSavedFigures')
            closeAfter = logical(S.plot.closeSavedFigures);
        end
        if isfield(S.plot,'saveMode')
            saveMode = lower(string(S.plot.saveMode));
        end
    end

    [folder,base,~] = fileparts(filename);
    if ~isempty(folder) && ~exist(folder,'dir')
        mkdir(folder);
    end

    if ~isgraphics(fig)
        return;
    end

    set(fig, 'Color', 'w', 'InvertHardcopy', 'off');
    try
        ax = findall(fig, 'Type', 'axes');
        for ia = 1:numel(ax)
            try, ax(ia).Toolbar.Visible = 'off'; catch, end
            try, disableDefaultInteractivity(ax(ia)); catch, end
        end
    catch
    end

    switch char(saveMode)
        case 'none'
            fprintf('Figure auto-save disabled: %s\n', filename);

        case 'pngscreen'
            pngFile = fullfile(folder, [base '.png']);
            try
                set(fig, 'Visible', 'on');
                drawnow;
                pause(0.08);
                fr = getframe(fig);
                img = fr.cdata;
                if isfield(S,'plot') && isfield(S.plot,'exportScale') && S.plot.exportScale > 1
                    img = imresize(img, S.plot.exportScale, 'bicubic');
                end
                imwrite(img, pngFile);
                fprintf('Saved PNG screen capture: %s\n', pngFile);
            catch ME
                warning('pngscreen export failed for %s: %s', pngFile, ME.message);
            end

        case 'fig'
            figFile = fullfile(folder, [base '.fig']);
            try
                savefig(fig, figFile);
                fprintf('Saved MATLAB figure: %s\n', figFile);
            catch ME
                warning('savefig failed for %s: %s', figFile, ME.message);
            end

        case 'pngpainters'
            pngFile = fullfile(folder, [base '.png']);
            try
                set(fig, 'Visible', 'on');
                set(fig, 'Renderer', 'painters');
                set(fig, 'InvertHardcopy', 'off');
                drawnow;
                exportDPI = 600;
                if isfield(S,'plot') && isfield(S.plot,'exportDPI')
                    exportDPI = S.plot.exportDPI;
                end
                % Prevent MATLAB print() from clipping bottom axis labels or colorbar labels.
                oldUnits = get(fig,'Units');
                set(fig,'Units','centimeters');
                pos = get(fig,'Position');
                set(fig,'PaperUnits','centimeters');
                set(fig,'PaperPositionMode','manual');
                set(fig,'PaperPosition',[0 0 pos(3) pos(4)]);
                set(fig,'PaperSize',[pos(3) pos(4)]);
                print(fig, pngFile, '-dpng', sprintf('-r%d', exportDPI), '-painters');
                set(fig,'Units',oldUnits);
                fprintf('Saved PNG with painters renderer: %s\n', pngFile);
            catch ME
                warning('pngpainters export failed for %s: %s. Falling back to pngscreen.', pngFile, ME.message);
                try
                    set(fig, 'Visible', 'on');
                    drawnow;
                    pause(0.15);
                    fr = getframe(fig);
                    img = fr.cdata;
                    if isfield(S,'plot') && isfield(S.plot,'exportScale') && S.plot.exportScale > 1
                        img = imresize(img, S.plot.exportScale, 'bicubic');
                    end
                    imwrite(img, pngFile);
                    fprintf('Saved PNG screen capture fallback: %s\n', pngFile);
                catch ME2
                    warning('pngscreen fallback also failed for %s: %s', pngFile, ME2.message);
                end
            end

        case 'png'
            pngFile = fullfile(folder, [base '.png']);
            try
                set(fig, 'Visible', 'on');
                drawnow;
                pause(0.08);
                fr = getframe(fig);
                img = fr.cdata;
                if isfield(S,'plot') && isfield(S.plot,'exportScale') && S.plot.exportScale > 1
                    img = imresize(img, S.plot.exportScale, 'bicubic');
                end
                imwrite(img, pngFile);
                fprintf('Saved PNG screen capture: %s\n', pngFile);
            catch ME1
                warning('PNG export failed for %s: %s', pngFile, ME1.message);
            end

        otherwise
            warning('Unknown S.plot.saveMode=%s. Use ''pngscreen'', ''pngpainters'', ''fig'', ''png'', or ''none''.', saveMode);
    end

    if closeAfter && isgraphics(fig)
        close(fig);
    end
end
