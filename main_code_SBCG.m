clearvars
clc

hist.ID = input('ID? ');
player_role = input('Player? ');

global wPtr rect scr_x scr_y text_color bk_color dot_color rect_color white blue green p1_text_rect p1_tar_rect p2_text_rect p2_tar_rect baseLen baseSepX baseSepY

%% Selcet mode 
dummy_mode = 0; % 1 = no eye-tracking, 0 = eye-tracking
test_mode  = 0; % T = 5; short session, 1 = test

show_up_fee = 200;
ECU_exchange_rate = 20;
pen_width_emp = 8;

%% Get Data (loads CSV/Excel/Mat)

par_o = readtable('game_para.xlsx');

%% Shuffle Random Num Seed
rng('shuffle');

%% decide game length
TT = max(par_o.game_index);
AT = length(par_o.game_index);

num_practice_trial = AT - TT;

if test_mode
    Screen('Preference', 'SkipSyncTests', 1);
    T = num_practice_trial + 4;
else
    Screen('Preference', 'SkipSyncTests', 0)
    T = AT; % trial # for session I, decpends on data
end

%% randomly reorder all trials
hist.rand_order = randperm( TT );

hist.rand_order = [1:num_practice_trial hist.rand_order + num_practice_trial];

par = par_o(hist.rand_order , :);

if player_role == 2
    
    temp_par = par;
    
    par.p1_tar_x = temp_par.p2_tar_x;
    par.p1_tar_y = temp_par.p2_tar_y;
    par.p2_tar_x = temp_par.p1_tar_x;
    par.p2_tar_y = temp_par.p1_tar_y;
 
elseif player_role ~= 1
    
    error('Player should be 1 or 2.');
    
elseif isempty(player_role)
    
    error('Player should not be empty.');
    
end

%% Rest Screen is not placed yet
rest  = round( (T-num_practice_trial)/2 ) + num_practice_trial;
rest_t = rest;

%% Set parameter
dot_size   = 36;    % fixation dot size
fix_thresh = 100;   % fixation threshold width
fix_time   = 1.1;   % fixation time in second

FileName = ['SBCG_eye_' datestr(clock,'mmDDHHMM') '_subject_', num2str(hist.ID) ,'.mat']; % Matlab .mat file name
edfFile = [ datestr(clock,'mmDDHHMM'),'.edf']; % Name of remote data file to create

%%
createFile = 0; % if we screate .edf file
save_file  = 0; % if we save matlab .mat file

if ~dummy_mode
    createFile = 1;
    save_file  = 1;
end

% Get the screen numbers
screens = Screen('Screens'); % if we have 2 screens, we will get [0 1 2]

% Draw to the external screen if avaliable
if max(screens) > 1
    scr_num = 2;
else
    scr_num = 0;
end


%% preallocate matrix or struct. for saving data
hist.rt     = ones(1, AT)*NaN;
hist.dec    = cell(1,AT);
hist.dec_x  = ones(1, AT)*NaN;
hist.dec_y  = ones(1, AT)*NaN;

% hist.pi_trial = randi([1,T],1); % Randomly decide the payoff trial

%% set colors

% red   = [246   7  10];
% green = [ 11 102  35];
% blue  = [ 43 104 255];

red   = [100   0    0];
green = [  0 100    0];
blue  = [  0   0  100];

black = [0 0 0]; 
gray  = [255 255 255]/3;
white = [255, 255 , 255];

bk_color = gray; % gray; % background color
eye_link_bk_color = gray;
text_color = blue;
dot_color  = red;
rect_color = black;
% cursor_color = red;

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

% Open windows
[wPtr, rect] = Screen('OpenWindow', scr_num, bk_color);

HideCursor();

% Get the size of the screen 
scr_x = rect(3); % width of the screen
scr_y = rect(4); % length of the screen

xRange = [0 scr_x];
yRange = [0 scr_y];

%% Set font
%Screen('Preference','TextRenderer', 1);
%Screen('Preference', 'TextAntiAliasing', 1);
%Screen('Preference', 'TextAlphaBlending', 0);
%Screen('Preference', 'DefaultTextYPositionIsBaseline', 1);

