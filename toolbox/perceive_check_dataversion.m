function config = perceive_check_dataversion(js, config)

if isfield(js, 'DataVersion')
    if strcmp(js.DataVersion, '1.2')
        config.DataVersion = 1.2;
    elseif strcmp(js.DataVersion, '1.3')
        warning('DataVersion implentation 1.3 is still in progress, for issues please report to Jojo Vanhoecke (Prof WJ Neumann julian.neumann@charite.de)')
        config.DataVersion = 1.3;
    elseif strcmp(js.DataVersion, '1.4')
        assert(strcmp(js.DataVersion, '1.4'), 'Version implentation until 1.3, contact Jojo Vanhoecke for update')
        config.DataVersion = 1.4;
    end
else % no DataVersion field, so it is the first Version
    config.DataVersion = 0;
end
end