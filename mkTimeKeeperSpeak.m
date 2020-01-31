%% this script extract the infos of TimeKeeper, saved as subjnamesessionTimer.mat
%==========================================================================
% created by: YN 12/12/2019
% last update: YN 17/01/2020
%==========================================================================

clc
clear all;

if isunix
    slash = '/';
elseif ismac
    slash = '/';
elseif ispc
    slash = '\';
end

result_path = [pwd slash 'RESULTS' slash];

% ask the name of the file
dataFile   = 'tmp';
promptUser = true;

while promptUser

    prompt1=inputdlg('Subject ID','Output File',1,{'tmp'});
    if isempty(prompt1)
        disp(['Script annulÃ©...']);
        return;
    else
        initials=prompt1{1};
    end

    prompt2=inputdlg('Block number','Output File',1,{'tmp'});
    if isempty(prompt2)
        disp(['Script annulÃ©...']);
        return;
    else
        blocknum =prompt2{1};
    end

    if initials
        tmpFile = [initials,blocknum,'_mmn_dur.mat'];
        timerFile = [initials,blocknum, 'Timer.mat'];
        if  exist(tmpFile)
            dataFile = [result_path tmpFile];
            load(dataFile);
            load(timerFile);
            promptUser = false;
        else
            replace=questdlg(['Ce fichier n''existe pas.', tmpFile, '. Voulez-vous recommencer?']);
            if strcmp( replace, 'Yes' )
               promptUser = true;
            end
        end
    end
end

% did you used eeg ?
used_EEG = false;

% do you want to plot ?
plot = false;

% check for -99
B = TimeKeeper == -99;
C = sum(sum(B)); % nbr of element missing should be 3*20
disp(['il manque ' num2str(C) ' éléments.'])
disp('========================================')
% if ~ used_EEG
%     disp('3*20 Ã©lÃ©ments manquants Ã©taient attendus')
% else
%     disp('c''est pas normal, t''as encore fait une erreur... toc hard')
% end

disp(['durée totale de la tàche:' num2str((t_end - t_start)/60) 'min']);
disp('========================================')

%% check delay between trials
% initialization
trial_start_diff = -99*(length(TimeKeeper)-1);
sound_start_diff = -99*(length(TimeKeeper)-1);
trial_stop_diff = -99*(length(TimeKeeper)-1);
theoretical_trial_dur = -99*(length(TimeKeeper)-1);
counter = 0;
i = 0;
% compute the diff between each trial to see if everything goes in the same timinng 
for i=2:length(TimeKeeper)
    counter = counter + 1;
    trial_start_diff(counter) = TimeKeeper(i,1) - TimeKeeper(i-1,1);
    
    theoretical_trial_dur(counter) = expMat(i,2) + expMat(i,3)*ifi + 0.010;    % theoretical trial duration
    
    sound_start_diff(counter) = TimeKeeper(i,2) - TimeKeeper(i-1,2);

    trial_stop_diff(counter) = TimeKeeper(i,8) - TimeKeeper(i-1,8);
end

trial_start_min = min(trial_start_diff);
trial_start_max = max(trial_start_diff);
trial_start_max_diff = trial_start_max - trial_start_min;
disp(['Mean diff betwteen trial starts: ' num2str(mean(trial_start_diff)) ' should be close to 0.7s'])
disp(['Maximum delay betwteen trial starts: ' num2str(trial_start_max_diff) ' Theoretical delay is 0.2s (ISI range)'])
cmp_theoretical_vs_trial_dur_trial = theoretical_trial_dur - trial_start_diff;
disp(['Mean diff between theoretical trial dur and measured (by trial start): ' num2str(mean(cmp_theoretical_vs_trial_dur_trial))])
disp('========================================')

if plot
    figure
    plot(trial_start_diff);
    title('trial start diff')
    xlabel('time in seconds')
    ylabel('time of each trial')
end

