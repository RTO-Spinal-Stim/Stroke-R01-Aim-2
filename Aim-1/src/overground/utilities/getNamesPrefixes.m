function [namesPrefixes] = getNamesPrefixes(names, level, delim)

%% PURPOSE: GET THE FIRST N PARTS OF A TRIAL/FILE NAME.
% Inputs:
% names: The cell array of names to get the prefixes of
% level: The number of parts to return
% delim: The delimiter between parts of the name

% Note whether this is a scalar char/not a cell.
isCell = iscell(names) || (~iscell(names) && isstring(names));
if ~isCell
    names = {names};
end

if ~exist('delim','var') || isempty(delim)
    delim = '_';
end

if ~exist('level','var')
    level = 1;
end

namesPrefixes = {};
for i = 1:length(names)
    name = char(names{i});
    nameParts = strsplit(name, delim);
    namePrefix = '';
    for j = 1:level
        namePrefix = [namePrefix delim nameParts{j}];
    end
    namePrefix = namePrefix(2:end);
    if ~ismember(namePrefix, namesPrefixes)
        namesPrefixes = [namesPrefixes; {namePrefix}];
    end
end

if ~isCell
    namesPrefixes = namesPrefixes{1};
end