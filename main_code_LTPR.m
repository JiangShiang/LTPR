clearvars
clc

global hist subj wPtr rect scr_x scr_y text_color bk_color dot_color rect_color baseLen baseSepX baseSepY TT AT start_quiz_first start_prac_trial start_stage_first start_quiz_second start_stage_second 

%% Set function path
mainpath = cd;
addpath(genpath(fullfile(mainpath,'experiment_materials')));

%% ID and file names
hist.ID = input('Subject ID:  ');

FileName = ['LTPR' datestr(clock,'mmDDHH') '_subject_', num2str(hist.ID) ,'.mat']; % Matlab .mat file name
edfFile  = [ datestr(clock,'mmDDHH') num2str(hist.ID),'.edf']; % Name of remote data file to create
xlsxFile = ['LTPR' datestr(clock,'mmDDHH') '_subject_', num2str(hist.ID) ,'.xlsx'];

%% Selcet mode 
dummy_mode = 0; % 1 = no eye-tracking, 0 = eye-tracking
test_mode  = 0; % T = 5; short session, 1 = test
% PsychDebugWindowConfiguration % transparent the window

show_up_fee = 100;
token_exchange_rate = 1.2;

%% Shuffle Random Num Seed
rng('shuffle');

%% decide game length
TT = 72; % 72 trials (formal exp.)
num_quiz_first  = 7; % 7 comprehension quiz for the first stage
num_prac_trial  = 3; % 3 practice trials
num_quiz_second = 2; % 2 comprehension quiz for the second stage
AT = 84; % 84 trials (in total)

start_quiz_first   = 1;                                 % trial 1-7 
start_prac_trial   = start_quiz_first + num_quiz_first; % trial 8-10
start_stage_first  = start_prac_trial + num_prac_trial; % trial 11-46
start_quiz_second  = start_stage_first + TT/2;          % trial 47-48
start_stage_second = start_quiz_second + num_quiz_second; % trial 49-84

if test_mode
    Screen('Preference', 'SkipSyncTests', 1);
    T = AT;
else
    Screen('Preference', 'SkipSyncTests', 0);
    T = AT; % trial # for session I, decpends on data
end

%% Preallocate matrix or struct. for saving data
hist.trial_index      = ones(1, AT)*NaN;
hist.today_pay        = ones(1, AT)*NaN;
hist.weeks_delayed    = ones(1, AT)*NaN;
hist.future_pay       = ones(1, AT)*NaN;
hist.left_is_future   = ones(1, AT)*NaN;
hist.choose_future    = ones(1, AT)*NaN;
hist.response_time    = ones(1, AT)*NaN;
hist.pi_trial = [randi([11,46],1), randi([49,AT],1)]; % Randomly decide the payoff trial from both stage

%% Read Data
pay_o = readtable('bank_transfer.xlsx');
writetable(pay_o, ['bank_transfer','.xlsx']); % see whether the xlsx is available

%% decide treatment or control
subj.treatment = rand;
if subj.treatment < 0.5
     subj.treatment = 0;
else
     subj.treatment = 1;
end
hist.treatment_will = subj.treatment;

%% Decide the first stage is 100 or 120 tokens today and Read the corresponding parameters
subj.first_stage = rand;
if subj.first_stage < 0.5
     subj.first_stage = 100; subj.second_stage = 120;
     par_o = readtable('game_para_first100.xlsx');%% Get Data (loads CSV/Excel/Mat)
else
     subj.first_stage = 120; subj.second_stage = 100;
     par_o = readtable('game_para_first120.xlsx');%% Get Data (loads CSV/Excel/Mat)
end
hist.first_stage = subj.first_stage;

%% Randomize the weeks delayed and payment for the future
hist.rand_order = [randperm(num_prac_trial),randperm(TT/2)+num_prac_trial,randperm(TT/2)+num_prac_trial+TT/2]; %[1:3 4:39 40:75]
par = par_o(hist.rand_order , :);
for n = 1:(TT + num_prac_trial)
    if n <= num_prac_trial + TT/2  % practice + firststage
        hist.today_pay(n + num_quiz_first) = par.today_pay(n);
        hist.weeks_delayed(n + num_quiz_first) = par.weeks_delayed(n);
        hist.future_pay(n + num_quiz_first) = par.future_pay(n);
    else % second stage
        hist.today_pay(n + num_quiz_first + num_quiz_second) = par.today_pay(n);
        hist.weeks_delayed(n + num_quiz_first + num_quiz_second) = par.weeks_delayed(n);
        hist.future_pay(n + num_quiz_first + num_quiz_second) = par.future_pay(n);
    end
end
%% Randomize "future" and "today" in the left / right rectangle
for n = 1: (TT + num_prac_trial)
    indexes = rand;
    if indexes < 0.5
     	left_future = 0;
    else
        left_future = 1;
    end
    if n <= num_prac_trial + TT/2  % practice + firststage
        hist.left_is_future(n + num_quiz_first) = left_future; 
    else % second stage
        hist.left_is_future(n + num_quiz_first + num_quiz_second) = left_future; 
    end
end

%% Rest Screen is not placed yet
if test_mode
    rest_t  = round(num_quiz_first + num_prac_trial + TT/2);
else
    rest_t  = round(num_quiz_first + num_prac_trial + TT/2);
end

%% Set parameters
dot_size   = 36;    % fixation dot size
fix_thresh = 100;   % fixation threshold width
fix_time   = 1.1;   % fixation time in second

%% Creat Files
createFile = 0; % if we screate .edf file
save_file  = 1; % if we save matlab .mat file

if ~dummy_mode
    createFile = 1;
    save_file  = 1;
end

%% Screens
% Get the screen numbers
screens = Screen('Screens'); % if we have 2 screens, we will get [0 1 2]

% Draw to the external screen if avaliable
if max(screens) > 1
    scr_num = 2;
else
    scr_num = 0;
end

%% Colors
red   = [100, 0, 0]; green = [  0, 100,  0];    blue = [  0,   0, 100];
black = [  0, 0, 0]; gray  = [255, 255 255]/3; white = [255, 255, 255];

bk_color = gray; % background color
eye_link_bk_color = gray;
text_color = black;
dot_color  = red;
rect_color = black;

%% Keyboard
% Setup MaxPriority for Keyboard Check function
priority    = MaxPriority('KbCheck'); 
oldPriority = Priority();

KbName('UnifyKeyNames');

