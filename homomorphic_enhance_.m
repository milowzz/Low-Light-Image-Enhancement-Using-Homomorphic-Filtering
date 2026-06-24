function Iout = homomorphic_enhance(Iin, Hparams)
% Homomorphic enhancement in frequency domain.
% Works for gray or RGB. Applies on log-domain per-channel, frequency filter, then exp.
% Hparams: gammaL (<1), gammaH (>1), c (slope), D0 (cutoff), order (optional).

    validateattributes(Iin, {'double','single'}, {'>=',0,'<=',1}, mfilename, 'Iin');

    if size(Iin,3)==1
        Iout = processChannel(Iin, Hparams);
    else
        Iout = zeros(size(Iin));
        for ch = 1:3
            Iout(:,:,ch) = processChannel(Iin(:,:,ch), Hparams);
        end
        % clamp
        Iout = min(max(Iout,0),1);
    end
end


function O = processChannel(I, P)
    % Avoid log(0)
    eps0 = 1e-6;
    L = log(I + eps0);

    % FFT
    [M,N] = size(L);
    Lfft = fftshift(fft2(L));

    % Construct homomorphic filter H(u,v)
    [U,V] = meshgrid( (-floor(N/2)):(ceil(N/2)-1), ...
                      (-floor(M/2)):(ceil(M/2)-1) );
    D = sqrt(U.^2 + V.^2);

    % Filter order (fallback to 2 if not provided)
    if isfield(P,'order')
        n = max(1, round(P.order));
    else
        n = 2;
    end

    D0 = P.D0;
    % c = P.c;   % (not used in this Butterworth-style version)

    % Butterworth-like high-emphasis homomorphic filter
    H = (P.gammaH - P.gammaL) .* ( 1 ./ (1 + (D0./(D + eps)).^(2*n)) ) + P.gammaL;

    % Filter in freq domain
    Sout = Lfft .* H;

    % Inverse FFT & exponentiate
    s = real(ifft2(ifftshift(Sout)));
    O = exp(s) - eps0;

    % Normalize to [0,1]
    O = O - min(O(:));
    O = O ./ max(O(:) + 1e-12);
end

