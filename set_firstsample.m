function firstsample = set_firstsample(string_of_TicksInMses)

    parts = strsplit(string_of_TicksInMses, ',');

    % extract the first part and convert it to a number

    firstsample = str2num(parts{1});
    warning('firstsample is no longer divided by 50')
    if isempty(firstsample)
        firstsample=1;
    end

end