main_font      = 'Arial';
main_font_size = 36;

Screen('TextFont' , wPtr , main_font);
% Screen('TextStyle', wPtr , 0);
Screen('TextFont', wPtr, '-:lang=zh-tw');

%% predertermine the ROI rect
baseLen   = scr_x*0.05;
baseSepX  = scr_x*0.015;
baseSepY  = scr_y*0.015;

margin = 0.45;
sensor_margin = [-baseSepX*margin -baseSepY*margin baseSepX*margin baseSepY*margin];

p1_text_rect = [0 0 3*baseLen 5*baseSepY];
p1_tar_rect  = [0 5*baseSepY 3*baseLen 10*baseSepY];

p2_text_rect = [scr_x - 3*baseLen 0 scr_x 5*baseSepY];
p2_tar_rect  = [scr_x - 3*baseLen 5*baseSepY scr_x 10*baseSepY];

confirm_rect = [0 scr_y - 5*baseSepY 3*baseLen scr_y];
cancel_rect  = [scr_x - 3*baseLen scr_y - 5*baseSepY scr_x scr_y];

%% Get image for host PC

% if test_mode == 1
%     
%     map_x = 11;
%     map_y = 9;
%     p1_tar_x = 1;
%     p1_tar_y = -1;
%     p2_tar_x = -2;
%     p2_tar_y = 2;
%     
%     [ allRects , pos_text , IA_label] = draw_game_rect(map_x, map_y, p1_tar_x ,p1_tar_y, p2_tar_x, p2_tar_y);
%     
%     Screen('Flip', wPtr);
%     
%     exp_img = Screen('GetImage',wPtr); 
%     % imwrite(minimizeimage(optionimg),['tS' num2str(01) '.png'],'png'); 
%     imwrite(exp_img,'example_image.bmp', 'bmp');
%     WaitSecs(2);
%     
% end

%%

% Query the frame duration and set waitframe
Priority(priority); 
ifi = Screen('GetFlipInterval', wPtr); 
waitframes = 1;