% Keyboard recognition codes
escape_key = KbName('ESCAPE');
space_key = KbName('space');
q_key = KbName('q');
left_arrow = KbName('leftarrow');
right_arrow = KbName('rightarrow');

%% Windows
% Open windows
[wPtr, rect] = Screen('OpenWindow', scr_num, bk_color);

% HideCursor();

% Get the size of the screen 
scr_x = rect(3); % width of the screen
scr_y = rect(4); % length of the screen

xRange = [0 scr_x];
yRange = [0 scr_y];

%% Font
main_font = 'Arial';
big_font_size   = 72;
mid_font_size   = 54;
small_font_size = 36;

Screen('TextFont', wPtr , main_font);
Screen('TextFont', wPtr, '-:lang=zh-tw');

%% predertermine the ROI rect
baseLen   = scr_x*0.05;
baseSepX  = scr_x*0.01;
baseSepY  = scr_y*0.01;

margin = 2.5;
sensor_margin = [-baseSepX*margin -baseSepY*margin baseSepX*margin baseSepY*margin];

left_rect  = [0.2*scr_x 0.6*scr_y 0.45*scr_x 0.9*scr_y];
right_rect = [0.55*scr_x 0.6*scr_y 0.8*scr_x 0.9*scr_y];


if subj.treatment
    Screen('TextSize' , wPtr , big_font_size);
    main_text = double('?ñº 1 ??? ??? Âæ? Ôº? Â∞? ?î∂ ?à∞ 110 Ê≥? Âπ?');

    [~,~, rect_todaypay,~]          = DrawFormattedText(wPtr, '100' , 0.1*scr_x , 0.3*scr_y, bk_color);
    [~,~, rect_maintext,wordbounds] = DrawFormattedText(wPtr, main_text , 'center', 0.4*scr_y, bk_color, [], [], [], [], [], rect);
    
    % use bulid-in function wordbounds to attain the word rect
    rect_weeks    = [wordbounds(2,1), rect_maintext(2), wordbounds(4,3) ,rect_maintext(4)] + sensor_margin;
    rect_tokens   = [wordbounds(10,1),rect_maintext(2),wordbounds(12,3) ,rect_maintext(4)] + sensor_margin;
    rect_will     = [wordbounds(7,1), rect_maintext(2), wordbounds(7,3) ,rect_maintext(4)] + sensor_margin;
    
    rect_todaypay = rect_todaypay + sensor_margin;
    rect_maintext = rect_maintext + sensor_margin;
else
    Screen('TextSize' , wPtr , big_font_size);
    main_text = double('?ñº 1 ??? ??? Âæ? Ôº? ?î∂ ?à∞ 110 Ê≥? Âπ?');

    [~,~, rect_todaypay,~]          = DrawFormattedText(wPtr, '100' , 0.1*scr_x , 0.3*scr_y, bk_color);
    [~,~, rect_maintext,wordbounds] = DrawFormattedText(wPtr, main_text , 'center', 0.4*scr_y, bk_color, [], [], [], [], [], rect);
   
    % use bulid-in function wordbounds to attain the word rect
    rect_weeks    = [wordbounds(2,1), rect_maintext(2), wordbounds(4,3)  ,rect_maintext(4)] + sensor_margin;
    rect_tokens   = [wordbounds(9,1), rect_maintext(2), wordbounds(11,3) ,rect_maintext(4)] + sensor_margin;
    
    rect_todaypay = rect_todaypay + sensor_margin;
    rect_maintext = rect_maintext + sensor_margin;
end

% check ROI is good
% Screen('FrameRect', wPtr , red , rect_todaypay, 3);
% if subj.treatment
%     Screen('FrameRect', wPtr , red , rect_will, 3);
% end
% Screen('FrameRect', wPtr , red , rect_weeks, 3);
% Screen('FrameRect', wPtr , red , rect_tokens, 3);
% Screen('FrameRect', wPtr , red , left_rect, 3);
% Screen('FrameRect', wPtr , red , right_rect, 3);

%% Query the frame duration and set waitframe
Priority(priority); 
ifi = Screen('GetFlipInterval', wPtr); 
waitframes = 1;

%% Instructions
Screen('TextSize' , wPtr, mid_font_size);
text = double('Ë´ãË©≥Á¥∞Èñ±ËÆ?ÂØ¶È?óË™™???');
DrawFormattedText(wPtr, text , 'center' , 0.45*scr_y, text_color);
Screen('TextSize' ,wPtr , small_font_size);
text = double('??â‰?ãÈçµ?õ§ ??? ?èØ??çÂ?‰∏ã‰????');
DrawFormattedText(wPtr, text , 'center' , 0.7*scr_y, text_color);
text = double('??â‰?ãÈçµ?õ§ ??? ?èØ??ûÂà∞‰∏ä‰????');
DrawFormattedText(wPtr, text , 'center' , 0.8*scr_y, text_color);

Screen('Flip', wPtr); % flip instruction to the screen
KbStrokeWait;

page = 1;
while page <= 15
    
    show_image(1,page,1);
    
    [~, ~, key] = KbCheck();
    if key(KbName('rightarrow'))
        page = page + 1;
        WaitSecs(0.5);
    elseif key(KbName('leftarrow'))
        if page ~= 1
            page = page - 1;
        end
        WaitSecs(0.5);
    elseif key(KbName('ESCAPE'))
        ShowCursor;
        sca;
        return
    end
        
end    

   %% Experiment

