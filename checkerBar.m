function TwoDirsSerialCheckerBar(varargin)
oldLevel = Screen('Preference', 'Verbosity', 2);
portaddress = 49232;
config_io;
outp(portaddress,0);%initiate port value to 0
% seed 0, 1, 2, 3 is used respectively 
try
    %assign default values
    speed=400;   % pixels/s, roughly 440 um/s, rig dependent
    checker.freq=15;
    checker.size=40;
    prefD=315;
    numReps=3;
    numDirs=2;
    barWidth=100;
    barLength=400;
    movingRadius=300;
    barColor=50;  % new rig
    preStimWait=3;
    baseWait=1;
    switch speed
        case 1200
            interTrialWait=2;
        case 400
            interTrialWait=1;
        case 100
            interTrialWait=2.5;
            numReps=2;
            baseWait=0;
    end
    
    saveStimulus=1;
    screenColor = 0.01;
    dendrites=[0 0];  % dendrites=[ distnance_from_soma angle from_soma], use this to apply stimulus in remote dendritic branches
    checker.colors=[ 0 0.1 ];  % pixel intensity, see gamma chart for intensity 
    checker.colors=checker.colors(randperm(length(checker.colors)));
    
    interSerialWait=2;
    pvpmod(varargin) %assign valueTa
    maskRadius=movingRadius;
    Screen('Preference','VisualDebugLevel',2);
    Beep = MakeBeep(1000,0.1);
    lptwrite(portaddress, 0); %initialize parallel port to 0's, portaddress is the "base address" of our parallel port
    %generate direction list
    dirs =0:(360/numDirs):(360-(360/numDirs));
    directions = [];
    for r=1:numReps*length(checker.colors)
        dirs_shuffled = Shuffle(dirs);
        directions=cat(2,directions,dirs_shuffled);
    end
    directions=mod(directions+prefD,360)
    %generate matrix for stimulus file
    StimulusInfo=ones(length(directions),10+length(checker.colors));
    StimulusInfo(:,1)=directions;
    StimulusInfo(:,2)=StimulusInfo(:,2)*speed;
    StimulusInfo(:,3)=StimulusInfo(:,3)*barLength;
    StimulusInfo(:,4)=StimulusInfo(:,4)*barWidth;
    StimulusInfo(:,5)=StimulusInfo(:,5)*movingRadius;
    StimulusInfo(:,6)=StimulusInfo(:,6)*barColor;
    StimulusInfo(:,7)=StimulusInfo(:,7)*checker.size;
    StimulusInfo(:,8)=StimulusInfo(:,8)*checker.freq;
    StimulusInfo(:,9)=StimulusInfo(:,9)*dendrites(1);
    StimulusInfo(:,10)=StimulusInfo(:,10)*dendrites(2);
    for i=1:length(checker.colors)
        StimulusInfo(:,10+i)=StimulusInfo(:,10+i)*checker.colors(i);
    end
    if saveStimulus
        [dirFile,dirPath] = uiputfile('*.txt','Save directions as');
        fn=[dirPath dirFile];
        if isstr(fn)
            fid = fopen(fn, 'wt');
            fprintf(fid, '%6.2f %6.2f %6.2f %6.2f %6.2f    %6.2f %6.2f %6.2f %6.2f %6.2f   %6.2f %6.2f %6.2f  \n', StimulusInfo');
            fclose(fid);
        end
    end
    
    fprintf('%s %f seconds\n', 'set normal recording length to',...
        (2*movingRadius+barLength)/speed+1+interTrialWait);
    disp('press any key to continue...')
    pause;
    
    HideCursor
    %initialize screen
    AssertOpenGL;
    table=getGammaTable(0); %  %load most recent gamma table
    Screen('Preference', 'SkipSyncTests',0);
    screens=Screen('Screens');
    screenNumber=max(screens);
    %Open a fullscreen window
    [window,~]=Screen('OpenWindow',screenNumber, 0 , [], 32, 2);
    Screen('LoadNormalizedGammaTable', window, table); %use gamma corrected table
    %Enable Alpha blending % THis is a linear super-position
    Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    %Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE);
    frameRate=1/Screen('GetFlipInterval',window);
    checker.nframe=ceil(frameRate/checker.freq); 
    priorityLevel=MaxPriority(window);
    Priority(priorityLevel);
    
    
    preStimFrame=floor(preStimWait*frameRate/checker.nframe)*checker.nframe;
    [x,y] = RectCenter(screenRect);
    cdstRect = [0 0 2*movingRadius 2*movingRadius];
    cdstRect=CenterRect(cdstRect, screenRect);
    cdstRect=CenterRectOnPoint(cdstRect,x+dendrites(1)*cosd(dendrites(2)),y+dendrites(1)*sind(dendrites(2)));
    
    ncheckers=floor(2*movingRadius/checker.size);  % spatial component
    padding = 1; % Region around bar drawn in texture matrix to be set to zero alpha
    %make texture with transparent border for smoother motion
    barTex = ones(barWidth, barLength+(2*padding), 2)*barColor;
    barTex(:,:,2) = 0;
    barTex(1:barWidth, 1+padding:barLength+padding, 2) = 255;
    tex = Screen('MakeTexture', window, barTex);
    for c=1:length(checker.colors)
        if KbCheck
            break; % Exit loop
        end
        dlist=directions( (c-1)*numReps*num_dirs+1:c*num_dirs*numReps);
        checker.color=checker.colors(c);
        [checkerboard] = makeRandchecker( checker.color,checker.size,ncheckers,maskRadius,0, ...,
            ceil((preStimFrame+60)/checker.nframe));
        checkerTexture = Screen('MakeTexture', window, squeeze(checkerboard(:,:,1)));
        % checkerboard is 3D, create additonal 60 frames just in case
        for i=1:preStimFrame
            Screen('DrawTextures', window, checkerTexture,  [],cdstRect, 0, 0);
            Screen('Flip', window);
            cpat=squeeze(checkerboard(:,:,ceil(i/checker.nframe)));
            checkerTexture = Screen('MakeTexture', window, cpat);
        end
        
        Snd('Play',Beep);
        
        
        for trial=1:length(dlist)
            direction=dlist(trial);
            showMovingBar(window,screenRect,tex,frameRate,checker,cdstRect,'interTrialWait',interTrialWait,...
                'frameRate',frameRate, 'direction',direction,'barWidth',barWidth,'baseWait',baseWait,...
                'barLength',barLength,'barColor',barColor,...
                'speed',speed,'movingRadius',movingRadius,'screenColor',screenColor,'maskRadius',maskRadius,'dendrites',dendrites);
        end
        Screen('FillOval',window,0,screenRect);
        Screen('Flip',window);
        WaitSecs(interSerialWait);
    end
    Snd('Play',Beep);
    sca;
    Screen('Preference','Verbosity', oldLevel);
    Priority(0);
    KbWait;
