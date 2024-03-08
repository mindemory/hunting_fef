function [ii_trial,ii_cfg] = createTrials(ii_data,ii_cfg,targ_coords,resp_epoch,fix_epoch,excl_criteria,save_chans,score_mode,align_to)
which_chans = {'X', 'Y'};
save_chans = {which_chans{:},'Pupil','XDAT'};
for chan_idx = 1:length(save_chans)
    ii_trial.(save_chans{chan_idx}) = cell(ii_cfg.numtrials,1);
end

% also want to store the raw coordinates
ii_trial.i_sacc_raw = nan(ii_cfg.numtrials,2);
ii_trial.f_sacc_raw = nan(ii_cfg.numtrials,2);

% aligned coordinates
ii_trial.i_sacc = nan(ii_cfg.numtrials,2);
ii_trial.f_sacc = nan(ii_cfg.numtrials,2);


ii_trial.i_sacc_err = nan(ii_cfg.numtrials,1);
ii_trial.f_sacc_err = nan(ii_cfg.numtrials,1);

ii_trial.n_sacc = nan(ii_cfg.numtrials,1); % how many saccades are there total? (in each epoch maybe?)
ii_trial.n_sacc_epoch = nan(ii_cfg.numtrials,5); % TODO: fill this w/ n_trials x n_epochs (exclude ITI)

ii_trial.i_sacc_rt = nan(ii_cfg.numtrials,1); % latency from go cue to each of these
ii_trial.f_sacc_rt = nan(ii_cfg.numtrials,1);

ii_trial.i_sacc_trace = cell(ii_cfg.numtrials,1);
ii_trial.f_sacc_trace = cell(ii_cfg.numtrials,1);

ii_trial.i_sacc_peakvel = nan(ii_cfg.numtrials,1);
ii_trial.f_sacc_peakvel = nan(ii_cfg.numtrials,1);

% save some calibration, drift correction info for convenience
if isfield(ii_cfg,'calibrate')
    ii_trial.calib_amt = ii_cfg.calibrate.amt;
    ii_trial.calib_adj = ii_cfg.calibrate.adj;
    ii_trial.calib_err = ii_cfg.calibrate.err;
end

if isfield(ii_cfg,'drift')
    ii_trial.drift_amt = ii_cfg.drift.amt;
end

ii_trial.excl_trial = cell(ii_cfg.numtrials,1);  % why is this trial excluded? each cell includes several markers


% let's copy over ii_cfg.trialinfo, if it exists
if isfield(ii_cfg,'trialinfo')
    ii_trial.trialinfo = ii_cfg.trialinfo;
end

% add parameters used for extracting saccades: ii_trial.params (as they
% were input/sanitized - but, for e.g., targ_coord, not updated [?])
ii_trial.params.excl_criteria = excl_criteria;
ii_trial.params.resp_epoch  = resp_epoch;
ii_trial.params.fix_epoch   = fix_epoch;
ii_trial.params.targ_coords = targ_coords;
ii_trial.params.save_chans  = save_chans;
ii_trial.params.score_mode  = score_mode;
ii_trial.params.score_chans = which_chans; % the two channels that were used for scoring

%% loop over trials
for tt = 1:ii_cfg.numtrials
    
    % save the data from each channel from each trial
    for chan_idx = 1:length(save_chans)
        ii_trial.(save_chans{chan_idx}){tt} = ii_data.(save_chans{chan_idx})(ii_cfg.trialvec==tt);
    end
    
    % time that relevant epoch of trial started
    t_start = find(ii_cfg.trialvec==tt & ismember(ii_data.XDAT,resp_epoch) ,1,'first')/ii_cfg.hz; 

    %% trial exclusions: find reasons we may want to exclude each trial
    
    % ~~~~~ FIRST: exclude based on trial-level features (see above)
    
    % note: only reject trials based on these criteria if those steps were
    % run!
    
    % DRIFT CORRECTION TOO BIG
    if isfield(ii_cfg,'drift')
        if sqrt(sum(ii_cfg.drift.amt(tt,:).^2)) > excl_criteria.drift_thresh
            ii_trial.excl_trial{tt}(end+1) = 11;
        end
    end
    
    % CALIBRATION OUTSIDE OF RANGE
    if isfield(ii_cfg,'calibrate')
        if ii_cfg.calibrate.adj(tt)~=1
            ii_trial.excl_trial{tt}(end+1) = 12;
        end
    end
    
    % DURING DELAY, FIXATION OUTSIDE OF RANGE
    
    % find fixations in this trial; epoch [TODO: make sure I'm using the
    % right channels here!!]
    this_fix_idx = ii_cfg.trialvec==tt & ismember(ii_data.XDAT,fix_epoch);
    if max(sqrt(ii_data.X_fix(this_fix_idx).^2+ii_data.Y_fix(this_fix_idx).^2)) > excl_criteria.delay_fix_thresh
        ii_trial.excl_trial{tt}(end+1) = 13;
    end
end

end