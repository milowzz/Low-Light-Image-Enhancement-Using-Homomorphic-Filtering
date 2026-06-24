function M = eval_metrics(Igray)
% Compute no-reference metrics with graceful fallbacks.
% Returns struct with fields: niqe, brisque, entropy, tenengrad
%
% If NIQE/BRISQUE not available, returns NaN for them and still fills entropy & tenengrad.
%
% Igray expected in [0,1]. If not, it will be scaled.

    if ~isa(Igray,'double'); Igray = im2double(Igray); end
    if size(Igray,3) == 3, Igray = rgb2gray(Igray); end

    % NIQE
    niqeVal = NaN;
    try
        niqeVal = niqe(Igray);  %#ok<NIQE>
    catch
        % NIQE not available; leave as NaN
    end

    % BRISQUE
    brisqueVal = NaN;
    try
        brisqueVal = brisque(Igray); %#ok<BRISQUE>
    catch
        % BRISQUE not available; leave as NaN
    end

    % Entropy (proxy for information content / contrast spread)
    entVal = entropy(Igray);

    % Tenengrad (focus/edge sharpness) using Sobel gradient magnitude
    Gx = imfilter(Igray, fspecial('sobel')'/8, 'replicate', 'conv'); % horizontal
    Gy = imfilter(Igray, fspecial('sobel')/8,  'replicate', 'conv'); % vertical
    G  = hypot(Gx, Gy);
    tenVal = mean2(G.^2);

    M.niqe      = niqeVal;
    M.brisque   = brisqueVal;
    M.entropy   = entVal;
    M.tenengrad = tenVal;
end