sound_start_min = min(sound_start_diff);
sound_start_max = max(sound_start_diff);
sound_start_max_diff = sound_start_max - sound_start_min;
disp(['Mean diff between sound start is ' num2str(mean(sound_start_diff)) ' should be close to 0.7s'])
disp(['Maximum delay betwteen sound_1 starts: ' num2str(sound_start_max_diff) ' Theoretical delay is 0.2s (ISI range)'])
cmp_theoretical_vs_trial_dur_sound = theoretical_trial_dur - sound_start_diff;
disp(['Mean diff between theoretical trial dur and measured (by sound start): ' num2str(mean(cmp_theoretical_vs_trial_dur_sound))])
disp('========================================')

if plot
    figure
    plot(sound_start_diff);
    title('sound start diff')
    xlabel('time in seconds')
    ylabel('time of each trial')
end

trial_stop_min = min(trial_stop_diff);
trial_stop_max = max(trial_stop_diff);
trial_stop_max_diff = trial_stop_max - trial_stop_min;
disp(['Mean diff between trial stop is ' num2str(mean(trial_stop_diff)) ' should be close to 0.7s'])
disp(['Maximum delay betwteen trial stops: ' num2str(trial_stop_max_diff) ' Theoretical delay is 0.2s (ISI range)'])
cmp_theoretical_vs_trial_dur_stop = theoretical_trial_dur - trial_stop_diff;
disp(['Mean diff between theoretical trial dur and measured (by trial stop): ' num2str(mean(cmp_theoretical_vs_trial_dur_stop))])
disp('========================================')

if plot
    figure
    plot(trial_stop_diff);
    title('trial stop diff')
    xlabel('time in seconds')
    ylabel('time of each trial')
end

%% check delay within trials
n = 0;
timing_within = -99*ones(length(TimeKeeper), 9);
cmp_theoretical_vs_measured = -99*ones(length(TimeKeeper), 5);
cmp_theoretical_vs_measured(:,1) = expMat(1:length(TimeKeeper),2) + 0.010; % set the theoretical value of stim duration in sec
for n = 1:length(TimeKeeper)
    timing_within(n,1) = TimeKeeper(n,2) - TimeKeeper(n,1); % diff between trial start and sound start
    timing_within(n,2) = TimeKeeper(n,6) - TimeKeeper(n,2); % diff between sound stop and sound start   
    timing_within(n,3) = TimeKeeper(n,8) - TimeKeeper(n,6); % diff between trial stop and sound stop (should be the same so close to zero)
    timing_within(n,9) = TimeKeeper(n,8) - TimeKeeper(n,2); % diff between trial stop and sound start
    
    cmp_theoretical_vs_measured(n,2) = timing_within(n,2);
    cmp_theoretical_vs_measured(n,3) = abs(cmp_theoretical_vs_measured(n,1)-timing_within(n,2)); % compare theoretical value of the sound duration and its measured duration by estStopTime
    cmp_theoretical_vs_measured(n,4) = timing_within(n,9);
    cmp_theoretical_vs_measured(n,5) = abs(cmp_theoretical_vs_measured(n,1)-timing_within(n,9)); % compare theoretical value of the sound duration and its measured duration by trial stop
    
    if used_EEG
        timing_within(n,4) = TimeKeeper(n,7) - TimeKeeper(n,6); % diff between trigger offset and sound stop
        timing_within(n,5) = TimeKeeper(n,9) - TimeKeeper(n,8); % diff between trigger stop and trial stop
        timing_within(n,6) = TimeKeeper(n,3) - TimeKeeper(n,2); % diff between trigger sound and sound start
        timing_within(n,7) = TimeKeeper(n,9) - TimeKeeper(n,6); % diff between trigger stop and sound stop
        timing_within(n,8) = TimeKeeper(n,9) - TimeKeeper(n,7); % diff between trigger sound and sound start
    end
end

% figure
% plot(timing_within(:,3));
% title('diff between stim duration theoretical and measured')
% xlabel('trial')
% ylabel('stim diff (in sec)')
% disp('========================================')
% 
% min_diff = min(timing_within(:,3));
% max_diff = max(timing_within(:,3));
% maximun_range_of_diff = max_diff - min_diff;
% disp(['Range of difference between stim duration' num2str(maximun_range_of_diff)])
% disp(['Mean diff between stim duration: ' num2str(mean(timing_within(:,3)))])
% disp('========================================')

