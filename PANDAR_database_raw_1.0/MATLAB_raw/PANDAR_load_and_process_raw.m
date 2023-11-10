disp('###########################################################')
disp('### Welcome to the iks|PANDAR database (v1.0)')
disp('### Paths for Active Noise Cancellation Development And Research')
disp('### Published by Institut of Communication Systems (IKS) ')
disp('### RWTH Aachen University')
disp('### - Raw measurement loading and processing -')
disp('###########################################################')


%% path to database
database_folder         = 'C:\Users\Gonzalo\Downloads\PANDAR_database_raw_1.1\PANDAR_database_raw_1.0'; 


%% load acoustic booth dataset
dataset_folder          = fullfile(database_folder,'\BoseQC20_raw\acoustic_booth\');
[ itaPersons ]          = ita_read_ita_folder( fullfile(dataset_folder,'persons') );
[ itaHandling ]         = ita_read_ita_folder( fullfile(dataset_folder,'handling') );
itaBooth                = [itaPersons,itaHandling];

% separate in primary/secondary/feedback path left and right
[ itaBoothPaths, ~ ]    = ita_separateByChannelNames( ita_merge(itaBooth), 3 );

%% load anechoic chamber dataset

dataset_folder          = fullfile(database_folder,'\BoseQC20_raw\anechoic_chamber\');
[ itaChamberPrimary ]   = ita_read_ita_folder( fullfile(dataset_folder,'primary') );
[ itaChamberSecAFB, ~ ] = ita_separateByChannelNames( ita_merge(itaChamberPrimary), 3 );

% separate in primary path left and right
[ itaChamberPaths ]     = ita_read_ita_folder( fullfile(dataset_folder,'secondary+afb') );


%% load electronic back-end
dataset_folder          = fullfile(database_folder,'\BoseQC20_raw\electronic_backend\');
[ itaBackend ]          = ita_read_ita_folder( dataset_folder );


%% calculate primary path and do preprocessing for booth
% define parameters
boundsRegularisation    = [20,20000];
divide_pair             = [3,5; 4,6];
divide_names            = {'PrimaryL','PrimaryR'};
flen                    = 2^13;
range                   = [round(flen*0.99),flen];

ppMethodPrimPath        = {@ita_time_window,@ita_time_window,@ita_smooth};
ppOptionsPrimPath       = { {[0.15,0.16]}, ...
                            {range,'crop'},...
                            {'LogFreqOctave1',1/24,'Abs+Phase'}};

ppMethodSecPath         = {@ita_time_window,@ita_time_window,@ita_smooth};
ppOptionsSecPath        = { {[0.15,0.16]}, ...
                            {range,'crop'},...
                            {'LogFreqOctave1',1/24,'Abs+Phase'}};

ppMethodAFBPath         = {@ita_time_window,@ita_time_window,@ita_smooth};
ppOptionsAFBPath        = { {[0.0045,0.005]}, ...
                            {range,'crop'},...
                            {'LogFreqOctave1',1/24,'Abs+Phase'}};

% apply batch processing
[ itaPrimPath_processed ]   = ita_divide_spk_batch( itaBoothPaths, divide_pair, divide_names, boundsRegularisation, ppMethodPrimPath, ppOptionsPrimPath );
[ itaSecPath_processed ]    = ita_batch_process( itaBoothPaths(7:8), ppMethodSecPath, ppOptionsSecPath );
itaSecPath_processed        = ita_extractChannelNameFromChannelUserData(itaSecPath_processed,2);
[ itaAFBPath_processed ]    = ita_batch_process( itaBoothPaths(1:2), ppMethodAFBPath, ppOptionsAFBPath );
itaAFBPath_processed        = ita_extractChannelNameFromChannelUserData(itaAFBPath_processed,2);
itaPaths                    = [itaSecPath_processed, itaAFBPath_processed, itaPrimPath_processed];

% extract certain paths
itaSecPaths                 = ita_merge(itaPaths(1:2));
[ itaSecPathsFit, ~ ]       = ita_separateByChannelUserData( itaSecPaths, 4 );
itaAFBPaths                 = ita_merge(itaPaths(3:4));
[ itaAFBPathsFit, ~ ]       = ita_separateByChannelUserData( itaAFBPaths, 4 );
itaPrimPaths                = ita_merge(itaPaths(5:6));
[ itaPrimPathsFit, ~ ]      = ita_separateByChannelUserData( itaPrimPaths, 4 );
itaPrimPathLateral          = itaPaths(5);
itaPrimPathOpposite         = itaPaths(6);

%% calculate primary path and do preprocessing for anechoic chamber
% define parameters
boundsRegularisation        = [20,20000];
divide_pair                 = [2,1; 4,3];
divide_names                = {'PrimaryL','PrimaryR'};
flen                        = 2^13;
range                       = [round(flen*0.99),flen];

ppMethodPrimPath            = {@ita_time_window,@ita_time_window,@ita_smooth};
ppOptionsPrimPath           = { {[0.15,0.16]}, ...
                                {range,'crop'},...
                                {'LogFreqOctave1',1/24,'Abs+Phase'}};

ppMethodSecPath             = {@ita_time_window,@ita_time_window,@ita_smooth};
ppOptionsSecPath            = { {[0.15,0.16]}, ...
                                {range,'crop'},...
                                {'LogFreqOctave1',1/24,'Abs+Phase'}};

ppMethodAFBPath             = {@ita_time_window,@ita_time_window,@ita_smooth};
ppOptionsAFBPath            = { {[0.0045,0.005]}, ...
                                {range,'crop'},...
                                {'LogFreqOctave1',1/24,'Abs+Phase'}};


% apply batch processing
[ itaPrimChamber_processed ]    = ita_divide_spk_batch( itaChamberSecAFB, divide_pair, divide_names, boundsRegularisation, ppMethodPrimPath, ppOptionsPrimPath );
[ itaSecPath_directions ]       = ita_batch_process( [itaChamberPaths.ch(1),itaChamberPaths.ch(2)], ppMethodSecPath, ppOptionsSecPath );
[ itaAFBPath_directions ]       = ita_batch_process( [itaChamberPaths.ch(3),itaChamberPaths.ch(4)], ppMethodAFBPath, ppOptionsAFBPath );
itaChamberPaths                 = [itaSecPath_directions, itaAFBPath_directions, itaPrimChamber_processed];

% extract certain paths
itaPrimPath_directions          = ita_merge(itaPrimChamber_processed);
itaSecPath_directions           = ita_merge(itaSecPath_directions);
itaAFBPath_directions           = ita_merge(itaAFBPath_directions);


%% process the backend
flen                = 2^13;
range               = [round(flen*0.99),flen];
ppMethodBackend     = {@ita_time_window};
ppOptionsBackend    = { {range,'crop'}};

% apply batch processing
[ itaBackend_processed ] = ita_batch_process( itaBackend, ppMethodBackend, ppOptionsBackend );


%% ************************************************
% *************** Extended Plotting ***************
% *************************************************

%% Electronic backend
co = winter(6);
[~, axh] = ita_plot_freq_phase(itaBackend_processed);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);


%% SecPath - calculate means and plot
itaSecPaths_mean = mean(itaSecPaths);
itaSecPath_closed = itaSecPathsFit(1);
itaSecPath_open = itaSecPathsFit(4);
itaSecPath_persons = ita_merge(itaSecPathsFit([2,3,5]));


co = winter(6);
hFig = figure('Name','Secondary Path');
% ita_preferences('colortablename','winter');
[~, axh] = ita_plot_freq_phase(itaSecPath_persons,'figure_handle',hFig,'hold','on','colormap',co(6,:));
ita_plot_freq_phase(itaSecPath_open,'figure_handle',hFig,'hold','on','colormap',co(5,:));
ita_plot_freq_phase(itaSecPath_closed,'figure_handle',hFig,'hold','on','colormap',co(4,:));
ita_plot_freq_phase(itaSecPath_directions,'figure_handle',hFig,'hold','on','colormap',co(3,:));
ita_plot_freq_phase(itaSecPaths_mean,'figure_handle',hFig,'hold','on','colormap',co(1,:));
nChannelsFit = [itaSecPath_persons.nChannels, itaSecPath_open.nChannels, itaSecPath_closed.nChannels, itaSecPath_directions.nChannels, itaSecPaths_mean.nChannels];
legendText = {'persons','open','closed','dummy','mean'};
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);



%% SecPath - calculate means and plot

% calculate individual mean
for idx = 1:length(itaSecPathsFit)
    itaSecPathsFit_mean(idx) = mean(itaSecPathsFit(idx));
end

co = winter(length(itaSecPathsFit_mean)+2);
hFig = figure('Name','Secondary Path');
for idx = 1:length(itaSecPathsFit_mean)
    [~, axh] = ita_plot_freq_phase(itaSecPathsFit_mean(idx),'figure_handle',hFig,'hold','on','colormap',co(idx,:));
    nChannelsFit(idx) = itaSecPathsFit_mean(idx).nChannels;
    legendText{idx} = itaSecPathsFit_mean(idx).comment;
end
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);



