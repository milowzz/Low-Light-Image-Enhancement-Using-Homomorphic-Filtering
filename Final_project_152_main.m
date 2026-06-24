% EE 152 Project: Low-Light Enhancement via Homomorphic Filtering
% Ditto Bhadra, Emilio
% Main script

clear; clc; close all;

%  Paths 
inDir = "C:\Users\Milog\Downloads\ExDark\ExDark\People";   % put test images here
outDir = fullfile(pwd, 'results');  % outputs (created if not exists)
if ~exist(outDir, 'dir'); mkdir(outDir); end

%  Parameters 
% Homomorphic filter params (tune these later for parameter study)
params.H.gammaL = 0.6;   % < 1, suppress low-freq illumination
params.H.gammaH = .5;   % > 1, boost high-freq details
params.H.c      = 1.0;   % slope
params.H.D0     = 250;    % cutoff (in pixels)
params.H.order  = 1;     % filter order

% Baselines
params.gammaCorr = 1.2;          % gamma value
params.heMedSize = [3 3];        % <-- median filter window for HistEq result

%  Read images 
imgFiles = dir(fullfile(inDir, '*.*'));
imgFiles = imgFiles(~[imgFiles.isdir]);

if isempty(imgFiles)
    error('No images found in %s. Add some test images (jpg/png).', inDir);
end

names = {};
metrics_homo = [];
metrics_he   = [];
metrics_gam  = [];

for k = 1:numel(imgFiles)
    fname  = imgFiles(k).name;
    inPath = fullfile(inDir, fname);

    % Read image as double [0,1]
    I0 = im2double(imread(inPath));
    if size(I0,3) == 3
        Igray = rgb2gray(I0);
    else
        Igray = I0;
    end

    %  Methods 
    Ihomo = homomorphic_enhance(I0, params.H);        % our method

    % Histogram equalization (grayscale)
    Ihe_raw = histeq(Igray);                          % raw hist-eq result

    % >>> DENOISE HIST-EQ RESULT WITH MEDIAN FILTER <<<
    % This removes a lot of the speckle / amplified noise
    Ihe = medfilt2(Ihe_raw, params.heMedSize);        % e.g. [3 3] or [5 5]

    % Gamma correction
    Igam  = imadjust(Igray, [], [], params.gammaCorr);

    %  Save outputs 
    [~, stemName, ~] = fileparts(fname);
    out_base = fullfile(outDir, stemName);

    imwrite(Ihomo, [out_base '_homo.png']);
    imwrite(Ihe,   [out_base '_he_med.png']);  % note: median-filtered HistEq
    imwrite(Igam,  [out_base '_gamma.png']);

    %  Evaluate (no-reference metrics) 
    % Make grayscale version of homomorphic result for evaluation
    if size(Ihomo,3) == 3
        Ihomo_g = rgb2gray(Ihomo);
    else
        Ihomo_g = Ihomo;
    end

    % Use the *filtered* HistEq image for metrics
    m_homo = eval_metrics(Ihomo_g);
    m_he   = eval_metrics(Ihe);
    m_gam  = eval_metrics(Igam);

    names{end+1,1}     = stemName; %#ok<SAGROW>
    metrics_homo(end+1,:) = [m_homo.niqe, m_homo.brisque, m_homo.entropy, m_homo.tenengrad]; %#ok<SAGROW>
    metrics_he(end+1,:)   = [m_he.niqe,   m_he.brisque,   m_he.entropy,   m_he.tenengrad  ]; %#ok<SAGROW>
    metrics_gam(end+1,:)  = [m_gam.niqe,  m_gam.brisque,  m_gam.entropy,  m_gam.tenengrad ]; %#ok<SAGROW>

    %  Plots (optional) 
    try
        % Pass the denoised HistEq result to your plotting function
        quick_plots(Igray, Ihomo_g, Ihe, Igam, stemName, outDir);
    catch
        % If plotting fails (e.g., no display), just skip
    end
end

%  Summarize 
headers = {'NIQE','BRISQUE','Entropy','Tenengrad'};
T_homo = array2table(metrics_homo, 'VariableNames', headers, 'RowNames', names);
T_he   = array2table(metrics_he,   'VariableNames', headers, 'RowNames', names);
T_gam  = array2table(metrics_gam,  'VariableNames', headers, 'RowNames', names);

writetable(addNameCol(T_homo), fullfile(outDir,'metrics_homomorphic.csv'));
writetable(addNameCol(T_he),   fullfile(outDir,'metrics_histEq_med.csv'));
writetable(addNameCol(T_gam),  fullfile(outDir,'metrics_gamma.csv'));

disp('=== Mean metrics (lower NIQE/BRISQUE better; higher Entropy/Tenengrad better) ===');
disp('Homomorphic:'), disp(mean(metrics_homo,1));
disp('HistEq:'), disp(mean(metrics_he,1));
disp('Gamma      :'), disp(mean(metrics_gam,1));

% ----- local helper -----

function T = addNameCol(Tin)
    T = Tin;
    T.Image = Tin.Properties.RowNames;
    T = movevars(T,'Image','Before',1);
    T.Properties.RowNames = {};
end

