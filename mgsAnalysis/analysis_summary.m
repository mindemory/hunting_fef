sess_fpath = '/d/DATC/datc/TMS_fef/analysis/sub01/day01/ii_sess_sub01_day01.mat';
load(sess_fpath)

trl_types = [0, 1, 2];
for t_type = trl_types
    trl_idx = find(ii_sess.TMScond == t_type);
    figure();
    sgtitle(['trl type: ' num2str(t_type, '%02d')])
    for ii = 1:length(trl_idx)
        this_trl_idx = trl_idx(ii);
        subplot(5, 5, ii)
        hold on;
        this_samps = find(ii_sess.XDAT{this_trl_idx}<4);
        len_this = length(this_samps)+200;
        this_X = ii_sess.X{this_trl_idx}(1:len_this);
        this_Y = ii_sess.Y{this_trl_idx}(1:len_this);
        this_XDAT = ii_sess.XDAT{this_trl_idx}(1:len_this);
        plot(1:len_this, this_X, 'r-')
        plot(1:len_this, this_Y, 'b-')
        plot(1:len_this, this_XDAT==2, 'm-')
        plot(1:len_this, this_XDAT==3, 'k-')
    end
end