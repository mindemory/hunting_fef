numBlocks = 20;
numTrialsperBlock = 40;
numTrials = numBlocks * numTrialsperBlock;

polangs = 0:30:360;
pol_res = 30;
eccentricity = 10;
stimLoc = NaN(numTrials, 2);

polangSampled = randsample(polangs, numTrials, true);
JitterHolder = round(-pol_res/2 + pol_res .* rand(1, numTrials));
polangJittered = polangSampled + JitterHolder;

taskMap = struct;

for bb = 1:numBlocks
    polang_selected = polangJittered((bb-1)*numTrialsperBlock+1:bb*numTrialsperBlock);
    %stimLocY_selected = stimLocY((bb-1)*numTrialsperBlock+1:bb*numTrialsperBlock);
    taskMap(bb).polang = polang_selected';
end
% stimLocX = eccentricity .* cosd(polangJittered);
% stimLocY = eccentricity .* sind(polangJittered);
% 
% taskMap = struct;
% 
% for bb = 1:numBlocks
%     stimLocX_selected = stimLocX((bb-1)*numTrialsperBlock+1:bb*numTrialsperBlock);
%     stimLocY_selected = stimLocY((bb-1)*numTrialsperBlock+1:bb*numTrialsperBlock);
%     taskMap(bb).stimLoc = [stimLocX_selected', stimLocY_selected'];
% end

save('/d/DATC/datc/TMS_fef/taskMap.mat','taskMap')
