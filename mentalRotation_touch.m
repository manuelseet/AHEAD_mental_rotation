
try
    % Preliminary stuff
    % Clear Matlab/Octave window:
    clc;
    
    % Reseed randomization
    rand('state', sum(100*clock));
    
    % check for Opengl compatibility, abort otherwise:
    AssertOpenGL;
    Priority(2);
    
    % General information about subject and session
    subNo = input('Subject number: ');
    hand  = input('Condition code: ');
    date  = str2num(datestr(now,'yyyymmdd'));
    time  = str2num(datestr(now,'HHMMSS'));
    
    % Get information about the screen and set general things
    Screen('Preference', 'SuppressAllWarnings',1);
    Screen('Preference', 'SkipSyncTests', 1);
    screens       = Screen('Screens');
%     if length(screens) > 1
%         error('Multi display mode not supported.');
%     end
    rect          = Screen('Rect',0);
    screenRatio   = rect(3)/rect(4);
    pixelSizes    = Screen('PixelSizes', 0);
    startPosition = round([rect(3)/2, rect(4)/2]);

    
    % Experimental variables
    % Number of trials etc.
    degrees        = [0 50 100 150];%[0 60 120 180 240 300];
    nExercise      = 1;
    numberOfBlocks = 1;
    trialList      = [];
    for i = 1:12 %all 12 stimuli
        if i < 7 
            mirror = 0; %first 6 are original
        elseif i >= 7
            mirror = 1; %next 6 are mirror of originals
        end
        trialList = [trialList [zeros(1, length(degrees))+i; degrees; zeros(1, length(degrees))+ mirror]]; % [stimulus; degress; mirroring] if stimulus > 10 then it is mirrored
    end
    
    % Output files
    datafilename = strcat('results/mentalRotation_',num2str(subNo),'.dat'); % name of data file to write to
    mSave        = strcat('results/mentalRotation_',num2str(subNo),'.mat'); % name of another data file to write to (in .mat format)
    mSaveAll     = strcat('results/mentalRotation_',num2str(subNo),'All.mat'); % name of another data file to write to (in .mat format)
    
    % Checks for existing result file to prevent accidentally overwriting
    % files from a previous subject/session (except for subject numbers > 99):
    if subNo<99 && fopen(datafilename, 'rt')~=-1
        fclose('all');
        error('Result data file already exists! Choose a different subject number.');
    else
        datafilepointer = fopen(datafilename,'wt'); % open ASCII file for writing
    end
    
    % Temporal variables
    ITI                 = 0.25;
    fixDuration         = 0.25; % as in Shepard (1971)
    maxDuration         = 8;
    fbTime              = 0.5;
    
    % Experimental data
    RT                  = zeros(2, length(trialList))-99;
    response            = zeros(2, length(trialList))-99;
    correctness         = zeros(2, length(trialList))-99;
    results             = cell(length(trialList)*numberOfBlocks, 14); 
    % SubNo, date, time, trial, stim, block, mirroring/rightAnswer,
    % response, correctness, RT, fixationOnsetTime, StimulusOnsetTime, endStimulus

    % Colors
    bgColor             = [255, 255, 255];
    fixColor            = [0 0 0];
    
    % Textures
    fixLen              = 20; % Size of fixation cross in pixel
    fixWidth            = 3;
    
    % Creating screen etc.
    try
        [myScreen, rect]    = Screen('OpenWindow', 2, bgColor);
    catch
        try
            [myScreen, rect]    = Screen('OpenWindow', 2, bgColor);
        catch
            try
                [myScreen, rect]    = Screen('OpenWindow', 2, bgColor);
            catch
                try
                    [myScreen, rect]    = Screen('OpenWindow', 2, bgColor);
                catch
                    [myScreen, rect]    = Screen('OpenWindow', 2, bgColor);
                end
            end
        end
    end
    center              = round([rect(3) rect(4)]/2);
    
    % Keys and responses
    KbName('UnifyKeyNames');
    space               = KbName('space');
    if hand == 1
            notMirrored         = KbName('RightArrow'); % Saying not mirrored
            mirrored            = KbName('LeftArrow');  % Saying mirrored
            notMirroredString   = 'Right';
            mirroredString      = 'Left';
    elseif hand == 2
            notMirrored         = KbName('LeftArrow'); % Saying not mirrored
            mirrored            = KbName('RightArrow');  % Saying mirrored
            notMirroredString   = 'Left';
            mirroredString      = 'Right';
    end
    
    % Loading stimuli
    images              = {};
    stimuli             = {};
    for i = 1:12
        if i > 6
            images{i}  = imread(strcat('stimuli/stim_',num2str(i),'.jpg'));
        else
            images{i}  = imread(strcat('stimuli/stim_',num2str(i),'.jpeg'));
        end
        stimuli{i} = Screen('MakeTexture', myScreen, images{i}); % Saving textures in this structure
    end
    imageSize          = size(images{1});
    shift              = 50;
    
    % Calculating to rectangles (splitting screen)
    leftPosition       = [center(1)-imageSize(1)-shift center(2)-imageSize(1)/2 center(1)-shift center(2)+imageSize(1)/2];
    rightPosition      = [center(1)+shift center(2)-imageSize(1)/2 center(1)+ imageSize(1)+shift center(2)+imageSize(1)/2];
    
    % Message for introdution
    lineLength   = 90;
    Screen('TextStyle', myScreen, 1)
    Screen('TextSize',myScreen,50);

    messageIntro = WrapString(horzcat('Welcome to the Mental Rotation Task \n\n If the figures are different, \nplease press the DIFFERENT button. \n\nIf both figures are identical after the rotation, \nplease press the SAME button'),lineLength);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Experimental loop
    screenXpixels = rect(3);
    screenYpixels = rect(4); %get the screen size
    
    nextdata = imread('next.jpg');
    nextsize = size(nextdata);
    next_loc = [screenXpixels-nextsize(2) screenYpixels-nextsize(1) screenXpixels screenYpixels];
    nextPointer= Screen('MakeTexture', myScreen, nextdata);
    Screen('DrawTexture', myScreen, nextPointer,[0 0 nextsize(2),nextsize(1)],next_loc);
    HideCursor;
    
    iTrial = 0; % used for index
    for block = 1:numberOfBlocks
        if block == 1 % Shows introduction
            
            Screen('TextSize',myScreen,100);
            DrawFormattedText(myScreen, messageIntro, 'center', 'center');
            Screen('DrawTexture', myScreen, nextPointer,[0 0 nextsize(2),nextsize(1)],next_loc);
            
            Screen('Flip', myScreen); SetMouse(0,0,myScreen);
            while ~KbCheck
                [mx, my, buttons] =GetMouse(window); %alternate click loc
                if mx>=(next_loc(1)) && mx<=(next_loc(3)) && my>=(next_loc(2)) && my<=(next_loc(4))
                    Screen('Flip', window); 
                   break;
                end
            end
         
            WaitSecs(0.3);
            
            Screen('TextSize',myScreen,100);
            DrawFormattedText(myScreen, 'Get Ready. \n\n Press NEXT to start practice', 'center', 'center');
            Screen('DrawTexture', myScreen, nextPointer,[0 0 nextsize(2),nextsize(1)],next_loc);

            Screen('Flip', myScreen); 
            SetMouse(10,10,myScreen);
            while ~KbCheck
                [mx, my, buttons] =GetMouse(window); %alternate click loc
                if mx>=(next_loc(1)) && mx<=(next_loc(3)) && my>=(next_loc(2)) && my<=(next_loc(4))
                    Screen('Flip', window); 
                   break;
                end
            end
            
            WaitSecs(0.5);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Exercise 
            trialListExp = trialList(1:3, randomOrder(length(trialList), nExercise));
            
            diffdata = imread('different.jpg');
            diffsize = size(diffdata);
            diff_loc = [0 screenYpixels-diffsize(1) diffsize(2) screenYpixels];
            diffPointer= Screen('MakeTexture', myScreen, diffdata);
            Screen('DrawTexture', myScreen, diffPointer,[0 0 diffsize(2),diffsize(1)],diff_loc);
            
            samedata = imread('different.jpg');
            samesize = size(samedata);
            same_loc = [screenXpixels-samesize(2) screenYpixels-samesize(1) screenXpixels screenYpixels];
            samePointer= Screen('MakeTexture', myScreen, samedata);
            Screen('DrawTexture', myScreen, samePointer,[0 0 samesize(2),samesize(1)],same_loc);
            
            for trial = 1:nExercise
                % Fixation cross
                Screen('FillRect', myScreen, bgColor(1, 1:3)); % Sets normal bg color
                Screen('DrawLine', myScreen, fixColor, center(1)- fixLen, center(2), center(1)+ fixLen, center(2), fixWidth);
                Screen('DrawLine', myScreen, fixColor, center(1), center(2)- fixLen, center(1), center(2)+ fixLen, fixWidth);
                [VBLTimestamp fixationOnsetTime] = Screen('Flip', myScreen);
                WaitSecs(fixDuration);

                % Stimulus presentation
                if trialListExp(1,trial) > 10
                    Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)-10},[] , leftPosition, 0); % Stimulus for comparison
                else
                    Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , leftPosition, 0); % Stimulus for comparison
                end
                Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , rightPosition, trialListExp(2, trial)); % stimulus rotated
                [VBLTimestamp StimulusOnsetTime1] = Screen('Flip', myScreen);
                
                SetMouse(0,0,myScreen);tic;

                % Recording response
                %[keyIsDown, secs, keyCode] = KbCheck; % saves whether a key has been pressed, seconds and the key which has been pressed.
                while keyCode(notMirrored) == 0 && keyCode(mirrored) == 0
                    [mx, my, buttons] =GetMouse(window); %alternate click loc
                    if mx>=(diff_loc(1)) && mx<=(diff_loc(3)) && my>=(diff_loc(2)) && my<=(diff_loc(4))
                       secs = toc;
                       keyCode(Mirrored) = 1;
                       break;
                    end
                    if mx>=(same_loc(1)) && mx<=(same_loc(3)) && my>=(same_loc(2)) && my<=(same_loc(4))
                       secs = toc;
                       keyCode(notMirrored) = 1;
                       break;
                        %[keyIsDown, secs, keyCode] = KbCheck;
                    end
                    if secs - StimulusOnsetTime1 >= maxDuration
                        break
                    end
                end
                endStimulus   = Screen('Flip', myScreen);
                
                % Feedback
                if keyCode(notMirrored) == 1 % Saying not mirrored
                    if trialListExp(3, trial) == 0 % Not mirrored
                        Screen('TextColor', myScreen, [0 255 0]); 
                        DrawFormattedText(myScreen, horzcat('Correct'), 'center', 'center');
                    else % Mirrored
                        Screen('TextColor', myScreen, [255 0 0]); 
                        DrawFormattedText(myScreen, horzcat('Incorrect'), 'center', 'center');
                    end
                elseif keyCode(mirrored) == 1 % Saying mirrored
                    if trialListExp(3, trial) == 0 % Not mirrored
                        Screen('TextColor', myScreen, [255 0 0]); 
                        DrawFormattedText(myScreen, horzcat('Incorrect'), 'center', 'center');
                    else % Mirrored
                        Screen('TextColor', myScreen, [0 255 0]); 
                        DrawFormattedText(myScreen, horzcat('Correct'), 'center', 'center');
                    end 
                end
                Screen('Flip', myScreen);
                WaitSecs(fbTime);
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % Start of Experiment display
            Screen('TextColor', myScreen, [0 0 0]); 
            WaitSecs(0.1);
            DrawFormattedText(myScreen, horzcat('Start of Experiment. Press NEXT to begin'), 'center', 'center');
            Screen('DrawTexture', myScreen, nextPointer,[0 0 nextsize(2),nextsize(1)],next_loc);

            Screen('Flip', myScreen); SetMouse(0,0,myScreen);
            while ~KbCheck
                [mx, my, buttons] =GetMouse(window); %alternate click loc
                if mx>=(next_loc(1)) && mx<=(next_loc(3)) && my>=(next_loc(2)) && my<=(next_loc(4))
                    Screen('Flip', window); 
                   break;
                end
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Experiment 
        trialListExp = trialList(1:3, randomOrder(length(trialList), length(trialList)));
        
        % Block display
        WaitSecs(0.1);
        DrawFormattedText(myScreen, horzcat(num2str(block),'Experimental Block \n Please press spacebar to proceed.'), 'center', 'center');
        Screen('Flip', myScreen);
        [secs, keyCode] = KbWait;
        while keyCode(space) == 0
            [secs, keyCode] = KbWait;
        end
        Screen('Flip', myScreen);
        
        % Experimental loop
        for trial = 1:length(trialListExp)
            startOfTrial = GetSecs;
            iTrial = iTrial + 1;
            
            % Fixation cross
            Screen('DrawLine', myScreen, fixColor, center(1)- fixLen, center(2), center(1)+ fixLen, center(2), fixWidth);
            Screen('DrawLine', myScreen, fixColor, center(1), center(2)- fixLen, center(1), center(2)+ fixLen, fixWidth);
            [VBLTimestamp fixationOnsetTime] = Screen('Flip', myScreen);
            WaitSecs(fixDuration);

            % Stimulus presentation
            if trialListExp(1,trial) > 10
                Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)-10},[] , leftPosition, 0); % Stimulus for comparison
            else
                Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , leftPosition, 0); % Stimulus for comparison
            end
            Screen('DrawTexture', myScreen, stimuli{trialListExp(1, trial)},[] , rightPosition, trialListExp(2, trial)); % stimulus rotated
            [VBLTimestamp StimulusOnsetTime1] = Screen('Flip', myScreen);
            
            % Recording response
            [keyIsDown, secs, keyCode] = KbCheck; % saves whether a key has been pressed, seconds and the key which has been pressed.
            while keyCode(notMirrored) == 0 && keyCode(mirrored) == 0
                [keyIsDown, secs, keyCode] = KbCheck;
                if secs - StimulusOnsetTime1 >= maxDuration
                    break
                end
            end
            endStimulus   = Screen('Flip', myScreen);
            
            if keyCode(notMirrored) == 1 % Saying not mirrored
                if trialListExp(3, trial) == 0 % Not mirrored
                    Screen('TextColor', myScreen, [0 255 0]); 
                    DrawFormattedText(myScreen, horzcat('Correct'), 'center', 'center');
                else % Mirrored
                    Screen('TextColor', myScreen, [255 0 0]); 
                    DrawFormattedText(myScreen, horzcat('Incorrect'), 'center', 'center');
                end
             elseif keyCode(mirrored) == 1 % Saying mirrored
                if trialListExp(3, trial) == 0 % Not mirrored
                    Screen('TextColor', myScreen, [255 0 0]); 
                    DrawFormattedText(myScreen, horzcat('Incorrect'), 'center', 'center');
                else % Mirrored
                    Screen('TextColor', myScreen, [0 255 0]); 
                    DrawFormattedText(myScreen, horzcat('Correct'), 'center', 'center');
                end 
            end
            Screen('Flip', myScreen);
            WaitSecs(fbTime);
            
            % Saving response and checking correctness
            RT(block, trial) = (secs - StimulusOnsetTime1)*1000;
            if keyCode(notMirrored) == 1 % Saying not mirrored
                response(block, trial) = 0; % Saying not mirrored
                if trialListExp(3, trial) == 0 % Not mirrored
                    correctness(block, trial) = 4; % Correct rejection
                else % Mirrored
                    correctness(block, trial) = 3; % Miss
                end
            elseif keyCode(mirrored) == 1 % Saying mirrored
                response(block, trial) = 1; % Saying mirrored
                if trialListExp(3, trial) == 0 % Not mirrored
                    correctness(block, trial) = 2; % False Alarm
                else % Mirrored
                    correctness(block, trial) = 1; % Hit
                end 
            end
            WaitSecs(ITI);
            
            % SubNo, date, time, trial, stim, block, angle, mirroring/rightAnswer,
            % response, correctness, RT, fixationOnsetTime, StimulusOnsetTime, endStimulus
            fprintf(datafilepointer,'%i %i %i %i %i %i %i %i %i %i %f %f %f %f\n', ...
                subNo, ...
                date, ...
                time, ...
                iTrial, ...
                trialListExp(1,trial), ...
                block, ...
                trialListExp(2, trial),...
                trialListExp(3,trial), ...
                response(block, trial),...
                correctness(block, trial),...
                RT(block, trial),...
                (fixationOnsetTime - startOfTrial)*1000,...
                (StimulusOnsetTime1 - startOfTrial)*1000,...
                (endStimulus - startOfTrial)*1000);

            results{iTrial, 1}  = subNo;
            results{iTrial, 2}  = date;
            results{iTrial, 3}  = time;
            results{iTrial, 4}  = iTrial;
            results{iTrial, 5}  = trialListExp(1,trial);
            results{iTrial, 6}  = block;
            results{iTrial, 7}  = trialListExp(2, trial);
            results{iTrial, 8}  = trialListExp(3,trial);
            results{iTrial, 9}  = response(block, trial);
            results{iTrial, 10} = correctness(block, trial);
            results{iTrial, 11} = RT(block, trial);
            results{iTrial, 12} = (fixationOnsetTime - startOfTrial)*1000;
            results{iTrial, 13} = (StimulusOnsetTime1 - startOfTrial)*1000;
            results{iTrial, 14} = (endStimulus - startOfTrial)*1000;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    % End screen
    Screen('TextSize',myScreen,100);
    DrawFormattedText(myScreen, 'End of Experiment', 'center', 'center');
    Screen('Flip', myScreen);
    WaitSecs (3.000);
    
    save(mSave, 'results');
    %save(mSaveALL);
    fclose('all');
    Screen('CloseAll');
    Priority(0);
    ShowCursor;
catch
    rethrow(lasterror)
    save(mSave, 'results');
    %save(mSaveAll);
    Screen('CloseAll')
    fclose('all');
    Priority(0);
    ShowCursor;
end