%% check ISI timing
p = 0;
timing_ISI = -99*ones(length(TimeKeeper)-1,6);
timing_ISI(:,1) = expMat(1:length(TimeKeeper)-1, 3)*ifi; % set the theoretical value of ISI duration in sec
for p = 2:length(TimeKeeper)
    timing_ISI(p-1,2) = TimeKeeper(p,2) - TimeKeeper(p-1,6); % diff between sound start of the current trial and the sound stop of the previous trial
    
    timing_ISI(p-1,5) = TimeKeeper(p,1) - TimeKeeper(p-1,8); % diff between trial start of the current trial and the trial stop of the previous trial => should be ISI dur
    
    timing_ISI(p-1,3) = abs(timing_ISI(p-1,1) - timing_ISI(p-1,2)); % compare the theoretical value of the ISI and its measured duration (by estStopTime)
    
    timing_ISI(p-1,6) = abs(timing_ISI(p-1,1) - timing_ISI(p-1,5)); % compare the theoretical value of the ISI and its measured duration (by trial stop)
     
    if used_EEG
        timing_ISI(p-1,4) = TimeKeeper(p,2) - TimeKeeper(p-1,9); % diff between 
    end
end

if plot
    figure
    plot(timing_ISI(:,3));
    title('diff between ISI duration theoretical and measured')
    xlabel('trial')
    ylabel('ISI diff (in sec)')
end

minSound_diff = min(cmp_theoretical_vs_measured(:,3));
maxSound_diff = max(cmp_theoretical_vs_measured(:,3));
minSound_diff_stop = min(cmp_theoretical_vs_measured(:,5));
maxSound_diff_stop = max(cmp_theoretical_vs_measured(:,5));
maximun_Soundrange_of_diff = maxSound_diff - minSound_diff;
maximun_Soundrange_of_diff_stop = maxSound_diff_stop - minSound_diff_stop;
disp(['Maximum difference between stimulus duration (by EstStopTime) ' num2str(maximun_Soundrange_of_diff) 's'])
disp(['Maximum difference between stimulus duration (by trialStop) ' num2str(maximun_Soundrange_of_diff_stop) 's'])
disp(['Mean difference between theoretical and measured stimulus duration (by EstStopTime) : ' num2str(mean(cmp_theoretical_vs_measured(:,3))) 's'])
disp(['Mean difference between theoretical and measured stimulus duration (by trial stop) : ' num2str(mean(cmp_theoretical_vs_measured(:,5))) 's'])
disp('========================================')

minISI_diff = min(timing_ISI(:,3));
maxISI_diff = max(timing_ISI(:,3));
maximun_ISIrange_of_diff = maxISI_diff - minISI_diff;
minISI_diff_stop = min(timing_ISI(:,6));
maxISI_diff_stop = max(timing_ISI(:,6));
maximun_ISIrange_of_diff_stop = maxISI_diff_stop - minISI_diff_stop;
disp(['Maximum difference between ISI duration (EstStopTime) ' num2str(maximun_ISIrange_of_diff) 's'])
disp(['Mean difference between theoretical and measured ISI duration (EstStopTime): ' num2str(mean(timing_ISI(:,3))) 's'])
disp(['Maximum difference between ISI duration (trial stop) ' num2str(maximun_ISIrange_of_diff_stop) 's'])
disp(['Mean difference between theoretical and measured ISI duration (trial stop): ' num2str(mean(timing_ISI(:,6))) 's'])
disp('========================================')

if used_EEG
    disp(['Mean delay between trigger offset and sound stop: ' num2str(mean(timing_within(:,4)))])
    disp('========================================')
    disp(['Mean delay between trigger stop and trial stop: ' num2str(mean(timing_within(:,5)))])
    disp('========================================')
    disp(['Mean delay between trigger sound and sound start: ' num2str(mean(timing_within(:,6)))])
    disp('========================================')
    disp(['Mean delay between trigger stop and sound stop: ' num2str(mean(timing_within(:,7)))])
    disp('========================================')
    disp(['Mean delay between trigger stop and trigger offset: ' num2str(mean(timing_within(n,8)))])
    disp('========================================')
end
