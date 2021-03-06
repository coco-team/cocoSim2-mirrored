%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This file is part of CoCoSim.
% Copyright (C) 2018  The university of Iowa
% Author: Mudathir Mahgoub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ CoCoSimPreferences, modified ] = loadCoCoSimPreferences()
    % check if the preferences mat file is there
    path = fileparts(mfilename('fullpath'));
    preferencesFile = fullfile(path, 'preferences.mat');
    if exist(preferencesFile, 'file') == 2        
        load(preferencesFile, 'CoCoSimPreferences');        
    end
    
    modified = false;
    
    % check if the variable CoCoSimPreferences is defined
    if exist('CoCoSimPreferences', 'var') ~= 1
        CoCoSimPreferences = {};
        modified = true;
    end  
    
    % check if the modelChecker is defined
    if ~ isfield(CoCoSimPreferences,'modelChecker')
        CoCoSimPreferences.modelChecker = 'Kind2';
        modified = true;
    end
    
    % check if irToLustreCompiler is defined
    if ~ isfield(CoCoSimPreferences,'irToLustreCompiler')
        CoCoSimPreferences.irToLustreCompiler = true;
        modified = true;
    end
    % check if compositionalAnalysis is defined
    if ~ isfield(CoCoSimPreferences,'compositionalAnalysis')
        CoCoSimPreferences.compositionalAnalysis = true;
        modified = true;
    end 
    
    % check if kind2Binary is defined
    if ~ isfield(CoCoSimPreferences,'kind2Binary')
        % for windows the web service is the default
        if ispc
            CoCoSimPreferences.kind2Binary = 'Kind2 web service';
        else
            CoCoSimPreferences.kind2Binary = 'Local';
        end
        modified = true;
    end 
    
    % check if verificationTimeout is defined
    if ~ isfield(CoCoSimPreferences,'verificationTimeout')
        CoCoSimPreferences.verificationTimeout = 60; % 60 seconds
        modified = true;
    end 
    
    % save if CoCoSimPreferences is modified
    if modified
        save(preferencesFile, 'CoCoSimPreferences');
    end
end

