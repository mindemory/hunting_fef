function mgs_task(subjID, day, start_block, TMSamp, prac_status, anti_type, aperture)
clearvars -except subjID day start_block TMSamp prac_status anti_type aperture;
close all; clc;
% Created by Mrugank Dake, Curtis Lab, NYU (10/11/2022)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize parameters
subjID = num2str(subjID, "%02d"); % convert subjID to string


parameters = loadParameters(subjID);
if nargin < 4
    TMSamp = 0; % default TMS amplitude of 30% MSO
end
if nargin < 5
    prac_status = 0; % 0: actual session, 1: practice session
end
if nargin < 6
    anti_type = 'mirror'; % mirror: mirrored anti conditon, diagonal: diagonal anti condition
end
if nargin < 7
    aperture = 1; % 0: full screen mode, 1: stimulus drawn on aperture
end

eyetrackfeedback = 0;
% Check the system running on: currently accepted: syndrome, tmsubuntu
[ret, hostname] = system('hostname');
if ret ~= 0
    hostname = getenv('HOSTNAME');
end
hostname = strtrim(hostname);

% Initialize PTB and EEG/TMS/Eyetracking parameters
if strcmp(hostname, 'syndrome') || strcmp(hostname, 'zod') || strcmp(hostname, 'zod.psych.nyu.edu') % Lab iMac is meant for debugging
    addpath(genpath('/Users/Shared/Psychtoolbox')) %% mrugank (01/28/2022): load PTB
    parameters.isDemoMode = true; % set to true if you want the screen to be transparent
    parameters.EEG = 0; % set to 0 if there is no EEG recording
    parameters.TMS = 0; % set to 0 if there is no TMS stimulation
    parameters.eyetracker = 0; % set to 0 if there is no eyetracker
    Screen('Preference','SkipSyncTests', 1)
    if prac_status == 1
        end_block = 2; % 2 blocks for practice session
        mgs_data_path = ['/d/DATC/datc/TMS_fef/data/mgs_practice_data/sub' subjID];
    else
        end_block = 10; % 10 blocks for main sessions
        mgs_data_path = ['/d/DATC/datc/TMS_fef/data/mgs_data/sub' subjID];
    end
    tmap_path = '/d/DATC/datc/TMS_fef/taskMap.mat';
elseif strcmp(hostname, 'tmsubuntu') % Running stimulus code for testing
    addpath(genpath('/usr/share/psychtoolbox-3'))
    parameters.isDemoMode = false; %set to true if you want the screen to be transparent
    parameters.TMS = 0; % set to 0 if there is no TMS stimulation
    % Relative paths for tmsubuntu
    curr_dir = pwd; filesepinds = strfind(curr_dir,filesep);
    master_dir = curr_dir(1:(filesepinds(end-1)-1));
    % Path to MarkStim
    trigger_path = [master_dir '/mgs_stimul/EEG_TMS_triggers'];
    addpath(genpath(trigger_path));
    if prac_status == 1
        parameters.EEG = 0; % set to 0 if there is no EEG recording
        end_block = 6; % 6 blocks for practice session
        mgs_data_path = [master_dir '/data/mgs_practice_data/sub' subjID];
    else
        parameters.EEG = 1;
        end_block = 10; % 10 blocks for main sessions
        mgs_data_path = [master_dir '/data/mgs_data/sub' subjID];
    end
    parameters.eyetracker = 1;
    PsychDefaultSetup(1);
else
    disp('Running on unknown device. Psychtoolbox might not be added correctly!')
    return;
end

% Initialize data paths
addpath(genpath(mgs_data_path));

% Load taskMap
load(tmap_path);
if prac_status == 1
    parameters.TMS = 0;
else
    if TMSamp > 0% determine if this is a TMS task
        parameters.TMS = 1;
    else
        parameters.TMS = 0;
    end
end

