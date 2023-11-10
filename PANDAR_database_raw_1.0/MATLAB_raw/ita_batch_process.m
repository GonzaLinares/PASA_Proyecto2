function [ result ] = ita_batch_process( data, method, options )
% Function to batch-wise divide in spectrum with regularization
%
% INPUT:
%   - data:                 itaAudio objects with different channels or
%                           multiinstance
%   - method:               cell array with preprocessing function handles
%                           e.g. {'@ita_time_window','@ita_smooth'}
%   - options:              cell array with preprocessing function options
%                           e.g. { {[0.5,0.51]} , {'LogFreqOctave1',1/24,'Abs+Phase'} }
%                           -> the options are encapsulated in a cell for
%                           each processing function
%
% OUTPUT:
%   - result:               processed objects

% Author: Stefan Liebich (IKS) -- Email: liebich@iks.rwth-aachen.de
% Date:  21-Mar-2019

%% Input parsing
if nargin < 3
   options = []; 
end
if nargin < 2
   method = []; 
end

result = data;

%% apply notch smoothing
if ~isempty(method)
    % iterate over different preprocess methods
    for idProcess = 1:numel(method)
        % iterate over different instances
        for idx = 1:numel(result)
            if ~isempty(options)
                curOptions = options{idProcess};
                result(idx) = method{idProcess}(result(idx),curOptions{:});
            else
                result(idx) = method{idProcess}(result(idx));
            end
        end
    end
end



end

