function drawTextures(parameters, screen, texture_name, color, dotCenter)
% created by Mrugank (06/15/2022):
% drawTexture can be called with texture_name to draw either a fixation
% cross or a stimulus at periphery. color argument is optional. Default
% color for either stimulus is white.

switch texture_name
    % Drawing Aperture
    case 'Aperture'
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_aperture = va2pixel(parameters, screen, parameters.apertureSize);
        
        % Coordinates for outer circle
        baseRect_aperture = [0 0 r_pix_aperture*2 r_pix_aperture*2];
        maxDiameter_aperture = ceil(max(baseRect_aperture) * 1.1);
        centeredRect_aperture = CenterRectOnPoint(baseRect_aperture, screen.xCenter, screen.yCenter);
  
        % Draw Aperture
        Screen('FillRect', screen.win, screen.black);
        Screen('FillOval', screen.win, screen.grey, centeredRect_aperture, maxDiameter_aperture)
    
    % Drawing Fixation Cross
    case 'FixationCross'
        if nargin < 4
            fixcolor = screen.white;
        else
            fixcolor = color;
        end
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_outer = va2pixel(parameters, screen, parameters.fixationSizeDeg);
        r_pix_inner = va2pixel(parameters, screen, parameters.fixationSizeDeg/3);
        
        % Coordinates for fixation cross
        xCoords = [-r_pix_outer r_pix_outer 0 0];
        yCoords = [0 0 -r_pix_outer r_pix_outer];
        allCoords = [xCoords; yCoords];
        
        % Coordinates for outer circle
        baseRect_outer = [0 0 r_pix_outer*2 r_pix_outer*2];
        maxDiameter_outer = ceil(max(baseRect_outer) * 1.1);
        centeredRect_outer = CenterRectOnPoint(baseRect_outer, screen.xCenter, screen.yCenter);
        
        % Coordinates for inner circle
        baseRect_inner = [0 0 r_pix_inner*2 r_pix_inner*2];
        maxDiameter_inner = ceil(max(baseRect_inner) * 1.1);
        centeredRect_inner = CenterRectOnPoint(baseRect_inner, screen.xCenter, screen.yCenter);
        
        % Draw Fixation cross
        Screen('FillOval', screen.win, screen.black, centeredRect_outer, maxDiameter_outer);
        if strcmp(computer, 'GLNXA64')
            Screen('DrawLines', screen.win, allCoords, round(r_pix_inner*1.5), ...
                fixcolor, [screen.xCenter screen.yCenter], 2); % 2 is for smoothing
        end
        Screen('FillOval', screen.win, screen.black, centeredRect_inner, maxDiameter_inner);
        Screen('Flip', screen.win);
    
    % Drawing Fixation Cross
    case 'FixationCrossITI'
        if nargin < 4
            fixcolor = screen.white;
        else
            fixcolor = color;
        end
        % Get pixel width and height for inner and outer circle based of VA
        r_pix_outer = va2pixel(parameters, screen, parameters.fixationSizeDeg);
        r_pix_inner = va2pixel(parameters, screen, parameters.fixationSizeDeg/3);
        
        % Coordinates for fixation cross
        xCoords = [-r_pix_outer r_pix_outer 0 0];
        yCoords = [0 0 -r_pix_outer r_pix_outer];
        allCoords = [xCoords; yCoords];
        
        % Coordinates for outer circle
        baseRect_outer = [0 0 r_pix_outer*2 r_pix_outer*2];
        maxDiameter_outer = ceil(max(baseRect_outer) * 1.1);
        centeredRect_outer = CenterRectOnPoint(baseRect_outer, screen.xCenter, screen.yCenter);
        
        % Coordinates for inner circle
        baseRect_inner = [0 0 r_pix_inner*2 r_pix_inner*2];
        maxDiameter_inner = ceil(max(baseRect_inner) * 1.1);
        centeredRect_inner = CenterRectOnPoint(baseRect_inner, screen.xCenter, screen.yCenter);
        
        % Draw Fixation cross
        Screen('FillOval', screen.win, (screen.black + screen.grey)/2, centeredRect_outer, maxDiameter_outer);
        if strcmp(computer, 'GLNXA64')
            Screen('DrawLines', screen.win, allCoords, round(r_pix_inner*1.5), ...
                fixcolor, [screen.xCenter screen.yCenter], 2); % 2 is for smoothing
        end
        Screen('FillOval', screen.win, (screen.black + screen.grey)/2, centeredRect_inner, maxDiameter_inner);
        Screen('Flip', screen.win);
        
    % Drawing Stimulus
    case 'Stimulus'
        baseRect = [0 0 parameters.dotSize*2 parameters.dotSize*2];
        maxDiameter = ceil(max(baseRect) * 1.1);
        centeredRect = CenterRectOnPointd(baseRect, dotCenter(1), dotCenter(2));
        Screen('FillOval', screen.win, color, centeredRect, maxDiameter);
end