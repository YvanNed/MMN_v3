function MMN_Duration_LongDiff
% =========================================================================
% created by: YN. 23/06/2020
% last Update: YN. 23/06/2020
% =========================================================================
%% Description
% basic passive MMN duration with at least 1 standards (o) between a deviant (x)
% o o o x o x o o o x o o o x ...
% =========================================================================
% Here we increased the duration of the stimuli but we kept the ratio between std and dev.
% total duration of MMN is ~19min.
% =========================================================================

clear all; 
clc;
AddPsychJavaPath;

global w
global screenRect
global pahandle
global FIX_HEIGHT 
global FIX_WIDTH 
global FIX_COLOR 
global ifi 
global ESC_KEY
global USE_EEG 

ESC_KEY  ='ESCAPE';                                                         % key value returned by KbName|exit
KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');

EEG = input('Are you using EEG? (0/1)');
if EEG == 1
    USE_EEG = true;
else 
    USE_EEG = false;
end
 
try 
    %----------------- Start the PsychToolBox sound driver ----------------
    %----------------------------------------------------------------------
    disp('InitializePsychSound')
    InitializePsychSound(1)                                                 % (1) to specify needlowlatency argument
    GetSecs;                                                                % pre-load GetSecs if you want to use it later on your code
    nrchannels = 2;                                                         % 2 channels for left and right (binaural sound presentation)
    pahandle = PsychPortAudio('Open', [], [], 2, [], nrchannels, [], []);  
    % the 4th parameter is the request latency mode. 
    % 1: Try to get the lowest latency% that is possible under the constraint of reliable playback, freedom of choice for all parameters and interoperability with other applications.
    % 2: Take full control over the audio device, even if this causes other sound applications to fail or shutdown.
    % 3: As level 2, but request the most aggressive settings for the given device.
    % 4: Same as 3, but fail if device can't meet the strictest requirements.
    % The 5th parameter is 'freq'. It can be change by sf if the sampling rate supported by the device is already known !
    
    PsychPortAudio('Verbosity',5);                                          % set the Verbosity level
    PsychPortAudio('Volume', pahandle, .6);                                 % adjust volume, this migth need to be adjusted on your device
    s = PsychPortAudio('GetStatus', pahandle);                              % get status of the device pahandle
    sf = s.SampleRate;                                                      % get the sampling frequency of your device
    %----------------------------------------------------------------------
    
    %------------------------ Initialize Screen info ----------------------
    %----------------------------------------------------------------------
    AssertOpenGL;                                                           % check if the correct psychtoolbox version is used
    starttime = clock;
    
    
    rand('state',sum(100*clock));                                           % rand('seed',sum(100*clock)) %  ensure that MATLAB always gives different random numbers in separate runs. In recent matlab version this line can be remplace by: rng(sum(100*clock),'v4')
    
    screens = Screen('Screens');                                            % get the number of screens, to choose the screen where you want to display the task
    screenNumber = max(screens);                                            % choose the external screen attached to the computer
    white = WhiteIndex(screenNumber);                                       % get the white and black indexes of the loaded gamma lookup table
    black = BlackIndex(screenNumber); 
    Screen('Preference', 'SkipSyncTests', 1);                               % it is ok to use this bc y=we are doing only auditory stimuli and we control perfeclty the timing
    [w,screenRect]= Screen('OpenWindow',screens);
    ifi = Screen('GetFlipInterval',w);                                      % inter-frame-interval:minimum possible time between drawing to the screen (should be 0.0167seconds)
    sca;
    %----------------------------------------------------------------------
    
    %-------------------------- Define Result path ------------------------
    %----------------------------------------------------------------------
    result_path = 'C:\Users\admin-local\Documents\MATLAB\MATLAB2\Library\Yvan_tasks\MMN_v3-64EEG_noWS_LISI\RESULTS\';
    %----------------------------------------------------------------------

    %----------------------- Pc port initialization for EEG----------------
    %----------------------------------------------------------------------
    if USE_EEG
        config_io
        address = hex2dec('378');                                           % le port depend de l'ordi
    end
    %----------------------------------------------------------------------
    
