function [p, taskMap] = initialization(p, analysis_type, prac_status)

% Adding all the folders and the helper function
tmp = pwd; tmp2 = strfind(tmp,filesep);
p.master = tmp(1:(tmp2(end)-1));
addpath(genpath(p.master)); 

% Check the system running on: currently accepted: syndrome and my macbook
[ret, hostname] = system('hostname');
if ret ~= 0
    hostname = getenv('HOSTNAME');
end
p.hostname = strtrim(hostname);

% Initialize all the paths
if strcmp(p.hostname, 'syndrome') || strcmp(p.hostname, 'vader') || strcmp(p.hostname, 'thanos') || ...
        strcmp(p.hostname, 'zod') || strcmp(p.hostname, 'zod.psych.nyu.edu') || strcmp(p.hostname, 'loki.psych.nyu.edu')% If running on Syndrome or Vader or Zod
    p.datc = '/d/DATC/datc/TMS_fef';
else % If running on World's best MacBook
    p.datc = '/Users/mrugankdake/Documents/Clayspace/EEG_TMS/datd/MD_TMS_EEG';
end
p.data = [p.datc '/data_express'];
addpath(genpath(p.data));

if prac_status == 1
    p.task = [p.data '/expressSacc_practice_data/sub' p.subjID];
    p.analysis = [p.datc '/analysis/practice'];
else
    p.task = [p.data '/expressSacc_data/sub' p.subjID];
    p.analysis = [p.datc '/analysis'];
end
addpath(genpath(p.analysis));
p.dayfolder = [p.task '/day' num2str(p.day, '%02d')];

taskMapfileName = [p.datc '/express_taskMap.mat'];
load(taskMapfileName);
p.tmsstatus = 1;

% Folder to save analysis data
p.save = [p.analysis '/sub' p.subjID '/day' num2str(p.day, '%02d')];
p.save_eyedata = [p.save '/EyeData'];
if ~exist(p.save, 'dir')
    mkdir(p.save);
end

% Add toolbox to path (either iEye or fieldtrip)
if strcmp(analysis_type, 'eye')
    p.iEye = '/d/DATA/hyper/experiments/Mrugank/TMS/mgs_stimul/iEye';
    addpath(genpath(p.iEye));
end
end