try
    % Provide Eyelink with details about the graphics environment
    % and perform some initializations. The information is returned
    % in a structure that also contains useful defaults
    % and control codes (e.g. tracker state bit and Eyelink key values).
    if ~dummy_mode 
        
        el = EyelinkInitDefaults(wPtr);
        
        % Initialization of the connection with the Eyelink Gazetracker.
        % exit program if this fails.
        if ~EyelinkInit(dummy_mode) % Initializes Eyelink and Ethernet system. Returns: 0 if OK, -1 if error
            error('could not init connection to Eyelink')
        end
        
        % check the software version
        [v , vs] = Eyelink('GetTrackerVersion');
        fprintf('Running experiment on a ''%s'' tracker.\n', vs);
        
        % open file to record data to %
        if createFile
            status = Eyelink('openfile',edfFile);
            % open EDF file (auto recording? what's the results of this?)
            if status~=0
                fprintf('Cannot create EDF file ''%s''\n', edfFile);
                Eyelink('Shutdown');
                Screen('CloseAll');
                return;
            end
        end
        
        % SET UP TRACKER CONFIGURATION
        % Setting the proper recording resolution, proper calibration type, 
        % as well as the data file content;
        Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, scr_x-1, scr_y-1);
        Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, scr_x-1, scr_y-1);                
        % set calibration type.
        Eyelink('command', 'calibration_type = HV9');

        % set EDF file contents using the file_sample_data and
        % file-event_filter commands
        % set link data through link_sample_data and link_event_filter
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,INPUT');
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,INPUT');
        
        Eyelink('command', 'file_sample_data  = GAZE,AREA,GAZERES,STATUS,INPUT');
        Eyelink('command', 'link_sample_data  = GAZE,AREA,GAZERES,STATUS,INPUT');
        
        % make sure we're still connected.
        if Eyelink('IsConnected')~=1
            fprintf('not connected, clean up\n');
            Eyelink('ShutDown');
            Screen('CloseAll');
            return;
        end
        
        % Calibrate the eye tracker
        % setup the proper calibration foreground and background colors
        el.backgroundcolour = eye_link_bk_color;
        el.calibrationtargetcolour = dot_color;

        % parameters are in frequency, volume, and duration
        % set the second value in each line to 0 to turn off the sound
        el.cal_target_beep=[600 0.2 0.05];
        el.drift_correction_target_beep=[600 0.2 0.05];
        el.calibration_failed_beep=[400 0.2 0.25];
        el.calibration_success_beep=[800 0.2 0.25];
        el.drift_correction_failed_beep=[400 0.2 0.25];
        el.drift_correction_success_beep=[600 0.2 0.25];
        % you must call this function to apply the changes from above
        EyelinkUpdateDefaults(el);
        
        % Hide the mouse cursor
        Screen('HideCursorHelper', wPtr);
        % Calibration
        EyelinkDoTrackerSetup(el); 
 
    end % of not dummy mode    
    
    % Hide mouse cursor
    HideCursor();
    
    while 1
        show_image(1,16,1);
        [~, ~, key] = KbCheck();
        if key(KbName('rightarrow'))
            WaitSecs(0.5); 
            break
        elseif key(KbName('ESCAPE'))
            sca
            break
        end
    end
    
    for t = 1:T
        
      %% record trial index
     if ismember(t,(start_quiz_first : start_prac_trial-1))
         hist.trial_index(t) = 200 + t; % index 201-207 for quiz_first
     elseif ismember(t,(start_prac_trial : start_stage_first -1))
         hist.trial_index(t) = 100 + t - num_quiz_first; % index 101-103 for prac_trial
     elseif ismember(t, (start_stage_first : start_quiz_second -1))
         hist.trial_index(t) = t - num_quiz_first - num_prac_trial; % index 1-36 for first stage
     elseif ismember(t,(start_quiz_second : start_stage_second - 1))
         hist.trial_index(t) = 200 + t - num_prac_trial -TT/2; % index 208-209 for quiz_second
     else
         hist.trial_index(t) = t - num_quiz_first - num_prac_trial - num_quiz_second; % index 37-72 for second stage
     end
     disp(['trial_index = ', num2str(hist.trial_index(t))]);
     
        %% Preface before this trial
     Screen('Flip', wPtr);
     if t == start_quiz_first % Comprehension quiz for the first stage
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('?Ç∫‰∫ÜÁ¢∫‰øùÊÇ®‰∫ÜËß£ÂØ¶È?óÁ?ÑÈ?≤Ë?åÊñπÂºèÔ?åË?ãÊÇ®ÂÆåÊ?ê‰ª•‰∏ãÁ?ÑÊòØ??ûÈ?å„??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.3*scr_y, text_color);
            pre_text = double('??öÈÅ∏??áÊ?ÇÔ?åË?ãÊÇ®??ãË?óÈÅ∏??ÖÔ?àÊ?áÂ?óÊ?ÉË?äÊ?êÁ?ÖËâ≤ÔºâÔ?å‰∏¶??â‰?ãÁ©∫?ôΩ?çµ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = double('?Ç®Â°´Á?îÁ?ÑÁ?êÊ?ú‰?çÊ?ÉÂΩ±?üø?Ç®??ÑÂØ¶È©óÁ?éÂãµÔº?');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            pre_text = double('‰ΩÜÊÇ®??Ë¶ÅÊ≠£Á¢∫Âú∞??ÜËß£ÂØ¶È?óÂÖßÂÆπÊ?çËÉΩ??ãÂ?ãÂØ¶È©ó„??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.7*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
     elseif t == start_prac_trial  % Practice trials
            Screen('TextSize' , wPtr , mid_font_size);
            pre_text = double('?Ç∫‰∫ÜË?ìÊÇ®??üÊ?âÁ?â‰?‰∏ãÂØ¶È©ó‰∏≠??ÑÈÅ∏??áÊñπÂºèÔ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.3*scr_y, text_color);
            pre_text = double('?é•‰∏ã‰?ÜÊ?ÉÈ?≤Ë?å‰?âÂ?ûÂ?àÁ?ÑÁ∑¥Áøí„??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = double('?ô‰?âÂ?ûÂ?àÁ?ÑÁ∑¥ÁøíÔ?å‰∏¶‰∏çÊ?ÉÁ?óÂÖ•ÂØ¶È?óÁ?éÂãµ‰∏≠„??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
            Screen('TextSize' , wPtr , mid_font_size);
            pre_text = double('Á∑¥Á?íÈ?éÊÆµ');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.2*scr_y, text_color);
            pre_text = double('?é•‰∏ã‰?ÜÁ?ÑÂ?èÈ?åË£°Ôºå„?å‰?äÂ§©?çÁ?ÑÈÅ∏??ÖÈÉΩ?òØÔº?');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = num2str(110);
            DrawFormattedText(wPtr, pre_text , 0.52*scr_x , 0.5*scr_y, red);
            pre_text = double('?ñº‰ªäÂ§©ÔºåÊî∂?à∞               ??öÊ?ïÂπ£');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.5*scr_y, text_color);
            pre_text = double('Ë´ãÊ?îË?ÉÂ?ÑÂ?ã„?åÊú™‰æÜ„?çÁ?ÑÈÅ∏??ÖÂ?åÂ?öÂá∫?Å∏???'); 
            DrawFormattedText(wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);            
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
     elseif t == (num_quiz_first + num_prac_trial + 1) % first stage
            Screen('TextSize' , wPtr , mid_font_size);
            pre_text = double('Á∑¥Á?íÂ?ûÂ?àÁ?êÊ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.3*scr_y, text_color);
            pre_text = double('‰ª•‰?ãÁÇ∫ 36 ?ãÂ?ûÂ?àÁ?ÑÊ≠£ÂºèÂØ¶È©óÔ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = double('ÊØèÂ?ûÂ?àÁ?ÑÈÅ∏??áÔ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.5*scr_y, text_color);
            pre_text = double('??ÜÊ?âÊ?üÊ?ÉÂ?åÁèæ??êÊÇ®??ÑÊ?ÂæåÁ?éÂãµ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
            Screen('TextSize' , wPtr , mid_font_size);
            pre_text = double('Á¨¨‰???éÊÆµ');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.2*scr_y, text_color);
            pre_text = double('?é•‰∏ã‰?ÜÁ?ÑÂ?èÈ?åË£°Ôºå„?å‰?äÂ§©?çÁ?ÑÈÅ∏??ÖÈÉΩ?òØÔº?');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = num2str(subj.first_stage);
            DrawFormattedText(wPtr, pre_text , 0.52*scr_x , 0.5*scr_y, red);
            pre_text = double('?ñº‰ªäÂ§©ÔºåÊî∂?à∞               ??öÊ?ïÂπ£');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.5*scr_y, text_color);
            pre_text = double('Ë´ãÊ?îË?ÉÂ?ÑÂ?ã„?åÊú™‰æÜ„?çÁ?ÑÈÅ∏??ÖÂ?åÂ?öÂá∫?Å∏???'); 
            DrawFormattedText(wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);            
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
      elseif t == (num_quiz_first + num_prac_trial + (TT/2) + 1) % Comprehension quiz for the first stage
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('?Ç∫‰∫ÜÁ¢∫‰øùÊÇ®‰∫ÜËß£ÂØ¶È?óÁ?ÑÈ?≤Ë?åÊñπÂºèÔ?åË?ãÊÇ®ÂÆåÊ?ê‰ª•‰∏ãÁ?ÑÊòØ??ûÈ?å„??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.3*scr_y, text_color);
            pre_text = double('??öÈÅ∏??áÊ?ÇÔ?åË?ãÊÇ®??ãË?óÈÅ∏??ÖÔ?àÊ?áÂ?óÊ?ÉË?äÊ?êÁ?ÖËâ≤ÔºâÔ?å‰∏¶??â‰?ãÁ©∫?ôΩ?çµ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = double('?Ç®Â°´Á?îÁ?ÑÁ?êÊ?ú‰?çÊ?ÉÂΩ±?üø?Ç®??ÑÂØ¶È©óÁ?éÂãµÔº?');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            pre_text = double('‰ΩÜÊÇ®??Ë¶ÅÊ≠£Á¢∫Âú∞??ÜËß£ÂØ¶È?óÂÖßÂÆπÊ?çËÉΩ??ãÂ?ãÂØ¶È©ó„??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.7*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
       elseif t == (num_quiz_first + num_prac_trial + (TT/2) +  num_quiz_second + 1) % second stage
            Screen('TextSize' , wPtr , mid_font_size);
            pre_text = double('??ÜËß£Ê∏¨È?óÁ?êÊ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.3*scr_y, text_color);
            pre_text = double('‰ª•‰?ãÁÇ∫ 36 ?ãÂ?ûÂ?àÁ?ÑÊ≠£ÂºèÂØ¶È©óÔ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = double('ÊØèÂ?ûÂ?àÁ?ÑÈÅ∏??áÔ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.5*scr_y, text_color);
            pre_text = double('??ÜÊ?âÊ?üÊ?ÉÂ?åÁèæ??êÊÇ®??ÑÊ?ÂæåÁ?éÂãµ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
            Screen('TextSize' , wPtr , mid_font_size);
            pre_text = double('Á¨¨‰?åÈ?éÊÆµ');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.2*scr_y, text_color);
            pre_text = double('?é•‰∏ã‰?ÜÁ?ÑÂ?èÈ?åË£°Ôºå„?å‰?äÂ§©?çÁ?ÑÈÅ∏??ÖÈÉΩ?òØÔº?');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.4*scr_y, text_color);
            pre_text = num2str(subj.second_stage);
            DrawFormattedText(wPtr, pre_text , 0.52*scr_x , 0.5*scr_y, red);
            pre_text = double('?ñº‰ªäÂ§©ÔºåÊî∂?à∞               ??öÊ?ïÂπ£');
            DrawFormattedText(wPtr, pre_text , 'center' , 0.5*scr_y, text_color);
            pre_text = double('Ë´ãÊ?îË?ÉÂ?ÑÂ?ã„?åÊú™‰æÜ„?çÁ?ÑÈÅ∏??ÖÂ?åÂ?öÂá∫?Å∏???'); 
            DrawFormattedText(wPtr, pre_text , 'center' , 0.6*scr_y, text_color);
            Screen('TextSize' , wPtr , small_font_size);            
            pre_text = double('??âÁ©∫?ôΩ?çµÁπºÁ??');
            DrawFormattedText( wPtr, pre_text , 'center' , 0.9*scr_y, text_color);            
            Screen('Flip', wPtr);
            KbStrokeWait;
     end
     
            %% do tracker setup for each trial
        if ~dummy_mode
            if subj.treatment
                imgfile = 'treatment_screen.bmp';
            else
                imgfile = 'control_screen.bmp';
            end
            transferimginfo=imfinfo(imgfile); % load a image to use on the host pc

            % This message provide data viewer the trial ID
            Eyelink('Message', 'TRIALID %d', hist.trial_index(t)); 
            % This supplies the title at the bottom of the eyetracker display
            Eyelink('command', 'record_status_message "TRIAL %d / %d"', t , T);
            % Before recording, we place reference graphics on the host display
            % Must be offline to draw to EyeLink screen
            Eyelink('Command', 'set_idle_mode');
            % clear tracker display and draw box at center
            Eyelink('Command', 'clear_screen 0');
            Eyelink('command', 'draw_box %d %d %d %d 15', 0, 0, scr_x, scr_y);
            
            %transfer image to host 
            % image file should be 24bit or 32bit bitmap
            % parameters of ImageTransfer:
            % imagePath, xPosition, yPosition, width, height, trackerXPosition, trackerYPosition, xferoptions
            transferStatus =  Eyelink('ImageTransfer',transferimginfo.Filename,0,0,transferimginfo.Width,transferimginfo.Height,...
                                                        scr_x/2-transferimginfo.Width/2 ,scr_y/2-transferimginfo.Height/2,1);
            if transferStatus ~= 0
                fprintf('*****Image transfer Failed*****-------\n');
            end

            WaitSecs(0.1);

            % start recording eye position (preceded by a short pause so that 
            % the tracker can finish the mode transition)
            % The paramerters for the 'StartRecording' call controls the
            % file_samples, file_events, link_samples, link_events availability
            Eyelink('Command', 'set_idle_mode');
            WaitSecs(0.05);   
            
            % drift correction before the start of a trial
            EyelinkDoDriftCorrection(el);
            
            WaitSecs(0.1);
            Eyelink('StartRecording');    
            % record a few samples before we actually start displaying
            % otherwise you may lose a few msec of data 
            WaitSecs(0.1);

            % used for syncing time
            Eyelink('Message', 'Start Recording'); 

            % Eyelink('Message', '!V TRIAL_VAR VALID_TRIAL %d', 1);

            eye_used = Eyelink('eyeavailable');
            
        else % if dummy mode

            % Draw fixation screen
            Screen('FillRect', wPtr, bk_color);
            Screen('DrawDots', wPtr, [0.5*scr_x 0.5*scr_y] , dot_size , dot_color);
            % Flip to the screen
            Screen('Flip', wPtr);
            WaitSecs(fix_time);

        end % end of if ~dummy mode
            
                %% Give host PC ROI (use predetermine ROI)
        if ~dummy_mode

            Eyelink('Message', 'Trail Start'); % Sync time
            
            % Send an integration message so that an image can be loaded as 
            % overlay backgound when performing Data Viewer analysis.  This 
            % message can be placed anywhere within the scope of a trial (i.e.,
            % after the 'TRIALID' message and before 'TRIAL_RESULT')
            % See "Protocol for EyeLink Data to Viewer Integration -> Image 
            % Commands" section of the EyeLink Data Viewer User Manual.
            Eyelink('Message', '!V IMGLOAD CENTER %s %d %d', imgfile, scr_x/2, scr_y/2);
            Eyelink('Message', '!V IMGLOAD FILL %s', imgfile);

            % Draw ROIs
            if subj.treatment
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 1, floor(rect_todaypay(1)), floor(rect_todaypay(2)) , floor(rect_todaypay(3)), floor(rect_todaypay(4)), 'rect_todaypay');
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 2, floor(rect_maintext(1)), floor(rect_maintext(2)) , floor(rect_maintext(3)), floor(rect_maintext(4)) , 'rect_maintext' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 3, floor(rect_weeks(1)),    floor(rect_weeks(2)) ,    floor(rect_weeks(3)),    floor(rect_weeks(4)) ,    'rect_weeks' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 4, floor(rect_tokens(1)),   floor(rect_tokens(2)) ,   floor(rect_tokens(3)),   floor(rect_tokens(4)) ,   'rect_tokens' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 5, floor(left_rect(1)), floor(left_rect(2)) , floor(left_rect(3)), floor(left_rect(4)) , 'leftrect' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 6, floor(right_rect(1)),floor(right_rect(2)) ,floor(right_rect(3)),floor(right_rect(4)) ,'rightrect');
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 7, floor(rect_will(1)),     floor(rect_will(2)) ,     floor(rect_will(3)),     floor(rect_will(4)) ,     'rect_will');

            else
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 1, floor(rect_todaypay(1)), floor(rect_todaypay(2)) , floor(rect_todaypay(3)), floor(rect_todaypay(4)) , 'rect_todaypay' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 2, floor(rect_maintext(1)), floor(rect_maintext(2)) , floor(rect_maintext(3)), floor(rect_maintext(4)) , 'rect_maintext' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 3, floor(rect_weeks(1)),    floor(rect_weeks(2)) ,    floor(rect_weeks(3)),    floor(rect_weeks(4)) ,    'rect_weeks' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 4, floor(rect_tokens(1)),   floor(rect_tokens(2)) ,   floor(rect_tokens(3)),   floor(rect_tokens(4)) ,   'rect_tokens' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 5, floor(left_rect(1)), floor(left_rect(2)) , floor(left_rect(3)), floor(left_rect(4)) , 'leftrect' );
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 6, floor(right_rect(1)),floor(right_rect(2)) ,floor(right_rect(3)),floor(right_rect(4)) ,'rightrect');
                % Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 7, floor(rect_will(1)),     floor(rect_will(2)),     floor(rect_will(3)),     floor(rect_will(4)),     'rect_will');

            end

            
        end % of ~dummy mode
        
               %% Trial Screen
        
        vbl = Screen('Flip', wPtr);
        
        s_choice = GetSecs; % record response time (start)

        dec_made = 0;
        
        if dummy_mode
            SetMouse(scr_x/2, scr_y/2 , wPtr);
            ShowCursor('Arrow');
        end
        
        
        while 1

            if ~dummy_mode

                % Check recording status, stop display if error
                err = Eyelink('CheckRecording');

                if(err~=0)
                    error('checkrecording problem, status: %d',err)
                end

                % check for presence of a new sample update
                status = Eyelink('NewFloatSampleAvailable'); 
                % satus = -1 (none or error) ; 0 (old) ; 1 (new)

                if status ~= 1
                   fprintf('no sample available, status: %d\n',status)
                end

            end  % of not dummy mode  
            
            
            [today_pay, main_text, sub_text, left_text, right_text] = print_screen(t);
            
            
            % Check for the position of the mouse/eye
            if dummy_mode
                [mx, my, ~] = GetMouse(wPtr);
            else
                evt = Eyelink('NewestFloatSample');

                mx = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array (Why?)
                my = evt.gy(eye_used+1);
                mx = scr_x*((mx-min(xRange))/range(xRange)); % calculateing the corresponding x position (a ratio)
                my = scr_y*((my-min(yRange))/range(yRange));
            end
            
            inside_leftrect  = IsInRect(mx, my, left_rect);
            inside_rightrect = IsInRect(mx, my, right_rect);
            
            % Set the color red if the mouse is inside
            if inside_leftrect
                left_color = red;
            else
                left_color = black;
            end

            if inside_rightrect
                right_color = red;
            else
                right_color = black;
            end
            
            adjust_font_trial = [5,6,7,48];
            if ismember(t, adjust_font_trial)
                Screen('TextSize' , wPtr , mid_font_size);
                DrawFormattedText(wPtr, main_text , 'center', 0.3*scr_y, text_color, [], [], [], [], [], rect);
                DrawFormattedText(wPtr,  sub_text , 'center', 0.4*scr_y, text_color, [], [], [], [], [], rect);
            else
                Screen('TextSize' , wPtr , big_font_size);
                DrawFormattedText(wPtr, today_pay , 0.1*scr_x, 0.3*scr_y, text_color, [], [], [], [], [], rect);
                DrawFormattedText(wPtr, main_text , 'center', 0.4*scr_y, text_color, [], [], [], [], [], rect);
                Screen('TextSize' , wPtr , mid_font_size);
                DrawFormattedText(wPtr,  sub_text , 'center', 0.5*scr_y, text_color, [], [], [], [], [], rect);
            end
            Screen('TextSize' , wPtr , big_font_size);
            Screen('FrameRect', wPtr, rect_color, left_rect, 2);
            Screen('FrameRect', wPtr, rect_color, right_rect, 2);    
            DrawFormattedText(wPtr, left_text  , 'center', 'center', left_color, [], [], [], [], [], left_rect);
            DrawFormattedText(wPtr, right_text , 'center', 'center', right_color, [], [], [], [], [], right_rect);

            
            [~,~, keyCode] = KbCheck;
            
            quiz_trial  = [1,2,3,4,5,6,7,47,48];
            quiz_answer = [1,1,0,0,1,0,1,0,0];
            
            if keyCode(space_key) && inside_leftrect

                    if ~dummy_mode
                        Eyelink('Message', 'Choice Made'); % choice made and confirm
                    end
                        
                    if ismember(t,quiz_trial) % leftrect is always "yes" for the quizzes
                        if ismember(t,[1,2,5,7])
                            hist.choose_future(t) = 1; dec_made = 1; % chose the correct answer
                            show_image(0,t,1);KbStrokeWait;
                        else
                            hist.choose_future(t) = 0; dec_made = 1; % chose the correct answer
                            show_image(0,t,0);KbStrokeWait;
                        end
                    else    
                        if hist.left_is_future(t) == 1
                            hist.choose_future(t) = 1; dec_made = 1;
                        else
                            hist.choose_future(t) = 0; dec_made = 1;
                        end
                    end    

                        
             elseif keyCode(space_key) && inside_rightrect  
                     
                    if ~dummy_mode
                        Eyelink('Message', 'Choice Made'); % choice made and confirm
                    end
                    
                    if ismember(t,quiz_trial) % rightrect is always "no" for the quizzes
                        if ismember(t,[3,4,6,47,48])
                            hist.choose_future(t) = 1; dec_made = 1; % chose the correct answer
                            show_image(0,t,1);KbStrokeWait;
                        else
                            hist.choose_future(t) = 0; dec_made = 1; % chose the correct answer
                            show_image(0,t,0);KbStrokeWait;
                        end
                    else                          
                        if hist.left_is_future(t) == 1
                            hist.choose_future(t) = 0; dec_made = 1;
                        else
                            hist.choose_future(t) = 1; dec_made = 1;
                        end
                    end
                    
            end % end of if space
                    
                if dec_made 
                     s_choice_made = GetSecs; % record response time (ends)
                     break % the while loop 
                end

            [~,~, keyCode] = KbCheck;
            if keyCode(escape_key)
                ShowCursor;
                sca;
                return
            end % end of if keyCode(escape_key)
            
            % Screen('Flip', wPtr); 
            vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);

        end % of while
        
        hist.response_time(t) = s_choice_made - s_choice;           
    
        if ~dummy_mode
            Eyelink('Message', 'Stop Recording'); % end of trial
            Eyelink('StopRecording');
            Eyelink('Message', 'TRIAL_RESULT %d', hist.trial_index(t));
        end 
        

             %% REST, after the first stage

        if ismember(t,rest_t)
            
            while 1
                [~,~,keyCode] = KbCheck;
                if keyCode(escape_key)
                    break
                end

                % Draw ending screen            
                Screen('TextSize' , wPtr , mid_font_size);
                rest_text = double('Á¨¨‰???éÊÆµÁµêÊ??');
                DrawFormattedText( wPtr, rest_text , 'center' , 0.3*scr_y, text_color);
                rest_text = double('?èæ?ú®?òØ‰∏≠È?î‰?ëÊÅØ??ÇÈ?ìÔ?åÈ†≠?èØ‰ª•Èõ¢??ã‰?ãÂ∑¥?û∂Ê¥ªÂ?ï‰?‰∏?');
                DrawFormattedText( wPtr, rest_text , 'center' , 0.5*scr_y, text_color);
                rest_text = double('Ê∫ñÂ?ôÂ•Ω‰∫ÜÂ?çÈñ±ËÆ?Á¨¨‰?åÈ?éÊÆµ??ÑÂØ¶È©óË™™???');
                DrawFormattedText( wPtr, rest_text , 'center' , 0.6*scr_y, text_color);
                Screen('TextSize' , wPtr , small_font_size);
                rest_text = double('Â¶ÇÊ?úË?ÅÁπºÁ∫å‰?ã‰???éÊÆµÔºåË?ãÊ?â‰?? ESC ?çµ');
                DrawFormattedText( wPtr, rest_text , 'center' , 0.9*scr_y, text_color);

                % Flip to the screen
                vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
            end % of while
         
            
            % Instructions for second stage
            page = 41;
            while page <= 46

                    show_image(1,page,1);

                [~, ~, key] = KbCheck();
                if key(KbName('rightarrow'))
                    page = page + 1;
                    WaitSecs(0.5);
                elseif key(KbName('leftarrow'))
                    if page ~= 1
                        page = page - 1;
                    end
                    WaitSecs(0.5);
                end

            end
            
            % Calibration before the second stage
            if ~dummy_mode  
                EyelinkDoTrackerSetup(el);
            end
            
           while 1
                show_image(1,47,1);
                [~, ~, key] = KbCheck();
                if key(KbName('rightarrow'))
                    WaitSecs(0.5); 
                    break
                elseif key(KbName('ESCAPE'))
                    sca
                    break
                end
            end
            
        end % end of rest
        
        % HideCursor();
                
            
     end % end of for t = 1:T 
   