%% Initialisation
    % In the lab, we want at least 75 dev per duration (this number will be optimized for the train travel on another script)
    % And we want at least 1 std between a dev ( o  x )
    % we have 2 dev so 150 dev in total. it means we need at least 150 sequences o  x
    % we want 7.5% of dev compared to std so we will do loop putting 2 std and
    % then take randomly either a std or a dev.
    
    %---------------------------- Parameters ------------------------------
    %----------------------------------------------------------------------
    std_dur = 1.00;                                                        % std duration (o) = 1 s (in sec)                
    dev_dur = [0.900 1.10];                                    % dev duration (x) = 0.9 1.1s (in sec). 100ms difference from the std 
    ISI = [1.80 2.00];                                                    % ISI = 1.8:2s (in sec). ISI have been extended to avoid an overlap of the baseline of the MMN of the previous trial
    ISIf = round(ISI./ifi);                                                 % convert ISI in number of frame
    
    
    nStd = 38;                                                             % calculate by hands, 1000/2 = 500 ; we have 300 dev ; so we still need 200 std % standard number  = 700 (70%)  
    nDev = 75;                                                             % deviant number   = 300  (7.5% each) (75 each)
    nTOT = 375;                                                            % stimulus number  = 1000 (100%)
    %----------------------------------------------------------------------
    
    %---------------------------- Create clicks ---------------------------
    %----------------------------------------------------------------------
    click_dur = 0.005;                                                      % default click duration 5ms
    N = floor(sf*click_dur);                                                % number of samples for 5ms click
    sig = floor(randn(N,1));                                                % create white noise clicks               
    m = max(sig);                           
    tmp = 0.5 *(sig/m) ;                                                    % wnoise dB scaling
    
    ramp_dur = 0.0025;                                                      % define duration of the ramp (here half of the duration of the click
    y = ramp_sound(sf, ramp_dur, tmp);                                      % add the ramp to the sound. (the function ramp_sound need to be added in the folder)
   
    click(1,:) = y';
    click(2,:) = y';                                                        % make the sound binaural
    %----------------------------------------------------------------------
    
    
    %---------------------------- Create stims ----------------------------
    %----------------------------------------------------------------------
    % STD
    stdd     =  zeros(2,fix(sf*std_dur));                                   % number of samples for std dur
    STD      = [click stdd click];

    % DEV1
    dev1d     = zeros(2,fix(sf*dev_dur(1)));                                % number of samples for dev1 dur
    DEV1      = [click dev1d click];

    % DEV2
    dev2d     = zeros(2,fix(sf*dev_dur(2)));                                % number of samples for dev2 dur
    DEV2      = [click dev2d click];

    %----------------------------------------------------------------------

    %-------------------- Compute Experimental Matrix ---------------------
    %----------------------------------------------------------------------
    rep = 0;
    while rep == 0
        
        % initialization 
        expMat       = -99*ones(nTOT,5);                                    % the experimentale matrix that will contain 5 columns: stim_nb; stim_dur; ISI; trigger_sonset; trigger_offset
        expMat(:,1)  = randperm(length(expMat));
        expMat       = sortrows(expMat);

        % create the random order of dev and std vector.
        n_std  = std_dur*ones(nStd,2);                                      % create a vector of 38 stim containing 1s for the duration of std
        n_dev1 = dev_dur(1,1)*ones(nDev,2);                                 % create a vector of 75 stim containing 0.5 for the duration of dev1
        n_dev2 = dev_dur(1,2)*ones(nDev,2);                                 % ... dev2
      
        rand_stim = [n_std; n_dev1; n_dev2];                % concatenate all the simulus that will be randomly drawn

        rand_stim(:,1) = randperm(length(rand_stim));                       % create the random order
        rand_stim = sortrows(rand_stim);

        % loop that add a random stim (either std or dev) between 2 std
        idx = 1; 
        for i = 2:2:length(expMat)
            expMat(i,2) = rand_stim(idx,2);
            idx = idx+1;
        end

        % fill up the matrix with the std
        count = 0;
        for i = 1:length(expMat)
            if expMat(i,2) == -99
                expMat(i,2) = std_dur;
            else
                count = count+1;
            end
        end

        % check if we have all the stim and add trigger: 
        % o 10 & 11 = dev1 sound1 & sound2;
        % o 20 & 21 = dev2 sound1 & sound2;
        % o 50 & 51 = std  sound1 & sound2;
        
        countDev1 = 0;
        countDev2 = 0;
        countStd  = 0;
        for i = 1:length(expMat)
            
            if expMat(i,2) == dev_dur(1)
                countDev1 = countDev1 +1;
                expMat(i,4) = 10;
                expMat(i,5) = 11;
                
            elseif expMat(i,2) == dev_dur(2)
                countDev2 = countDev2 +1;
                expMat(i,4) = 20;  
                expMat(i,5) = 21;
                
            elseif expMat(i,2) == std_dur
                countStd = countStd +1;
                expMat(i,4) = 50;
                expMat(i,5) = 51;
            end
        end

        % add ISI in the 3rd column in sample rate based on the interframe interval
        nTOT = length(expMat);
        expMat(:,3) = round((ISIf(2)-ISIf(1))*rand(1,nTOT) + ISIf(1))';     % randomise une difference entre le min et le max de l'ISI et l'ajoute au minimum ISI pour avoir des ISI compris entre le min et le max  

        % ask if the numbers of stim presentation are correct
        disp(['Std number  : ' num2str(countStd) ' (' num2str((countStd*100)/length(expMat)) '%)'])
        disp(['Dev1 number : ' num2str(countDev1) ' (' num2str((countDev1*100)/length(expMat)) '%)'])
        disp(['Dev2 number : ' num2str(countDev2) ' (' num2str((countDev2*100)/length(expMat)) '%)'])
        disp(['Total number of stimuli : ' num2str(countStd + countDev1 + countDev2)])

        ok = input('Are you cool with those numbers? (0/1)');
        if ok == 1
            rep = 1;
        else
            rep = 0;
        end
    end

    %----------------------------------------------------------------------
    
    %--------------------- Prompt user for data file name -----------------
    %----------------------------------------------------------------------
    dataFile   = 'tmp';
    promptUser = true;

    while promptUser

        prompt1=inputdlg('Subject ID','Output File',1,{'tmp'});
        if isempty(prompt1)
            disp(['Experience annulee...']);
            return;
        else
            initials=prompt1{1};
        end

        prompt2=inputdlg('Block number','Output File',1,{'tmp'});
        if isempty(prompt2)
            disp(['Experience annulee...']);
            return;
        else
            blocknum =prompt2{1};
        end

        if initials
            tmpFile = [initials,blocknum,'_mmn_dur.mat'];
            if ~ exist(tmpFile)
                dataFile = [result_path tmpFile];
                promptUser = false;
            else
                replace=questdlg(['Un fichier de ce nom existe deja ', tmpFile, '. Voulez-vous le remplacer?']);
                if strcmp( replace, 'Yes' )
                   dataFile = [result_path tmpFile];
                   promptUser = false;
                end
            end
        end
    end
    %----------------------------------------------------------------------

    %% MMN task
    %-------------------- Initialize Display intial Screen ----------------
    %----------------------------------------------------------------------
    HideCursor;
    [w,screenRect]= Screen('OpenWindow',screenNumber,0,[],[],2);            % screenRect returns rectangular coordinates of the screen size in pixels

    displayWidth  = screenRect(3) - screenRect(1);                          % Get the size of the screen in pixels
    displayHeight = screenRect(4) - screenRect(2);
    
    FIX_HEIGHT = displayHeight/2;                                           % Get center of the screen for fixation cross and set global variables
    FIX_WIDTH  = displayWidth/2;
    FIX_COLOR  = white;

    instructions       = 'Appuyez sur la barre espace pour commencer';
    instructions_end   = 'Fin de la session. Merci! ';
    
    disp_instr = 0;
    while disp_instr == 0
        Screen('TextSize', w, 30);
        Screen('TextFont', w, 'Arial Black'); 
        Screen('FillRect', w, black );
        Screen('DrawText', w, instructions, displayWidth/2 - 350 , displayHeight/3, FIX_COLOR); % 350 depend de la taille de l'ecran 
        Screen('TextFont', w, 'Geneva'); 
        drawFixation(FIX_COLOR);
        Screen('Flip', w);
        
        [KeyIsDown,secs, keyCode, deltaSecs] = KbCheck;
        keyNum = find(keyCode);
        if keyNum == 32
            disp_instr = 1;
        elseif keyCode(escapeKey)
            error('Esc key was pressed');
            break
        end
    end
    %----------------------------------------------------------------------
    
    %----------------------------- Start MMN ------------------------------
    %----------------------------------------------------------------------
    save(dataFile, 'expMat');                                               % save expMat

    
    Screen('FillRect',w, black);                                            % initialization
    drawFixation(FIX_COLOR);
    Screen('Flip', w);
    
    priorityLevel=MaxPriority(w);                                           % set prioritylevel at maximum for minimum delay
    Priority(priorityLevel);
    
    tmp_s=zeros(1,10000);                                                   % initialize PsychSound
    tmp_s(1,:)= tmp_s;
    tmp_s(2,:)= tmp_s;
    
    PsychPortAudio('FillBuffer', pahandle,tmp_s);
    t0 = PsychPortAudio('Start', pahandle,[],0,1);
    WaitSecs(0.5);                                                          % Hack to initialize PsychSound
    
    nT = length(expMat);
    
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %!!!!!!!!!!!!!!!!!!!!!!!!! NEED TO BE COMMENTED !!!!!!!!!!!!!!!!!!!!!!!!!
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %nT=5; % it was just to debug, the nbr of trial is reduce to 20
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    %!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    TimeKeeper = -99*ones(nT,9);                                           % initialize matrix that store the timing in our task and that can be read with the appropriate script
    
    Screen('TextFont', w, 'Geneva'); 
    drawFixation(FIX_COLOR);
    t_start = Screen('Flip', w);
    
    % trigger pour le debut de la tache
    if USE_EEG
        outp(address, 226); % le trigger 226 signe le debut de la tâche
        WaitSecs(0.5);
        outp(address, 0);
    end

    PsychPortAudio('FillBuffer', pahandle, STD);
    
    WaitSecs(5)                                                             % Wait 5 seconds before starting
    
    % START LOOP   
    for trial = 1 : nT
      
        % timestamping trial onset
        Screen('TextFont', w, 'Geneva'); 
        drawFixation(FIX_COLOR);
        trial_start         = Screen('Flip',w); 
        TimeKeeper(trial,1) = trial_start;
        
        % read duration of the interval
        STIM = [];
        if expMat(trial,2) == 0.200
            STIM = STD;
        elseif expMat(trial,2)== 0.100
            STIM = DEV1;
        elseif expMat(trial,2)== 0.150
            STIM = DEV2;
        elseif expMat(trial,2) == 0.250
            STIM = DEV3;
        elseif expMat(trial,2)== 0.300
            STIM = DEV4;
        end
        
        PsychPortAudio('FillBuffer', pahandle, STIM);
        
        % TRIAL display for the experimenter
        disp([' Trial #' num2str(trial) '/' num2str(nT)]);
        disp(['play stimulus: ' expMat(trial,2)]);
        
        % timestamps when the sound hits the speakers
        t_sound_start = PsychPortAudio('Start', pahandle,[],[],1);
        TimeKeeper(trial,2) = t_sound_start;
        
        % trigger interval ONSET
        if USE_EEG
            outp(address,expMat(trial,4)); % with the outp function we don't have timestamp of the trigger...
            TimeKeeper(trial,3) = GetSecs;
        end
        
        [startTime_s endPositionSecs_s xruns estStopTime_s] = PsychPortAudio('Stop', pahandle, 1);
        TimeKeeper(trial,4) = startTime_s;                                  % same as the timestamp of soundstart
        TimeKeeper(trial,5) = endPositionSecs_s;                            % duration of the sound played
        TimeKeeper(trial,6) = estStopTime_s;                                % estimation of when the sound is finished
        
        outp(address, 0);                                                   % should reset the pin after the sound stopped
        % trigger interval OFFSET
%         if USE_EEG
%             outp(address,expMat(trial,5));
%             TimeKeeper(trial,7) = GetSecs;
%             WaitSecs(0.01);
%             outp(address, 0);
%         end
        
        Screen('TextFont', w, 'Geneva'); 
        drawFixation(FIX_COLOR);
        trial_stop = Screen('Flip', w, t_sound_start + expMat(trial,2)+ 0.010); 
        TimeKeeper(trial,8) = trial_stop;                                   % timing should be t_soundstart + sound duration 
        
        % trigger END of trial
        if USE_EEG
            outp(address,150); % le trigger 150 correspond a la fin du trial
            TimeKeeper(trial,9) = GetSecs;
        end
        
        % Wait ITI (frames)
        for i=1:expMat(trial,3)
            Screen('TextFont', w, 'Geneva'); 
            drawFixation(FIX_COLOR);
            Screen('Flip', w);
        end
        
        outp(address, 0);                                                   % should reset the oin after the ITI
                
        [KeyIsDown, secs, keyCode, deltaSecs] = KbCheck;
        KeyNum = find(keyCode);
        if keyCode(escapeKey)
            error('Esc key was pressed');       % ESCAPE program
            break;
        end
    end
    
    if USE_EEG
        outp(address,200); % le trigger 200 correspond a la fin de la tache
        WaitSecs(0.1);
        outp(address, 0);
    end

    Screen('TextSize', w, 30);
    Screen('TextFont', w, 'Arial Black'); 
    Screen('FillRect', w, black );
    Screen('DrawText', w, instructions_end,displayWidth/2 - 150 , FIX_HEIGHT, white);
    Screen('TextFont', w, 'Geneva'); 
    t_end = Screen('Flip', w);
    KbWait;
    %------------------------------ End MMN -------------------------------

    %------------------------- Save and close ptb -------------------------
    %----------------------------------------------------------------------
    save(dataFile, 'expMat');
    tmptimer = [initials,blocknum];
    timerFile = [result_path tmptimer];
    save([timerFile 'Timer'],'TimeKeeper','t_start','t_end', 'sf', 'STD', 'DEV1', 'DEV2', 'DEV3', 'DEV4', 'ifi');
    ShowCursor;
    sca
    PsychPortAudio('Stop',pahandle);
    %----------------------------------------------------------------------
    
catch
    % "catch" executes in case of an error in the "try" 
    % closes the onscreen w if open.
    ShowCursor;
    Screen('CloseAll');
    endtime=clock;
    disp(['CRITICAL ERROR: ' lasterr ])
    disp(['Exiting program ...'])
    rethrow(lasterror);
    PsychPortAudio('Stop',pahandle);
end %try..catch..

%==========================================================================
%------------------------------ SUB FUNCTIONS -----------------------------
%==========================================================================

%--------------------------------------------------------------------------
function drawFixation( color )
    % draws a fixation point to the Screen background buffer
    % color - the gamma lookup table color index
    global w
    global FIX_HEIGHT
    global FIX_WIDTH
    
    % length and width og the cross
    cross_length = 30;  
    penWidth = 5;
    
     % Color of the cross
    if ischar(color)
        if strcmp(color, 'white')
            color_rgb = [255 255 255];
        elseif strcmp(color, 'black')
            color_rgb = [0 0 0];
        else
            disp('This color is not yet programmed. The cross will be white')
            color_rgb = [255 255 255];
        end
    elseif isreal(color)
        color=num2str(color);
        if strcmp(color, '255')
            color_rgb = [255 255 255];
        elseif strcmp(color, '0')
            color_rgb = [0 0 0];
        else
            disp('This color is not yet programmed. The cross will be white')
            color_rgb = [255 255 255];
        end
    end
    
    bar_H_HdimStart = FIX_WIDTH - cross_length;
    bar_H_HdimEnd = FIX_WIDTH + cross_length;
    bar_H_VPosition = FIX_HEIGHT;
    Screen('DrawLine', w, color_rgb, bar_H_HdimStart, bar_H_VPosition, bar_H_HdimEnd, bar_H_VPosition, penWidth);

    % Vertical bar of the cross
    bar_V_HPosition = FIX_WIDTH;
    bar_V_VdimStart = FIX_HEIGHT - cross_length ;
    bar_V_VdimEnd = FIX_HEIGHT + cross_length;
    Screen('DrawLine', w, color_rgb, bar_V_HPosition, bar_V_VdimStart, bar_V_HPosition, bar_V_VdimEnd, penWidth);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function displayFixation( color )
    % draws a fixation point and refreshes the Screen
    % color - the gamma lookup table color index
    global w
    drawFixation( color );
    Screen('Flip', w);
