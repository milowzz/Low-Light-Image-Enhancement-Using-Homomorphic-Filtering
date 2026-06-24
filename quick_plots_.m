function quick_plots(Iin, Ihomo, Ihe, Igam, stemName, outDir)
%QUICK_PLOTS  Original + methods + histograms.
% Layout (2 x 4 tiles):
%
%   [ Original    Homomorphic    HistEq      Gamma      ]
%   [ Hist(Orig)  Hist(Homo)     Hist(HE)    Hist(Gamma)]
%
% Iin    : original (grayscale) image
% Ihomo  : homomorphic result (grayscale)
% Ihe    : histogram equalization result
% Igam   : gamma correction result

    if nargin < 6
        outDir = pwd;
    end
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end

    fig = figure('Visible','off');
    t = tiledlayout(2,4,'TileSpacing','compact','Padding','compact');

    %  Top row: images 
    % Original
    nexttile;
    imshow(Iin,[]);
    title('Original');

    % Homomorphic
    nexttile;
    imshow(Ihomo,[]);
    title('Homomorphic');

    % HistEq
    nexttile;
    imshow(Ihe,[]);
    title('HistEq');

    % Gamma
    nexttile;
    imshow(Igam,[]);
    title('Gamma');

    %  Bottom row: histograms 
    % Helper: all images are assumed scaled to [0,1]
    % Original hist
    nexttile;
    histogram(Iin(:),256,'EdgeColor','none');
    title('Hist(Original)');
    xlim([0 1]);

    % Homomorphic hist
    nexttile;
    histogram(Ihomo(:),256,'EdgeColor','none');
    title('Hist(Homomorphic)');
    xlim([0 1]);

    % HistEq hist
    nexttile;
    histogram(Ihe(:),256,'EdgeColor','none');
    title('Hist(HistEq)');
    xlim([0 1]);

    % Gamma hist
    nexttile;
    histogram(Igam(:),256,'EdgeColor','none');
    title('Hist(Gamma)');
    xlim([0 1]);

    %  Save figure 
    outPath = fullfile(outDir, sprintf('%s_methods.png', stemName));
    try
        exportgraphics(t, outPath, 'Resolution', 150);
    catch
        saveas(gcf, outPath);
    end

    close(fig);
end

