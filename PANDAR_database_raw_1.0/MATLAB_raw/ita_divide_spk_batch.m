function [ result ] = ita_divide_spk_batch( data, divide_pair, divide_names, boundsRegularization, preprocessMethod, preprocessOptions )
% Function to batch-wise divide in spectrum with regularization
%
% INPUT:
%   - multiinstance_ita:    multiinstance of ita objects containing the
%                           channels to divide in the various instances
%   - divide_pair_vector:   determines which channels should be divided
%                           vector with size [#divisions x 2]
%                           e.g. [1,3; 1,4; 2,3; 2,4]
%   - boundsRegularization: contains the bounds in Hz for regularization
%   - divide_names:         cell vector with channel names for division result
%                           e.g. 'primary path'
%   - preprocessMethod:    	cell array with preprocessing function handles
%                           e.g. {'@ita_time_window','@ita_smooth'}
%   - preprocessOptions:    cell array with preprocessing function options
%                           e.g. { {[0.5,0.51]} , {'LogFreqOctave1',1/24,'Abs+Phase'} }
%                           -> the options are encapsulated in a cell for
%                           each processing function
%
% OUTPUT:
%   - result:               contains the divided results as multiple
%                           instances
%                           e.g. [#1/#3, #1/#4, #2/#3, #2/#4]

% Author: Stefan Liebich (IKS) -- Email: liebich@iks.rwth-aachen.de
% Date:  21-Jan-2019

%% Input parsing
if nargin < 6
   preprocessOptions = []; 
end
if nargin < 5
   preprocessMethod = []; 
end
if nargin < 4
   boundsRegularization = []; 
end
if nargin < 3
   divide_names = []; 
end

numDivisions = size(divide_pair,1);
if( size(divide_pair,2) ~= 2 )
   error('divide_pair_vector not specified correctly');
end

local = data;

% determine channel of interest: only process those ones
instInterest = unique(divide_pair(:));

%% apply notch smoothing
if ~isempty(preprocessMethod)
    % iterate over different preprocess methods
    for idProcess = 1:numel(preprocessMethod)
        % iterate over different instances
        for idx = 1:numel(instInterest)
            curOptions = preprocessOptions{idProcess};
            local(instInterest(idx)) = preprocessMethod{idProcess}(local(instInterest(idx)),curOptions{:});
        end
    end
end

%% apply algorithms
for idx = 1:numDivisions
    if( isempty(boundsRegularization) )
        result(idx)  = ita_divide_spk(local(divide_pair(idx,1)),local(divide_pair(idx,2)));
    else
        result(idx)  = ita_divide_spk(local(divide_pair(idx,1)),local(divide_pair(idx,2)),'regularization',boundsRegularization);
    end
    if( ~isempty(divide_names) )
        result(idx).channelNames(:) = divide_names(idx);
        result(idx).comment = divide_names{idx};
    end
end


end

