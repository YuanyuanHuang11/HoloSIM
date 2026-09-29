function PSI_safeSaveFigure(fig, filename, S)
    % High-quality figure saving.
    % Preferred mode, S.plot.saveMode = 'pnghighres', uses exportgraphics()
    % at S.plot.exportDPI. This gives true high-resolution PNG output and
    % avoids the low-resolution blur from getframe/pngscreen saving.

    if nargin < 3
        S = struct();
    end

    closeAfter = true;
    saveMode = 'pnghighres';
    exportDPI = 1200;
    exportScale = 3.0;
    savePDF = false;

    if isfield(S,'plot')
        if isfield(S.plot,'closeSavedFigures')
            closeAfter = logical(S.plot.closeSavedFigures);
        end
        if isfield(S.plot,'saveMode')
            saveMode = lower(string(S.plot.saveMode));
        end
        if isfield(S.plot,'exportDPI')
            exportDPI = S.plot.exportDPI;
        end
        if isfield(S.plot,'exportScale')
            exportScale = S.plot.exportScale;
        end
        if isfield(S.plot,'savePDF')
            savePDF = logical(S.plot.savePDF);
        end
    end

    [folder,base,~] = fileparts(filename);
    if ~isempty(folder) && ~exist(folder,'dir')
        mkdir(folder);
    end

    if ~isgraphics(fig)
        return;
    end

    pngFile = fullfile(folder, [base '.png']);
    pdfFile = fullfile(folder, [base '.pdf']);

    set(fig, 'Color', 'w', 'InvertHardcopy', 'off');
    set(fig, 'PaperPositionMode', 'auto');

    try
        ax = findall(fig, 'Type', 'axes');
        for ia = 1:numel(ax)
            try, ax(ia).Toolbar.Visible = 'off'; catch, end
            try, disableDefaultInteractivity(ax(ia)); catch, end
        end
    catch
    end

    % Make sure all layout, manual frame lines, legends, and colorbars have
    % been rendered before export.
    try
        set(fig, 'Visible', 'on');
    catch
    end
    drawnow;
    pause(0.05);

    switch char(saveMode)
        case 'none'
            fprintf('Figure auto-save disabled: %s\n', filename);

        case 'pnghighres'
            saved = false;

            % Best option for modern MATLAB: true DPI export based on figure
            % physical size. For example, 18 cm at 1200 dpi gives ~8500 px.
            try
                exportgraphics(fig, pngFile, ...
                    'Resolution', exportDPI, ...
                    'BackgroundColor', 'white');
                fprintf('Saved high-resolution PNG with exportgraphics: %s\n', pngFile);
                saved = true;
            catch ME1
                warning('exportgraphics failed for %s: %s. Trying print().', pngFile, ME1.message);
            end

            % Fallback for older MATLAB versions.
            if ~saved
                try
                    set(fig, 'Renderer', 'opengl');
                    print(fig, pngFile, '-dpng', sprintf('-r%d', exportDPI), '-opengl');
                    fprintf('Saved high-resolution PNG with print: %s\n', pngFile);
                    saved = true;
                catch ME2
                    warning('print high-res export failed for %s: %s. Falling back to pngscreen.', pngFile, ME2.message);
                end
            end

            % Last fallback. This is not preferred because it captures screen
            % pixels first, then upsamples them.
            if ~saved
                try
                    fr = getframe(fig);
                    img = fr.cdata;
                    if exportScale > 1
                        img = imresize(img, exportScale, 'bicubic');
                    end
                    imwrite(img, pngFile);
                    fprintf('Saved PNG screen-capture fallback: %s\n', pngFile);
                catch ME3
                    warning('pngscreen fallback failed for %s: %s', pngFile, ME3.message);
                end
            end

            % Optional vector PDF copy for curve-only figures. For image-heavy
            % figures, the PNG is usually the safer manuscript file.
            if savePDF
                try
                    exportgraphics(fig, pdfFile, ...
                        'ContentType', 'vector', ...
                        'BackgroundColor', 'white');
                    fprintf('Saved vector PDF: %s\n', pdfFile);
                catch ME4
                    warning('PDF export failed for %s: %s', pdfFile, ME4.message);
                end
            end

        case 'pngscreen'
            try
                fr = getframe(fig);
                img = fr.cdata;
                if exportScale > 1
                    img = imresize(img, exportScale, 'bicubic');
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

        case 'png'
            try
                imwrite(getframe(fig).cdata, pngFile);
                fprintf('Saved PNG: %s\n', pngFile);
            catch ME
                warning('PNG export failed for %s: %s', pngFile, ME.message);
            end

        otherwise
            warning('Unknown S.plot.saveMode=%s. Use ''pnghighres'', ''pngscreen'', ''fig'', ''png'', or ''none''.', saveMode);
    end

    if closeAfter && isgraphics(fig)
        close(fig);
    end
end
