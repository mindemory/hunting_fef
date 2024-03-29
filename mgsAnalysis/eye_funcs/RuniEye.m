function [ii_sess] = RuniEye(p, taskMap, end_block, prac_status)

if nargin < 3
    end_block = 10;
end

if nargin < 4
    prac_status = 0;
end

% List of epochs in the task
% XDAT 1: Fixation window =  1s
% XDAT 10: Sample window =  0.5s (would correspond to 'S 11', 'S 12', 'S
% 13', 'S 14' in EEG flags depending on the stimulus VF and block type
% XDAT 2: Delay 1 = 2s
% XDAT 3: Delay 2 = 2s
% XDAT 4: Response window = 0.85s
% XDAT 5: Feedback window = 0.8s
% XDAT 6: ITI window = 2s or 3s (50-50 split)
ifgFile = 'p_1000hz.ifg';
ii_params = ii_loadparams; % load default set of analysis parameters, only change what we have to
ii_params.valid_epochs =[1 2 3 6]; % Updated epochs (Mrugank: 04/05/2023)
ii_params.trial_start_value = 1; %XDAT value for trial start
ii_params.trial_end_value = 6;   % XDAT value for trial end
ii_params.drift_epoch = [1]; % XDAT values for drift correction (
ii_params.drift_fixation_mode  = 'mode';
ii_params.blink_thresh = 0.1;
ii_params.blink_window = [100 100]; % how long before/after blink (ms) to drop?
ii_params.plot_epoch = [1 2 3];  % what epochs do we plot for preprocessing?

% Mrugank (04/05/2023): Could possibly be updated later?
excl_criteria.i_dur_thresh = 850; % must be shorter than 150 ms
excl_criteria.i_amp_thresh = 2;   % must be longer than 5 dva [if FIRST saccade in denoted epoch is not at least this long and at most this duration, drop the trial]
excl_criteria.i_err_thresh = 10;   % i_sacc must be within this many DVA of target pos to consider the trial

excl_criteria.drift_thresh = 2.5;     % if drift correction norm is this big or more, drop
excl_criteria.delay_fix_thresh = 2.5; % if any fixation is this far from 0,0 during delay (epoch 3)

for block = 1:end_block
    disp(['Running block ' num2str(block, '%02d')])
    p.block = [p.dayfolder '/block' num2str(block,'%02d')];
    
    % Loading task, display and timeReport for the block
    matFile_extract = dir(fullfile(p.block, '*.mat'));
    matFile = [p.block filesep matFile_extract(end).name];
    load(matFile);
    parameters = matFile.parameters;
    screen = matFile.screen;
    timeReport = matFile.timeReport;
    trialInfo{block} = timeReport;
    eyecond = taskMap(block).TMScond;
    
    ii_params.resolution = [screen.screenXpixels screen.screenYpixels];
    ii_params.ppd = parameters.viewingDistance * tand(1) / screen.pixSize;
    edfFileName = parameters.edfFile;
    edfFile_original = [p.block filesep edfFileName '.edf'];
    edf_block_fold = [p.save_eyedata '/block' num2str(block, '%02d')];
    if ~exist(edf_block_fold, 'dir')
        mkdir(edf_block_fold);
    end

    edfFile = [edf_block_fold filesep edfFileName '.edf'];
    if ~exist(edfFile, 'file')
        copyfile(edfFile_original, edfFile);
    end
    % what is the output filename?
    preproc_fn = edfFile(1:end-4);
    
    % run preprocessing!
    [ii_data, ii_cfg] = run_iipreproc(edfFile, ifgFile, preproc_fn, ii_params, [], {'calibration'});
    %[ii_data, ii_cfg, ii_sacc] = run_iipreproc(edfFile, ifgFile, preproc_fn, ii_params, []);
    
%     ii_data.XDAT(ii_data.XDAT == 4) = 5;
%     ii_sacc.epoch_start(ii_sacc.epoch_start == 4) = 5;
%     ii_sacc.epoch_end(ii_sacc.epoch_end == 4) = 5;

    % score trials
    % default parameters should work fine - but see docs for other
    % arguments you can/should give when possible
    [ii_trial{block},~] = createTrials(ii_data,ii_cfg,[],3,[],excl_criteria,[],'strict');
    ii_trial{block}.TMScond = taskMap(block).TMScond';
%     [ii_trial{block},~] = ii_scoreMGS(ii_data,ii_cfg,ii_sacc,[],3,[],excl_criteria,[],'strict');
%     if strcmp(eyecond, 'pro')
%         ii_trial{block}.instimVF = taskMap(block).stimVF;
%     elseif strcmp(eyecond, 'anti')
%         ii_trial{block}.instimVF = ~taskMap(block).stimVF;
%     end
%     if prac_status == 0
%         ii_trial{block}.istms = ones(length(taskMap(block).stimVF), 1) * taskMap(block).TMScond;
%     else
%         ii_trial{block}.istms = zeros(length(taskMap(block).stimVF), 1);
%     end
%     ii_trial{block}.ispro = ones(length(taskMap(block).stimVF), 1) * strcmp(eyecond, 'pro');

    clearvars ii_cfg ii_data;
end


%% Combining runs
disp('Combining runs')

% Creating ii_sess only if ii_trial is valid
if ~exist("ii_trial", "var")
    ii_sess = [];
else
    ii_sess = ii_combineruns(ii_trial);

    % Check TMS condition
%     ii_sess.TMS_condition = cell(size(ii_sess.instimVF));
%     ii_sess.TMS_condition(ii_sess.instimVF == 1 & ii_sess.istms == 1) = {'TMS_intoVF'};
%     ii_sess.TMS_condition(ii_sess.instimVF == 0 & ii_sess.istms == 1) = {'TMS_outVF'};
%     ii_sess.TMS_condition(ii_sess.istms == 0) = {'No TMS'};
%     
%     % Check trial-type
%     ii_sess.trial_type = cell(size(ii_sess.instimVF));
%     ii_sess.trial_type(ii_sess.ispro == 1 & ii_sess.instimVF == 1) = {'pro_intoVF'};
%     ii_sess.trial_type(ii_sess.ispro == 1 & ii_sess.instimVF == 0) = {'pro_outVF'};
%     ii_sess.trial_type(ii_sess.ispro == 0 & ii_sess.instimVF == 1) = {'anti_intoVF'};
%     ii_sess.trial_type(ii_sess.ispro == 0 & ii_sess.instimVF == 0) = {'anti_outVF'};
% end
end
