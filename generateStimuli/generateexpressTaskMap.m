numBlocks = 20;
numTrialsperBlock = 30;
numTrials = numBlocks * numTrialsperBlock;

polangs = [0 180];
pol_res = 15;
TMSconds = [0, 1, 2];


polangSampled = randsample(polangs, numTrials, true);
JitterHolder = round(-pol_res/2 + pol_res .* rand(1, numTrials));
polangJittered = polangSampled + JitterHolder;

taskMap = struct;

for bb = 1:numBlocks
    polang_selected = polangJittered((bb-1)*numTrialsperBlock+1:bb*numTrialsperBlock);
    taskMap(bb).polang = polang_selected';
    taskMap(bb).TMScond = randsample(TMSconds, numTrialsperBlock, true);
end

save('/d/DATC/datc/TMS_fef/express_taskMap.mat','taskMap')
