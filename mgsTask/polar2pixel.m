function coords = polar2pixel(parameters, theta, screen)
% created by Mrugank (06/15/2022):
% rho is distance of screen from the subject, and angle is the visual angle
% of the stimulus

r_in_cm = parameters.viewingDistance * tand(parameters.stimEccentricity);
r_in_pix = r_in_cm/screen.pixSize;
x = r_in_pix.*cosd(theta) + screen.xCenter; % in pixel
y = (-r_in_pix.*sind(theta) + screen.yCenter); % in pixel
coords = [round(x), round(y)];

end