% Initialize screen and peripherals
screen = initScreen(parameters);
[kbx, parameters] = initPeripherals(parameters);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Open TMS Port
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% detect the MagVenture and perform handshake.
if parameters.TMS > 0
    s = TMS('Open');
    TMS('Enable', s);
    TMS('Timing', s);
    TMS('Amplitude', s, TMSamp);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start Experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for block = start_block:end_block
    if eyetrackfeedback == 1
        eyetrack_errors = struct;
    end
    timeReport = struct;
    parameters.block = num2str(block, "%02d");
    stimLocs = polar2pixel(parameters, taskMap(1, block).polang, screen);

    % Create folders for the block and read taskMap for current block
    if prac_status == 1
        datapath = [mgs_data_path '/day01'];
        parameters = initFiles(parameters, screen, datapath, kbx, block);
    else
        datapath = [mgs_data_path '/day' num2str(day, "%02d")];
        parameters = initFiles(parameters, screen, datapath, kbx, block);
    end
    
    % Get a count of trials (it should be 40 for this experiment).
     trialNum = length(stimLocs);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initialize eyetracker
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    KbQueueFlush(kbx);
    if block == start_block
        while 1
            KbQueueStart(kbx);
            [keyIsDown, ~] = KbQueueCheck(kbx);
            while ~keyIsDown
                showprompts(screen, 'WelcomeWindow', parameters.TMS)
                [keyIsDown, ~] = KbQueueCheck(kbx);
            end
            break;
        end
    end
    
    % Initialize Eye Tracker and perform calibration
    if parameters.eyetracker ~= 0
        if ~parameters.eyeTrackerOn
            ListenChar(0);
            el = initEyeTracker(parameters, screen);
            FlushEvents;
            ListenChar(-1);
        else
            el.eye_used = 1;
            Eyelink('Openfile', parameters.edfFile);
        end
    end
    
    % Init start of experiment procedures
    if parameters.eyetracker
        Eyelink('StartRecording');
        WaitSecs(0.1);
        % synchronize time in edf file
        Eyelink('Message', 'SYNCTIME');
    end
    ListenChar(-1);
    
    % Show Block Start Screen
    if aperture == 1
        drawTextures(parameters, screen, 'Aperture');
    end
    showprompts(screen, 'BlockStart', block)
    WaitSecs(2);
    
    % Draw Fixation Cross
    if aperture == 1
        drawTextures(parameters, screen, 'Aperture');
    end
    drawTextures(parameters, screen, 'FixationCross');
    
    trialArray = 1:trialNum;
    ITI = Shuffle(repmat(parameters.itiDuration, [1 trialNum/2]));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Task Starts
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for trial = trialArray
        disp(['runing block: ' num2str(block, "%02d") ', trial: ' num2str(trial, "%02d")])
        
        % Send trial start to eyetracker
        if parameters.eyetracker
            Eyelink('command', 'record_status_message "TRIAL %i/%i "', ...
                trial, trialNum);
            Eyelink('Message', 'TRIAL %i ', trial);
        end
        
        if trial == 1 % for first trial, pause for 2 seconds
            WaitSecs(2);
        end
        trial_start = GetSecs;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % initial fixation window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        initStartTime = GetSecs;
       
        %record to the edf file that sample is started
        if parameters.eyetracker %&& Eyelink('NewFloatSampleAvailable') > 0
            Eyelink('command', 'record_status_message "TRIAL %i/%i /fixation"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 1);
            Eyelink('Message', 'TarX %s ', num2str(screen.xCenter));
            Eyelink('Message', 'TarY %s ', num2str(screen.yCenter));
        end
        
        % draw fixation cross
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'FixationCross');
        
        if eyetrackfeedback == 1
            % Check for blinks during fixation window
            gxold = screen.xCenter;
            gyold = screen.yCenter;
            fixbreaks = 0;
            while GetSecs-initStartTime < parameters.initDuration * 0.9
                if parameters.eyetracker && el.eye_used~=-1 && Eyelink('NewFloatSampleAvailable') > 0 
                    evt = Eyelink('NewestFloatSample');
                    gx = evt.gx(el.eye_used+1);
                    gy = evt.gy(el.eye_used+1);
                    % In case of blinks or something, make gx and gy back
                    % to center, crude fix
                    if gx==el.MISSING_DATA || gy==el.MISSING_DATA || evt.pa(el.eye_used+1)<=0
                        gx = screen.xCenter;
                        gy = screen.yCenter;
                    end

                    % see if there was a fixation break
                    if (gx~=gxold || gy~=gyold)
                        va_now = pixel2va(gx, gy, screen.xCenter, screen.yCenter, parameters, screen);
                        if va_now > parameters.fixbreakthresh
                            fixbreaks = fixbreaks+1;
                        end
                    end
                    gxold = gx;
                    gyold = gy;
                end
            end
            eyetrack_errors.fixation(trial) = fixbreaks;
            clearvars gx gy gxold gyold evt fixbreaks
        end
        
        if GetSecs - initStartTime < parameters.initDuration
            WaitSecs(parameters.initDuration - (GetSecs-initStartTime));
        end
        timeReport.initDuration(trial) = GetSecs-initStartTime;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % sample window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sampleStartTime = GetSecs;
        %record to the edf file that sample is started
        if parameters.eyetracker %&& Eyelink('NewFloatSampleAvailable') > 0
            Eyelink('command', 'record_status_message "TRIAL %i/%i /sample"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 2);
            Eyelink('Message', 'TarX %s ', num2str(screen.xCenter));
            Eyelink('Message', 'TarY %s ', num2str(screen.yCenter));
        end
        
        % draw sample and fixation cross
        dotCenter = stimLocs(trial, :);
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'Stimulus', screen.white, dotCenter);
        drawTextures(parameters, screen, 'FixationCross');
        
        if eyetrackfeedback == 1
            % Check for blinks during sample window
            gxold = screen.xCenter;
            gyold = screen.yCenter;
            fixbreaks = 0;
            while GetSecs-sampleStartTime < parameters.sampleDuration * 0.9
                if parameters.eyetracker && el.eye_used~=-1 && Eyelink('NewFloatSampleAvailable') > 0 
                    evt = Eyelink('NewestFloatSample');
                    gx = evt.gx(el.eye_used+1);
                    gy = evt.gy(el.eye_used+1);
                    % In case of blinks or something, make gx and gy back
                    % to center, crude fix
                    if gx==el.MISSING_DATA || gy==el.MISSING_DATA || evt.pa(el.eye_used+1)<=0
                        gx = screen.xCenter;
                        gy = screen.yCenter;
                    end

                    % see if there was a fixation break
                    if (gx~=gxold || gy~=gyold)
                        va_now = pixel2va(gx, gy, screen.xCenter, screen.yCenter, parameters, screen);
                        if va_now > parameters.fixbreakthresh
                            fixbreaks = fixbreaks + 1;
                        end
                    end
                    gxold = gx;
                    gyold = gy;
                end
            end
            eyetrack_errors.sample(trial) = fixbreaks;
            clearvars gx gy gxold gyold evt fixbreaks
        end
        
        if GetSecs - sampleStartTime < parameters.sampleDuration
            WaitSecs(parameters.sampleDuration - (GetSecs-sampleStartTime));
        end
        timeReport.sampleDuration(trial) = GetSecs-sampleStartTime;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Delay1 window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        delay1StartTime = GetSecs;
        
        %record to the edf file that delay1 is started
        if parameters.eyetracker %&& Eyelink('NewFloatSampleAvailable') > 0
            Eyelink('command', 'record_status_message "TRIAL %i/%i /delay1"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 3);
        end

        % Draw fixation cross
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'FixationCross');

        d1_dur = parameters.delay1Duration;
        if eyetrackfeedback == 1
            % Check for blinks during delay1 window
            gxold = screen.xCenter;
            gyold = screen.yCenter;
            fixbreaks = 0;

            while GetSecs-delay1StartTime < d1_dur * 0.9
                if parameters.eyetracker && el.eye_used~=-1 && Eyelink('NewFloatSampleAvailable') > 0 
                    evt = Eyelink('NewestFloatSample');
                    gx = evt.gx(el.eye_used+1);
                    gy = evt.gy(el.eye_used+1);
                    % In case of blinks or something, make gx and gy back
                    % to center, crude fix
                    if gx==el.MISSING_DATA || gy==el.MISSING_DATA || evt.pa(el.eye_used+1)<=0
                        gx = screen.xCenter;
                        gy = screen.yCenter;
                    end

                    % see if there was a fixation break
                    if (gx~=gxold || gy~=gyold)
                        va_now = pixel2va(gx, gy, screen.xCenter, screen.yCenter, parameters, screen);
                        if va_now > parameters.fixbreakthresh
                            fixbreaks = fixbreaks + 1;
                        end
                    end
                    gxold = gx;
                    gyold = gy;
                end
            end

            eyetrack_errors.delay1(trial) = fixbreaks;
            clearvars gx gy gxold gyold evt fixbreaks
        end

        if GetSecs - delay1StartTime < d1_dur
            WaitSecs(d1_dur - (GetSecs-delay1StartTime));
        end
        timeReport.delay1Duration(trial) = GetSecs - delay1StartTime;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Delay2 window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        delay2StartTime = GetSecs;
        
        if parameters.TMS
            TMS('Train', s); % Train of TMS pulses, set pulse protocol on MagVenture Timing page
        end
        
        %record to the edf file that noise mask is started
        if parameters.eyetracker 
            Eyelink('command', 'record_status_message "TRIAL %i/%i /delay2"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 4);
        end
        
        % Draw fixation cross
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'FixationCross');

        % Get the second delay duration, dependent on day
        d2_dur = parameters.delay2Duration;
        if eyetrackfeedback == 1
            % Check for blinks during delay1 window
            gxold = screen.xCenter;
            gyold = screen.yCenter;
            fixbreaks = 0;
            while GetSecs-delay2StartTime < d2_dur * 0.9
                if parameters.eyetracker && el.eye_used~=-1 && Eyelink('NewFloatSampleAvailable') > 0 
                    evt = Eyelink('NewestFloatSample');
                    gx = evt.gx(el.eye_used+1);
                    gy = evt.gy(el.eye_used+1);
                    % In case of blinks or something, make gx and gy back
                    % to center, crude fix
                    if gx==el.MISSING_DATA || gy==el.MISSING_DATA || evt.pa(el.eye_used+1)<=0
                        gx = screen.xCenter;
                        gy = screen.yCenter;
                    end

                    % see if there was a fixation break
                    if (gx~=gxold || gy~=gyold)
                        va_now = pixel2va(gx, gy, screen.xCenter, screen.yCenter, parameters, screen);
                        if va_now > parameters.fixbreakthresh
                            fixbreaks = fixbreaks + 1;
                        end
                    end
                    gxold = gx;
                    gyold = gy;
                end
            end
            eyetrack_errors.delay2(trial) = fixbreaks;
            clearvars gx gy gxold gyold evt fixbreaks
        end
        
        if GetSecs - delay2StartTime < d2_dur
            WaitSecs(d2_dur - (GetSecs - delay2StartTime));
        end
        timeReport.delay2Duration(trial) = GetSecs - delay2StartTime;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Response window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        respStartTime = GetSecs;
        
        saccLoc = stimLocs(trial, :);
        %record to the edf file that response cue is started
        if parameters.eyetracker
            Eyelink('command', 'record_status_message "TRIAL %i/%i /response"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 5);
            Eyelink('Message', 'TarX %s ', num2str(saccLoc(1)));
            Eyelink('Message', 'TarY %s ', num2str(saccLoc(2)));
        end
        % Draw green fixation cross
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'FixationCross', parameters.cuecolor);
        
        if eyetrackfeedback == 1
            % Check for blinks during delay1 window
            gxold = screen.xCenter;
            gyold = screen.yCenter;
            saccOnset = parameters.respDuration; % in case no saccade was made
            while GetSecs-respStartTime < parameters.respDuration * 0.9
                if parameters.eyetracker && el.eye_used~=-1 && Eyelink('NewFloatSampleAvailable') > 0 
                    evt = Eyelink('NewestFloatSample');
                    gx = evt.gx(el.eye_used+1);
                    gy = evt.gy(el.eye_used+1);
                    % In case of blinks or something, make gx and gy back
                    % to center, crude fix
                    if gx==el.MISSING_DATA || gy==el.MISSING_DATA || evt.pa(el.eye_used+1)<=0
                        gx = screen.xCenter;
                        gy = screen.yCenter;
                    end

                    % see if there was a fixation break
                    if (gx~=gxold || gy~=gyold)
                        va_now = pixel2va(gx, gy, screen.xCenter, screen.yCenter, parameters, screen);
                        if va_now > parameters.fixbreakthresh
                            saccOnset = GetSecs - respStartTime;
                            break;
                        end
                    end
                    gxold = gx;
                    gyold = gy;
                end
            end
            eyetrack_errors.response(trial) = saccOnset;
            clearvars gx gy gxold gyold evt saccOnset
        end
        
        if GetSecs - respStartTime < parameters.respDuration
            WaitSecs(parameters.respDuration - (GetSecs - respStartTime));
        end
        timeReport.respDuration(trial) = GetSecs - respStartTime;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Feedback window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        feedbackStartTime = GetSecs;
        
        %record to the edf file that feedback is started
        if parameters.eyetracker 
            Eyelink('command', 'record_status_message "TRIAL %i/%i /feedback"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 6);
        end
        
        % Get the size and location of dot
        dotCenter = stimLocs(trial, :);
        
        % draw the fixation dot
        % Render stimulus
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'Stimulus', parameters.feebackcolor, dotCenter);
        drawTextures(parameters, screen, 'FixationCross');
        
        if eyetrackfeedback == 1
            % Check for blinks during delay1 window
            gxold = screen.xCenter;
            gyold = screen.yCenter;
            sacc_errs = [];
            while GetSecs-feedbackStartTime < parameters.feedbackDuration * 0.9
                if parameters.eyetracker && el.eye_used~=-1 && Eyelink('NewFloatSampleAvailable') > 0 
                    evt = Eyelink('NewestFloatSample');
                    gx = evt.gx(el.eye_used+1);
                    gy = evt.gy(el.eye_used+1);
                    % In case of blinks or something, make gx and gy back
                    % to center, crude fix
                    if gx==el.MISSING_DATA || gy==el.MISSING_DATA || evt.pa(el.eye_used+1)<=0
                        gx = screen.xCenter;
                        gy = screen.yCenter;
                    end

                    % see if there was a fixation break
                    if (gx~=gxold || gy~=gyold)
                        va_now = pixel2va(gx, gy, saccLoc(1), saccLoc(2), parameters, screen);
                        sacc_errs = [sacc_errs va_now];
                    end
                    gxold = gx;
                    gyold = gy;
                end
            end
            if ~isempty(sacc_errs)
                eyetrack_errors.feedback_min(trial) = min(sacc_errs);
                eyetrack_errors.feedback_max(trial) = max(sacc_errs);
                eyetrack_errors.feedback_avg(trial) = mean(sacc_errs);
                eyetrack_errors.feedback_first(trial) = sacc_errs(1);
            else
                eyetrack_errors.feedback_min(trial) = NaN;
                eyetrack_errors.feedback_max(trial) = NaN;
                eyetrack_errors.feedback_avg(trial) = NaN;
                eyetrack_errors.feedback_first(trial) = NaN;
            end
            clearvars gx gy gxold gyold evt sacc_errs ctr
        end

        if GetSecs - feedbackStartTime < parameters.feedbackDuration
            WaitSecs(parameters.feedbackDuration - (GetSecs - feedbackStartTime));
        end
        timeReport.feedbackDuration(trial) = GetSecs-feedbackStartTime;
        
        if parameters.eyetracker
            Eyelink('Message', 'TRIAL_RESULT  0')
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Intertrial window
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        itiStartTime = GetSecs;
        
        %record to the edf file that iti is started
        if parameters.eyetracker 
            Eyelink('command', 'record_status_message "TRIAL %i/%i /iti"', trial, trialNum);
            Eyelink('Message', 'XDAT %i ', 7);
            Eyelink('Message', 'TarX %s ', num2str(screen.xCenter));
            Eyelink('Message', 'TarY %s ', num2str(screen.yCenter));
        end
        % Draw a fixation cross
        if aperture == 1
            drawTextures(parameters, screen, 'Aperture');
        end
        drawTextures(parameters, screen, 'FixationCrossITI');
        
        if GetSecs - itiStartTime < ITI(trial)
            WaitSecs(ITI(trial) - (GetSecs - itiStartTime));
        end
        
        timeReport.itiDuration(trial) = GetSecs - itiStartTime;
        timeReport.trialDuration(trial) = GetSecs-sampleStartTime;
    end
    
    %% Saving Data and Closing everything
    % stop eyelink and save eyelink data
    showprompts(screen, 'BlockEnd', block)
    Beeper('med',0.5,0.1)
    
    if parameters.eyetracker
        Eyelink('StopRecording');
        Eyelink('ReceiveFile', parameters.edfFile);
        copyfile([parameters.edfFile '.edf'], [parameters.block_dir filesep parameters.edfFile '.edf']);
        Eyelink('Shutdown');
        disp(['Eyedata recieve for ' num2str(block,"%02d") ' OK!']);
    end    
    
    % save timeReport
    matFile.parameters = parameters;
    matFile.screen = screen;
    matFile.timeReport = timeReport;
    save([parameters.block_dir filesep parameters.matFile],'matFile')

    % Save Eyetrack errors
    if eyetrackfeedback == 1
        save([parameters.block_dir filesep parameters.eyeErrorFile],'eyetrack_errors')
        fixbreaks = sum((eyetrack_errors.sample+eyetrack_errors.delay1+eyetrack_errors.delay2) > 0);
        resplate = sum(eyetrack_errors.response >= 0.8);
        disp(['Fixation breaks = ' num2str(fixbreaks) ' trials.']);
        disp(['Slow response = ' num2str(resplate) ' trials.']);
    end

    % check for end of block
    KbQueueFlush(kbx);
    [keyIsDown, ~] = KbQueueCheck(kbx);
    while ~keyIsDown
        showprompts(screen, 'ContinueorEsc', block)
        [keyIsDown, keyCode] = KbQueueCheck(kbx);
        cmndKey = KbName(keyCode);
    end
    
    if strcmp(cmndKey, parameters.space_key)
        continue;
    elseif strcmp(cmndKey, parameters.exit_key)
        % end Teensy handshake
        if parameters.TMS
            TMS('Disable', s);
            TMS('Close', s);
        end
        showprompts(screen, 'EndExperiment');
        WaitSecs(2);
        ListenChar(1);
        sca;
        return;
    end
end % end of block

% Close TMS Port and End Experiment
if parameters.TMS
    TMS('Disable', s);
    TMS('Close', s);
end
showprompts(screen, 'EndExperiment');
ListenChar(1);
WaitSecs(2);
sca;
Priority(0);
end