%% Instruction

    Screen('TextSize' , wPtr , main_font_size);
    
    welcome_text = double(['������@�� ' , num2str(T) , ' �^�X (�]�t�m��)']);
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.3*scr_y, text_color);

    welcome_text = double(['����̫�N�H����X�@�^�X�P�t�@����ժ̰t��ڥH�M�w���S�A�[�W�����O ', num2str(show_up_fee) , ' ��']);
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.4*scr_y, text_color);

    welcome_text = double(['���礤�Ҧ����S����쳣�O�k���A�k���P�s�x���I�����ײv���G 1 �k�� = �s�x�� ', num2str(ECU_exchange_rate), ' ��']);
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.5*scr_y, text_color);    

    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.8*scr_y, text_color);    

    % Flip to the screen
    Screen('Flip', wPtr);
    % vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
    KbStrokeWait;
        
    welcome_text = double('���礤�A�C�^�X���W�h�p�U�G');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.3*scr_y, text_color);

    welcome_text = double('�A�M�t�@����ժ̱N�P�ɿ�ܵe���W�a�Ϫ��@�Ӧ�m (X , Y)�A�A�����S�N�ѧA�̨�өҿ諸��m�@�P�M�w');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.4*scr_y, text_color);    

    welcome_text = double('����ӻ��A�A�̱N�U���@�� "�ؼ�"�A����ܬ۹�����ܦ�m�A�A�n��ܪ����');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.5*scr_y, text_color); 
    
    welcome_text = double('�U���ڭ̥H�@�� 5 X 7 ���a�ϧ@���Ҥl');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.6*scr_y, text_color); 
    
    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.9*scr_y, text_color);    
    
    % Flip to the screen
    Screen('Flip', wPtr);
    % vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
    KbStrokeWait;
    
    map_x = 5;
    map_y = 7;
    p1_tar_x = -2;
    p1_tar_y = 0;
    p2_tar_x = 0;
    p2_tar_y = -4;
    
    draw_game_rect(map_x, map_y, p1_tar_x ,p1_tar_y, p2_tar_x, p2_tar_y);

    welcome_text = double('�A���ؼ���ܩ󥪤W�� (�b�o�ӽd�Ҥ��� �� 2)');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.2*scr_y, text_color);

    welcome_text = double('��誺�ؼ���ܩ��k�W�� (�b�o�ӽd�Ҥ��� �U 4)');
    DrawFormattedText( wPtr, welcome_text , 'right' , 0.2*scr_y, text_color);    

    welcome_text = double('�ҥH�A�Ʊ�����諸��m��������');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.3*scr_y, text_color); 
    
    welcome_text = double('�ҥH���Ʊ���A�諸��m���U���|��');
    DrawFormattedText( wPtr, welcome_text , 'right' , 0.3*scr_y, text_color); 

    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.9*scr_y, text_color);    
    
    % Flip to the screen
    Screen('Flip', wPtr);
    % vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
    KbStrokeWait;

    exp_rect = draw_game_rect(map_x, map_y, p1_tar_x ,p1_tar_y, p2_tar_x, p2_tar_y);
    
    Screen('FrameRect', wPtr , red , exp_rect(:,25) , pen_width_emp );
    
    welcome_text = double('�A�n�۬ݪ����|�Q����خإ]��');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.2*scr_y, text_color);

    welcome_text = double('�n�M�w��ܳo�Ӧ�m�A�ݭn���U �ť��� �h��w�o�ӿ��');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.3*scr_y, text_color);    
    
    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.4*scr_y, text_color); 
    
    Screen('Flip', wPtr);
    
    KbStrokeWait;
    
    exp_rect = draw_game_rect(map_x, map_y, p1_tar_x ,p1_tar_y, p2_tar_x, p2_tar_y);
    
    Screen('FrameRect', wPtr , red , exp_rect(:,25) , pen_width_emp );
    
    Screen('FillRect', wPtr , red , confirm_rect);
    DrawFormattedText(wPtr , double('�T�{') , 'center','center',white,[],[],[],[],[], confirm_rect);

    Screen('FillRect', wPtr , red , cancel_rect);
    DrawFormattedText(wPtr , double('����') , 'center','center',white,[],[],[],[],[], cancel_rect);

    welcome_text = double('�A�n�۬ݪ����|�Q����خإ]��');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.2*scr_y, text_color);

    welcome_text = double('�n�M�w��ܳo�Ӧ�m�A�ݭn���U �ť��� �h��w�o�ӿ��');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.3*scr_y, text_color);    
    
    welcome_text = double('���U�ӽT�{�M�������ﶵ�|���O�q���U�Υk�U�X�{');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.7*scr_y, text_color); 
    
    welcome_text = double('�Ы�����T�{��ܡA�άO�k�������w');
    DrawFormattedText( wPtr, welcome_text , 'left' , 0.8*scr_y, text_color); 

    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.9*scr_y, text_color);    
    
    % Flip to the screen
    Screen('Flip', wPtr);
    % vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
    KbStrokeWait;
    
    Screen('TextSize' , wPtr , main_font_size);
    
    welcome_text = double('���祿���}�l�e�A�ڭ̱N�i��@�����ʻ����ե�');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.2*scr_y, text_color);

    welcome_text = double('�b�i��ե��ɡA�Ъ`���e������������I�A�ë��U �ť��� �@��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.3*scr_y, text_color);

    welcome_text = double('�o�Ӷ��I�|�����A�ò��ʨ�t�@���H�����s��m');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.4*scr_y, text_color);    

    welcome_text = double('�Ъ`���o�ӷs���I���쥦�A�@�������A�ò��ʨ�t�@���H�����s��m');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.5*scr_y, text_color); 

    welcome_text = double('�Ъ`���o�ӷs���I���쥦�A�@�������A�ò��ʨ�t�@���H�����s��m�A�í��Ƴo�Ӭy�{����S���s�I');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.6*scr_y, text_color); 
    
    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.8*scr_y, text_color);    

    % Flip to the screen
    Screen('Flip', wPtr);
    % vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
    KbStrokeWait;

    welcome_text = double('���祿���}�l��A�b�C�@�Ӧ^�X���@�}�l�ڭ̷|�A�i��@���ե�');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.4*scr_y, text_color);

    welcome_text = double('�e�����߷|�X�{�@�Ӷ��I�A�Ъ`�����ë��U �ť��� �@��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.5*scr_y, text_color);    
    
    welcome_text = double('�Ы��U �ť��� �~��');
    DrawFormattedText( wPtr, welcome_text , 'center' , 0.8*scr_y, text_color);    

    % Flip to the screen
    Screen('Flip', wPtr);
    % vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);
    KbStrokeWait;
    
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
        % set link data thtough link_sample_data and link_event_filter
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
        el.cal_target_beep=[600 0.5 0.05];
        el.drift_correction_target_beep=[600 0.5 0.05];
        el.calibration_failed_beep=[400 0.5 0.25];
        el.calibration_success_beep=[800 0.5 0.25];
        el.drift_correction_failed_beep=[400 0.5 0.25];
        el.drift_correction_success_beep=[800 0.5 0.25];
        % you must call this function to apply the changes from above
        EyelinkUpdateDefaults(el);
        
        % Hide the mouse cursor
        Screen('HideCursorHelper', wPtr);
        % Calibration
        EyelinkDoTrackerSetup(el); 
 
    end % of not dummy mode    
    
    % Hide mouse cursor
    HideCursor();
    
    %% for each trials

    for t = 1: T
        
        %% Confirmation Screen for Practice and Real Exp
        vbl = Screen('Flip', wPtr);
        if t == 1
            
            while 1

            [~,~,keyCode] = KbCheck;

            if keyCode(space_key)
                break
            end
            
            Screen('TextSize' , wPtr , main_font_size);
            
            % Draw ending screen

            practice_text = double(['�{�b�ڭ̱N�m�� ', num2str(num_practice_trial) ,' �Ӧ^�X']);
            DrawFormattedText( wPtr, practice_text , 'center' , 0.4*scr_y, text_color);

            practice_text = double('�ت��O���A���x���窺�ާ@�L�{');
            DrawFormattedText( wPtr, practice_text , 'center' , 0.5*scr_y, text_color);

            practice_text = double('�Ы��U �ť��� �}�l�m��');
            DrawFormattedText( wPtr, practice_text , 'center' , 0.8*scr_y, text_color);

            % Flip to the screen
            vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);

            end % of while
            
            WaitSecs(0.5);
            
        elseif t == 1 + num_practice_trial
            
            WaitSecs(0.5);
            
            if ~dummy_mode
                EyelinkDoTrackerSetup(el);
            end
            
            while 1

            [~,~,keyCode] = KbCheck;

            if keyCode(space_key)
                break
            end

            % Draw ending screen
            
            Screen('TextSize' , wPtr , main_font_size);

            start_text = double(['�{�b�ڭ̱N�}�l ', num2str(T - num_practice_trial) ,' �^�X����������']);
            DrawFormattedText( wPtr, start_text , 'center' , 0.4*scr_y, text_color);

            start_text = double('����L�{�кɥi�ण�n���ʧA���Y���A�u���ʵ��u');
            DrawFormattedText( wPtr, start_text , 'center' , 0.5*scr_y, text_color);

            start_text = double('�Ы��U �ť��� �}�l����');
            DrawFormattedText( wPtr, start_text , 'center' , 0.8*scr_y, text_color);

            % Flip to the screen
            vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);

            end % of while
            
            WaitSecs(0.5);
            
        end
        
        %% do tracker setup for each trial

        if ~dummy_mode
            
            imgfile = ['example_image' , '_' , num2str( par.map_x(t) ) , '_' num2str( par.map_y(t) ) , '.bmp']; % load a image to use on the host pc 
            transferimginfo=imfinfo(imgfile);

            % This message provide data viewer the trial ID
            Eyelink('Message', 'TRIALID %d', t); 
            % This supplies the title at the bottom of the eyetracker display
            Eyelink('command', 'record_status_message "TRIAL %d / %d %s"', t , T, imgfile);
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
            

            % Draw ROIs
            
            [ allRects_t , ~ , IA_label_t] = draw_game_rect(par.map_x(t), par.map_y(t), par.p1_tar_x(t), par.p1_tar_y(t), par.p2_tar_x(t), par.p2_tar_y(t) );
            
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 201, floor(p1_text_rect(1)), floor(p1_text_rect(2)), floor(p1_text_rect(3)), floor(p1_text_rect(4)), 'p1_text');
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 202, floor(p1_tar_rect(1)), floor(p1_tar_rect(2)), floor(p1_tar_rect(3)), floor(p1_tar_rect(4)), 'p1_tar');
            
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 203, floor(p2_text_rect(1)), floor(p2_text_rect(2)), floor(p2_text_rect(3)), floor(p2_text_rect(4)), 'p2_text');
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 204, floor(p2_tar_rect(1)), floor(p2_tar_rect(2)), floor(p2_tar_rect(3)), floor(p2_tar_rect(4)), 'p2_tar');
            
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 205, floor(confirm_rect(1)), floor(confirm_rect(2)), floor(confirm_rect(3)), floor(confirm_rect(4)), 'confirm');
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', 206, floor(cancel_rect(1)), floor(cancel_rect(2)), floor(cancel_rect(3)), floor(cancel_rect(4)), 'cancel');
            
            for i = 1:par.map_x(t)*par.map_y(t)
 
                Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s', i, floor(allRects_t(1,i) + sensor_margin(1)), floor(allRects_t(2,i) + sensor_margin(2)),... 
                    floor(allRects_t(3,i) +sensor_margin(3)), floor(allRects_t(4,i) + sensor_margin(4)), IA_label_t{i} );
                
            end
            
        end