%% Calculate payoff
    if hist.choose_future(hist.pi_trial(1)) == 1
        hist.pi_weeks(1) = hist.weeks_delayed(hist.pi_trial(1));
        hist.pi_token(1) = hist.future_pay(hist.pi_trial(1));
    else
        hist.pi_weeks(1) = 0;
        hist.pi_token(1) = hist.today_pay(hist.pi_trial(1));
    end
    if hist.choose_future(hist.pi_trial(2)) == 1
        hist.pi_weeks(2) = hist.weeks_delayed(hist.pi_trial(2));
        hist.pi_token(2) = hist.future_pay(hist.pi_trial(2));
    else
        hist.pi_weeks(2) = 0;
        hist.pi_token(2) = hist.today_pay(hist.pi_trial(2));
    end    
    
    hist.pi_days =  hist.pi_weeks * 7;
    hist.pi_money = hist.pi_token * token_exchange_rate;
    hist.pi_money(3) = show_up_fee;

    %% Show the payofff
    
    Screen('Flip', wPtr);
    Screen('TextSize' , wPtr , mid_font_size);
    DrawFormattedText( wPtr, 'Á¨¨‰???éÊÆµ??ÑÂØ¶È©óÁ?éÂãµ' , 'center' , 0.12*scr_y, text_color);
    Screen('TextSize' , wPtr , small_font_size);
    pi_text = ['?õª?Ö¶?Å∏‰∏≠Á¨¨ ' num2str(hist.pi_trial(1) - 10) ' ??ûÂ??'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.3*scr_y, text_color);
    pi_text = ['?å‰?äÂ§©?çÔ?öÊñº‰ªäÂ§©ÔºåÊî∂?à∞ ' num2str(hist.today_pay(hist.pi_trial(1))) ' Ê≥ïÂπ£'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.4*scr_y, text_color);
    if subj.treatment == 1
        pi_text = ['?åÊú™‰æÜ„?çÔ?öÊñº' num2str(hist.weeks_delayed(hist.pi_trial(1))) '??üÊ?üÂ?åÔ?åÂ?áÊî∂?à∞ ' num2str(hist.future_pay(hist.pi_trial(1))) ' Ê≥ïÂπ£'];
    else
        pi_text = ['?åÊú™‰æÜ„?çÔ?öÊñº' num2str(hist.weeks_delayed(hist.pi_trial(1))) '??üÊ?üÂ?åÔ?åÊî∂?à∞ ' num2str(hist.future_pay(hist.pi_trial(1))) ' Ê≥ïÂπ£'];
    end
    DrawFormattedText(wPtr, pi_text , 'center' , 0.5*scr_y, text_color);
    if hist.choose_future(hist.pi_trial(1)) == 1
        pi_text = '?Ç®?Å∏??áÁ?ÑÊòØ?åÊú™‰æÜ„??';
        pay_token = ['??‰ª•Ô?åÊÇ®??ÉÊñº ' num2str(hist.pi_weeks(1)) ' ??üÊ?üÂ?åÔ?åÊî∂?à∞ ' num2str(hist.pi_token(1)) ' Ê≥ïÂπ£??ÑÂåØÊ¨?'];
        pay_money = ['ÔºàÂç≥?ñ∞?è∞Âπ? ' num2str(hist.pi_money(1)) ' ??ÉÔ??'];
    else
        pi_text = '?Ç®?Å∏??áÁ?ÑÊòØ?å‰?äÂ§©??';
        pay_token = ['??‰ª•Ô?åÊÇ®??ÉÊñº‰ªäÂ§©ÔºåÊî∂?à∞ ' num2str(hist.pi_token(1)) ' Ê≥ïÂπ£??ÑÂåØÊ¨?'];
        pay_money = ['ÔºàÂç≥?ñ∞?è∞Âπ? ' num2str(hist.pi_money(1)) ' ??ÉÔ??'];
    end
    DrawFormattedText(wPtr, pi_text , 'center' , 0.6*scr_y, text_color);
    DrawFormattedText(wPtr, pay_token , 'center' , 0.7*scr_y, text_color);
    DrawFormattedText(wPtr, pay_money , 'center' , 0.8*scr_y, text_color);
    pi_text = double('??âÁ©∫?ôΩ?çµ??ãÁ¨¨‰∫åÈ?éÊÆµ');
    DrawFormattedText(wPtr, pi_text , 'center' , 0.9*scr_y, text_color);
    Screen('Flip', wPtr);
    KbStrokeWait;
    
    Screen('TextSize' , wPtr , mid_font_size);
    DrawFormattedText( wPtr, 'Á¨¨‰?åÈ?éÊÆµ??ÑÂØ¶È©óÁ?éÂãµ' , 'center' , 0.12*scr_y, text_color);
    Screen('TextSize' , wPtr , small_font_size);
    pi_text = ['?õª?Ö¶?Å∏‰∏≠Á¨¨ ' num2str(hist.pi_trial(2) - 48) ' ??ûÂ??'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.3*scr_y, text_color);
    pi_text = ['?å‰?äÂ§©?çÔ?öÊñº‰ªäÂ§©ÔºåÊî∂?à∞ ' num2str(hist.today_pay(hist.pi_trial(2))) ' Ê≥ïÂπ£'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.4*scr_y, text_color);
    if subj.treatment == 1
        pi_text = ['?åÊú™‰æÜ„?çÔ?öÊñº' num2str(hist.weeks_delayed(hist.pi_trial(2))) '??üÊ?üÂ?åÔ?åÂ?áÊî∂?à∞ ' num2str(hist.future_pay(hist.pi_trial(2))) ' Ê≥ïÂπ£'];
    else
        pi_text = ['?åÊú™‰æÜ„?çÔ?öÊñº' num2str(hist.weeks_delayed(hist.pi_trial(2))) '??üÊ?üÂ?åÔ?åÊî∂?à∞ ' num2str(hist.future_pay(hist.pi_trial(2))) ' Ê≥ïÂπ£'];
    end
    DrawFormattedText(wPtr, pi_text , 'center' , 0.5*scr_y, text_color);
    if hist.choose_future(hist.pi_trial(2)) == 1
        pi_text = '?Ç®?Å∏??áÁ?ÑÊòØ?åÊú™‰æÜ„??';
        pay_token = ['??‰ª•Ô?åÊÇ®??ÉÊñº ' num2str(hist.pi_weeks(2)) ' ??üÊ?üÂ?åÔ?åÊî∂?à∞ ' num2str(hist.pi_token(2)) ' Ê≥ïÂπ£??ÑÂåØÊ¨?'];
        pay_money = ['ÔºàÂç≥?ñ∞?è∞Âπ? ' num2str(hist.pi_money(2)) ' ??ÉÔ??'];
    else
        pi_text = '?Ç®?Å∏??áÁ?ÑÊòØ?å‰?äÂ§©??';
        pay_token = ['??‰ª•Ô?åÊÇ®??ÉÊñº‰ªäÂ§©ÔºåÊî∂?à∞ ' num2str(hist.pi_token(2)) ' Ê≥ïÂπ£??ÑÂåØÊ¨?'];
        pay_money = ['ÔºàÂç≥?ñ∞?è∞Âπ? ' num2str(hist.pi_money(2)) ' ??ÉÔ??'];
    end
    DrawFormattedText(wPtr, pi_text , 'center' , 0.6*scr_y, text_color);
    DrawFormattedText(wPtr, pay_token , 'center' , 0.7*scr_y, text_color);
    DrawFormattedText(wPtr, pay_money , 'center' , 0.8*scr_y, text_color);
    pi_text = double('??âÁ©∫?ôΩ?çµ??ãÁ∏Ω?†±?Ö¨');
    DrawFormattedText(wPtr, pi_text , 'center' , 0.9*scr_y, text_color);
    Screen('Flip', wPtr);
    KbStrokeWait;
    
    hist.pi_date  = datestr(now + hist.pi_days ,'yyyyÂπ? mm??? dd?ó•');
    hist.pi_total = hist.pi_money(1) + hist.pi_money(2) + hist.pi_money(3);
    Screen('TextSize' , wPtr , mid_font_size);
    DrawFormattedText( wPtr, 'Á∏ΩÂ†±?Ö¨' , 'center' , 0.12*scr_y, text_color);
    Screen('TextSize' , wPtr , small_font_size);
    pi_text = 'ËªäÈ¶¨Ë≤ªÔ?àÁèæ??ëÊîØ‰ªòÔ?âÔ?öÊñ∞?è∞Âπ? 100 ???';
    DrawFormattedText(wPtr, pi_text , 'center' , 0.3*scr_y, text_color);
    pi_text = ['Á¨¨‰???éÊÆµÔºàÂåØÊ¨æÔ?âÔ??' hist.pi_date(1,:) 'ÔºåÊñ∞?è∞Âπ? ' num2str(hist.pi_money(1)) ' ???'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.4*scr_y, text_color);
    pi_text = ['Á¨¨‰?åÈ?éÊÆµÔºàÂåØÊ¨æÔ?âÔ??' hist.pi_date(2,:)  'ÔºåÊñ∞?è∞Âπ? ' num2str(hist.pi_money(2)) ' ???'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.5*scr_y, text_color);
    pi_text = ['Á∏ΩÂ†±?Ö¨ÔºöÊñ∞?è∞Âπ? ' num2str(hist.pi_total) ' ???'];
    DrawFormattedText(wPtr, pi_text , 'center' , 0.6*scr_y, text_color);
    end_text = 'ÂØ¶È?óÁ?êÊ?üÔ?åÁ¢∫Ë™çÂ?åË?ãË?âÊ?ãÂ?äÁü•ÂØ¶È?ó‰∫∫?ì°';
    DrawFormattedText(wPtr, end_text , 'center' , 0.8*scr_y, text_color);
    end_text = double('‰∏¶Ê?ñÂ?ôÁßª??ïÂà∞?è¶‰∏??è∞?õª?Ö¶Â°´ÂØ´??èÂç∑');
    DrawFormattedText(wPtr, end_text , 'center' , 0.9*scr_y, text_color);
    Screen('Flip', wPtr);
    
    while 1
        [~,~,keyCode] = KbCheck;
        if keyCode(q_key)
            break
        end
    end
    hist.pi_trial = hist.pi_trial - [10,48]; % adjust pi trial to two of 72 formal trial (original index was for 84 total trial)
    
    %% Make the Data Table
    trial_index    = hist.trial_index';
    today_pay      = hist.today_pay';
    weeks_delayed  = hist.weeks_delayed';
    future_pay     = hist.future_pay';
    left_is_future = hist.left_is_future';
    choose_future  = hist.choose_future';
    response_time  = hist.response_time';

    choice_table = table(trial_index, today_pay, weeks_delayed, future_pay, left_is_future, choose_future, response_time);
    
    if ismember(0,hist.pi_days)
        trans_today = "‰ªäÂ§©Ë¶ÅÂåØÊ¨æÔ??";
    else
        trans_today = 'Ë®òÂ?óÈ?êÁ??';
    end 

    bank_trans_info = {hist.ID, datestr(now,'yyyyÂπ? mm??? dd?ó•'), hist.pi_date(1,:), [num2str(hist.pi_money(1)) ' ???'], ...
        hist.pi_date(2,:), [num2str(hist.pi_money(2)) ' ???'], trans_today};
    bank = cell2table(bank_trans_info);
    bank_trans_table = vertcat(pay_o, bank);
    
