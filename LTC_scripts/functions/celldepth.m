function d = celldepth(c)
    if ~iscell(c)
        d = 0;
    else
        d = 1 + max(cellfun(@celldepth, c));
    end
end