%% Trial Screen
        
        vbl = Screen('Flip', wPtr);
        
        s_choice = GetSecs;
        inside = zeros(par.map_x(t)*par.map_y(t),1);

        temp_dec_made = 0;
        dec_made = 0;
        
        if dummy_mode
            SetMouse(scr_x/2, scr_y/2 , wPtr);
            ShowCursor('Arrow');
        end
        
        [ allRects_t , pos_text_t , IA_label_t ] = draw_game_rect( par.map_x(t), par.map_y(t), par.p1_tar_x(t), par.p1_tar_y(t), par.p2_tar_x(t), par.p2_tar_y(t) );
        
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

            end  % of dummy mode
            
            draw_game_rect(par.map_x(t), par.map_y(t), par.p1_tar_x(t), par.p1_tar_y(t), par.p2_tar_x(t), par.p2_tar_y(t) );
            
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
            
            for i = 1:par.map_x(t)*par.map_y(t)

                inside(i) = IsInRect( mx, my, allRects_t(:,i) + sensor_margin' );

                if inside(i) && ~temp_dec_made
                    
                    temp_rect_t = allRects_t(:,i);
                                       
                    Screen('FrameRect', wPtr , red , temp_rect_t , pen_width_emp );
 
                    [~,~, keyCode] = KbCheck;

                    if keyCode(space_key)
                        
                        if ~dummy_mode
                            Eyelink('Message', 'Temp Choice Made'); % temp choice made
                        end
                        
                        dec_t = strsplit(IA_label_t{i},',');
                        
                        hist.dec{t}   = IA_label_t{i};
                        hist.dec_x(t) = str2double( dec_t(1) );
                        hist.dec_y(t) = str2double( dec_t(2) ); 
                        
                        temp_dec_made = 1;
                        
                        WaitSecs(0.05);
                        
                        break % the for loop

                    end % end of if space
                    
                end % if inside

            end % of i loop
            
            
            if temp_dec_made
                
                Screen('FrameRect', wPtr , red , temp_rect_t , pen_width_emp );
                
                Screen('FillRect', wPtr , red , confirm_rect);
                DrawFormattedText(wPtr , double('�T�{') , 'center','center', white ,[],[],[],[],[], confirm_rect);
                
                Screen('FillRect', wPtr , red , cancel_rect);
                DrawFormattedText(wPtr , double('����') , 'center','center', white ,[],[],[],[],[], cancel_rect);
                
                [~,~, keyCode] = KbCheck;

                if keyCode(left_arrow)
                    
                    s_choice_made = GetSecs;
                    
                    if ~dummy_mode
                        Eyelink('Message', 'Choice Made'); % choice made and confirm
                    end
                    
                    dec_made = 1;
                    
                elseif keyCode(right_arrow)
                    
                    if ~dummy_mode
                        Eyelink('Message', 'Temp Choice Canceled'); % choice canceled
                    end
                    
                    temp_dec_made = 0;

                end 
                
            end
            
            if dec_made 
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
        
        hist.rt(t) = s_choice_made - s_choice;           
    
        if ~dummy_mode
            Eyelink('Message', 'Stop Recording'); % end of trial
            Eyelink('StopRecording');
        end
        
             %% REST, press 'q' to quit REST screen

        if all(ismember(t,rest_t)) && t ~= T
            
            while 1

            [~,~,keyCode] = KbCheck;

            if keyCode(escape_key)
                break
            end

            % Draw ending screen
            
            Screen('TextSize' , wPtr , main_font_size);

            rest_text = double('�{�b�O���~�𮧮ɶ�');
            DrawFormattedText( wPtr, rest_text , 'center' , 0.4*scr_y, text_color);

            rest_text = double('�Y�i�H���}�U�ڬ[���ʤ@�U');
            DrawFormattedText( wPtr, rest_text , 'center' , 0.5*scr_y, text_color);

            rest_text = double('�p�G�n�~��A�Ы��U ESC ��');
            DrawFormattedText( wPtr, rest_text , 'center' , 0.8*scr_y, text_color);

            % Flip to the screen
            vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);

            end % of while
            
            if ~dummy_mode  
                EyelinkDoTrackerSetup(el);
            end
            
        end % end of rest
        
        HideCursor();
        
    end % end of for t = 1:T 
    
    %% Calculate payoff
    
    % hist.pi_trial_dec = [hist.dec_x( hist.pi_trial ) , hist.dec_y( hist.pi_trial )];
    
    % hist.pi = 100;
    
    %% End Screen
    
    Screen('TextSize' , wPtr , main_font_size);
    
    [g_num, order_index] = sort(hist.rand_order);
    
    dec_x = hist.dec_x(order_index);
    dec_y = hist.dec_y(order_index);
    
    g_num = [-3:-1 g_num(4:end)-3];
    
    g_num = g_num';
    dec_x = dec_x'; 
    dec_y = dec_y';
    
    chioce_table = table(g_num , dec_x, dec_y);
    
    while 1
        
        [~,~,keyCode] = KbCheck;

        if keyCode(escape_key)
            break
        end
        
        % Draw ending screen
        
        Screen('TextSize' , wPtr , main_font_size);
        
        end_text = double('�z�w�g�����F�Ҧ����');
        DrawFormattedText( wPtr, end_text , 'center' , 0.4*scr_y, text_color);
        
        % pi_text = [double('�z�@��o�F '), num2str(hist.pi * ECU_exchange_rate + show_up_fee) , double(' ��!')];
        % DrawFormattedText( wPtr, double(pi_text) , 'center' , 0.5*scr_y, text_color);
        
        end_text = double('���U�ӡA��ť�q����̪����ܲ��ʨ�t�@�x�q���e���A�i��U�@�B�J');
        DrawFormattedText( wPtr, end_text , 'center' , 0.5*scr_y, text_color);
        
        % Flip to the screen
        vbl  = Screen('Flip', wPtr, vbl + (waitframes - 0.5) * ifi);

    end % of while
    
%% Save Data
    
    if save_file
        %filename = [id,name];
        %save(FileName,'data');
        save(FileName);
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
    
disp(chioce_table)    
    
game_chosen = input('Game? ');

disp(chioce_table(game_chosen + num_practice_trial,:))