%% AFBPath - calculate means and plot
itaAFBPaths_mean = mean(itaAFBPaths);
itaAFBPaths_closed = itaAFBPathsFit(1);
itaAFBPaths_open = itaAFBPathsFit(4);
itaAFBPaths_persons = ita_merge(itaAFBPathsFit([2,3,5]));

co = winter(6);
hFig = figure('Name','Acoustic Feedback Path');
[~, axh] = ita_plot_freq_phase(itaAFBPaths_persons,'figure_handle',hFig,'hold','on','colormap',co(6,:));
ita_plot_freq_phase(itaAFBPaths_open,'figure_handle',hFig,'hold','on','colormap',co(5,:));
ita_plot_freq_phase(itaAFBPaths_closed,'figure_handle',hFig,'hold','on','colormap',co(4,:));
ita_plot_freq_phase(itaAFBPath_directions,'figure_handle',hFig,'hold','on','colormap',co(3,:));
ita_plot_freq_phase(itaAFBPaths_mean,'figure_handle',hFig,'hold','on','colormap',co(1,:));
nChannelsFit = [itaAFBPaths_persons.nChannels, itaAFBPaths_open.nChannels, itaAFBPaths_closed.nChannels, itaSecPath_directions.nChannels, itaAFBPaths_mean.nChannels];
legendText = {'persons','open','closed','dummy', 'mean'};
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);




