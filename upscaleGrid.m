
function B = upscaleGrid(A,vec,method)
% B = upscaleGrid(A,vec [,method]);
% Value of each grid in B is the mean/median/majority of corresponding smaller grids in A
%
% input
%   A, a numeric matrix
%   vec, the scale between 0 and 1 or [numRows numCols] of the output variable
%   method, 'mean'(default), 'median' or 'mode'('majority')
% output
%   B, the output matrix, has smaller size than A
%
% the scales along row and column should be same (or very close) if the user
% defines [numRows numCols] of the new matrix.
%
% 2018/08/01, written by Gongxue Wang (wanggx@mail.bnu.edu.cn)
% 2018/08/31, method added.
% 2019/06/05, for non-integral multiples of pixel size
% 2019/08/12, 3d data
%

% validate variables
validateattributes(A, ...
    {'numeric'}, {'3d','nonempty','nonsparse'}, mfilename,'A',1)
s = size(A);
LargerSize = s(1:2);

if isscalar(vec)
    validateattributes(vec, ...
        {'numeric'}, {'nonempty','>',0,'<',1}, mfilename,'vec',2)
    smallerSize = ceil(LargerSize*vec);
else
    validateattributes(vec, ...
        {'numeric'}, {'2d','numel',2,'nonempty','>',0}, mfilename,'vec',2)
    smallerSize = ceil(vec) ;
    assert(smallerSize(1)<LargerSize(1)&&smallerSize(2)<LargerSize(2),'input smaller size')
end

if nargin<3
    method = 'mean';
else
    method = validatestring(method,{'mean','median','mode'},mfilename,'method',3);
end

scale = LargerSize./smallerSize;
reciScale = scale;

ind = mod(scale,1)> 0.1;
reciScale(ind) = ceil(scale(ind));
reciScale(~ind) = floor(scale(~ind));

enlargeSize = reciScale.*smallerSize;

switch method
    case 'mean'
        fun = @(block_struct) mean(block_struct.data(:),'omitnan');
    case 'median'
        fun = @(block_struct) median(block_struct.data(:),'omitnan');
    case 'mode'
        fun = @(block_struct) mode(block_struct.data(:));
end

p = gcp('nocreate'); % If no pool, do not create new one.
if isempty(p)
    UseParallel = false;
else
    UseParallel = true;
end

if ismatrix(A)
enlargeA = imresize(A,enlargeSize,'nearest');
B = blockproc(enlargeA,reciScale,fun,'UseParallel',UseParallel);
else
    nSize = [enlargeSize,size(A,3)];
    enlargeA = imresize3(A,nSize,'nearest');
    B = nan(nSize);
    for i=1:size(A,3)
        temp = blockproc(enlargeA(:,:,i),reciScale,fun,'UseParallel',UseParallel);
        B(:,:,i)=temp;
    end
end