%% Save Data
    
    if save_file
        writetable(choice_table, xlsxFile);
        save(FileName);
        writetable(bank_trans_table, ['bank_transfer','.xlsx']);
    end
    
    %% Shutdown eye-tracker and get data from host PC
    if ~dummy_mode
        
        % End of Experiment; close the file first   
        % close graphics window, close data file and shut down tracker

        Eyelink('Command', 'set_idle_mode');
        WaitSecs(0.5);
        Eyelink('CloseFile');
        Priority(oldPriority);
        
        % download data file 
        try
            fprintf('Receiving data file ''%s''\n', edfFile );            
            status=Eyelink('ReceiveFile',edfFile,pwd,1);
            % [status =] Eyelink('ReceiveFile',['filename'], ['dest'], ['dest_is_path'])
            % Creates file using <dest> as name. If <dest_is_path> is supplied and non-zero
            % uses source file name but adds <dest> as directory path.

            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            
            if 2==exist(edfFile, 'file')
                fprintf('Data file ''%s'' can be found in ''%s''\n', edfFile, pwd );
            end
            
        catch ME
            fprintf('Problem receiving data file ''%s''\n', edfFile );
            rethrow(ME);
        end

        % close the eye tracker and window
        Eyelink('ShutDown');
        
    end    
    
    Screen('CloseAll');
    
catch ME
    
    % This "catch" section executes in case of an error in the "try" section
    % above.  Importantly, it closes the onscreen window if its open.
    if ~dummy_mode
        Eyelink('ShutDown');
        Priority(oldPriority);
    end
    
    Screen('CloseAll');
    rethrow(ME);
    
end