%% AFB - calculate means and plot
% calculate individual means
for idx = 1:length(itaAFBPathsFit)
    itaAFBPathsFit_mean(idx) = mean(itaAFBPathsFit(idx));
end

co = winter(length(itaAFBPathsFit_mean)+2);
hFig = figure('Name','Secondary Path');
for idx = 1:length(itaAFBPathsFit_mean)
    [~, axh] = ita_plot_freq_phase(itaAFBPathsFit_mean(idx),'figure_handle',hFig,'hold','on','colormap',co(idx,:));
    nChannelsFit(idx) = itaAFBPathsFit_mean(idx).nChannels;
    legendText{idx} = itaAFBPathsFit_mean(idx).comment;
end
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);


%% PrimPath - calculate means and plot
itaPrimPaths_mean = mean(itaPrimPathLateral);
itaPrimPaths_closed = itaPrimPathsFit(1);
itaPrimPaths_open = itaPrimPathsFit(4);
itaPrimPaths_persons = ita_merge(itaPrimPathsFit([2,3,5]));

co = winter(6);
hFig = figure('Name','Primary Path');
[~, axh] = ita_plot_freq_phase(itaPrimPaths_persons,'figure_handle',hFig,'hold','on','colormap',co(6,:));
ita_plot_freq_phase(itaPrimPaths_open,'figure_handle',hFig,'hold','on','colormap',co(5,:));
ita_plot_freq_phase(itaPrimPaths_closed,'figure_handle',hFig,'hold','on','colormap',co(4,:));
ita_plot_freq_phase(itaPrimPaths_mean,'figure_handle',hFig,'hold','on','colormap',co(1,:));
nChannelsFit = [itaPrimPaths_persons.nChannels, itaPrimPaths_open.nChannels, itaPrimPaths_closed.nChannels,  itaPrimPaths_mean.nChannels];
legendText = {'persons','open','closed','mean'};
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);
ylim(axh(1),[-70,20]);

%% Primary - calculate means and plot
% calculate individual means
for idx = 1:length(itaPrimPathsFit)
    itaPrimPathsFit_mean(idx) = mean(itaPrimPathsFit(idx));
end

co = winter(length(itaPrimPathsFit_mean)+2);
hFig = figure('Name','Secondary Path');
for idx = 1:length(itaPrimPathsFit_mean)
    [~, axh] = ita_plot_freq_phase(itaPrimPathsFit_mean(idx),'figure_handle',hFig,'hold','on','colormap',co(idx,:));
    nChannelsFit(idx) = itaPrimPathsFit_mean(idx).nChannels;
    legendText{idx} = itaPrimPathsFit_mean(idx).comment;
end
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);

%% PrimPath Chamber - calculate means and plot
itaPrimPaths_mean = mean(itaPrimPath_directions);

map = bone(itaPrimPath_directions.nChannels);
coMean = [1,0,0; 0,1,0];
hFig = figure('Name','Primary Path');
[~, axh] = ita_plot_freq_phase(itaPrimPath_directions,'figure_handle',hFig,'hold','on','colormap',map);
ita_plot_freq_phase(itaPrimPaths_mean,'figure_handle',hFig,'hold','on','colormap',coMean(1,:));
nChannelsFit = [itaPrimPath_directions.nChannels, itaPrimPaths_mean.nChannels];
legendText = {'directions','mean'};
legendGroups(axh(1), legendText, nChannelsFit);
xlim(axh(1),[20,20000]);
xlim(axh(2),[20,20000]);