catch
    Snd('Play',Beep);
    KbWait;
    ShowCursor
    sca;
    Screen('Preference','Verbosity', oldLevel);
    Priority(0);
    rethrow(lasterror);
end
return


function []=showMovingBar(window,screenRect,tex,frame_rate,checker,cdstRect,varargin)
pvpmod(varargin) %assign values
[x,y] = RectCenter(screenRect);
endRadius = -movingRadius-barLength;
ncheckers=floor(2*movingRadius/checker.size);


[mask,sz]=makeCircularMask(maskRadius,'bg',0);
masktex=Screen('MakeTexture', window, mask);
maskRect=[0 0 sz sz];
maskRect=CenterRect(maskRect, screenRect);
maskRect=CenterRectOnPoint(maskRect,x+dendrites(1)*cosd(dendrites(2)),y+dendrites(1)*sind(dendrites(2)));

%output trigger pulse
portaddress = 49232;
config_io;
outp(portaddress,0);%initiate port value to 0

%output trigger pulse
outp(portaddress, 255);%3020 is the "base address" of our parallel port
WaitSecs(.0005);
outp(portaddress, 0);
WaitSecs(.1);

baseFrame=ceil(baseWait*frameRate/checker.nframe)*checker.nframe+checker.nframe;
[checkerboard] = makeRandchecker( checker.color,checker.size,ncheckers,maskRadius,1, ...,
    ceil((baseFrame+60)/checker.nframe));
checkerTexture = Screen('MakeTexture', window, squeeze(checkerboard(:,:,1)));
% checkerboard is 3D, create additonal 60 frames just in case
for i=1:base_frame
    Screen('DrawTextures', window, checkerTexture,  [],cdstRect, 0, 0);
    Screen('Flip', window);
    cpat=squeeze(checkerboard(:,:,ceil(i/checker.nframe)));
    checkerTexture = Screen('MakeTexture', window, cpat);
end

barTime= (2*movingRadius+barLength)/speed;
barFrame=ceil(barTime*frame_rate/checker.nframe)*checker.nframe;
count=0;
[checkerboard] = makeRandchecker( checker.color,checker.size,ncheckers,maskRadius,2, ...,
    ceil((barFrame+60)/checker.nframe));
while movingRadius >= endRadius
    % Make the checkerboard into a texure (4 x 4 pixels)
    %         Screen('FillRect', window,screen_color, []);
    startPos = [x+((movingRadius+barLength/2)*cosd(direction))+dendrites(1)*cosd(dendrites(2))...
        y+((movingRadius+barLength/2)*sind(direction))+dendrites(1)*sind(dendrites(2))];% startPosition [x y]
    dstRect = [0 0 barLength+2 barWidth];
    dstRect = CenterRectOnPoint(dstRect, startPos(1), startPos(2));
    
    %         Screen('DrawTexture', window, masktex, [],maskRect,0);
    Screen('DrawTexture',window,tex,[],dstRect,direction,0);
    Screen('DrawTexture', window, masktex, [],maskRect,0);
    Screen('Flip', window);

    movingRadius = movingRadius-(speed/frameRate);
    
    count=count+1;
    if KbCheck
        return; % Exit loop
    end
    Screen('DrawTextures', window, checkerTexture,  [],cdstRect, 0, 0);
    Screen('Flip', window);
    cpat=squeeze(checkerboard(:,:,ceil(count/checker.nframe)));
    checkerTexture = Screen('MakeTexture', window, cpat);
end

waitFrame=ceil(interTrialWait*frameFate/checker.nframe)*checker.nframe;
[checkerboard] = makeRandchecker( checker.color,checker.size,ncheckers,maskRadius,3, ...,
    ceil((waitFrame+60)/checker.nframe));
for i=1:waitFrame
    Screen('DrawTextures', window, checkerTexture,  [],cdstRect, 0, 0);
    Screen('Flip', window);
    cpat=squeeze(checkerboard(:,:,ceil(i/checker.nframe)));
    checkerTexture = Screen('MakeTexture', window, cpat);
end
function [mask,sz]=makeCircularMask(maskRadius,varargin)

interior_val=0;
exterior_val=255;
bg=0.5;
diat=2;
sz=1000;
pvpmod(varargin)
mask=ones(sz/diat, sz/diat, 2) * bg;
center = [floor(sz/(diat*2)) floor(sz/(diat*2))];
for r=1:sz/diat
    for c=1:sz/diat
        if sqrt((r-center(1))^2+(c-center(2))^2)<=maskRadius/diat
            mask(r,c,2)=interior_val;
        else
            mask(r,c,2)=exterior_val;
        end
        
    end
end

return





