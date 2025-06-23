function result = perceive_updateAcq(inputStr, mytext)
    % Replace any 'acq-' followed by characters and an underscore with 'acq-mytext_'
    result = regexprep(inputStr, 'acq-[^_]*_', ['acq-' mytext '_']);
end
