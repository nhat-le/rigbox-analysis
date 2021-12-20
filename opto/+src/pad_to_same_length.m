function padded = pad_to_same_length(cellarr, varargin)
% pass varargin if cells are 2d arrays and we need to select a column
% in each cell

if numel(varargin) == 1
    idx = varargin{1};
    maxlen = max(cellfun(@(x) size(x, 1), cellarr));
else
    idx = nan;
    maxlen = max(cellfun(@(x) numel(x), cellarr));
end
padded = nan(numel(cellarr), maxlen);
for i = 1:numel(cellarr)
    if isnan(idx)
        padded(i,1:numel(cellarr{i})) = cellarr{i};
    else
        padded(i,1:size(cellarr{i},1)) = cellarr{i}(:,idx);
    end
end