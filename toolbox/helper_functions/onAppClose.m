function onAppClose(app)
    % Mark app as closed
    if isvalid(app.saveandexitButton)
        app.saveandexitButton.UserData = 'closed';
    end

    % SAFETY FIX #2: release any modal dialogs
    figs = findall(0,'Type','figure');
    for k = 1:numel(figs)
        if strcmp(figs(k).WindowStyle,'modal')
            try
                uiresume(figs(k)); % release uiwait
                delete(figs(k));   % close the modal
            catch
                % ignore errors if already closed
            end
        end
    end

    % Finally close the main app
    if isvalid(app)
        delete(app);
    end
end