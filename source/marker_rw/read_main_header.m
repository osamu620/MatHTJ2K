function PPM_header = read_main_header(hDsrc, JP2markers, main_header)
M_OFFSET = 1;

DEBUG = 1;
%% check SOC marker
WORD = hDsrc.get_word();
assert(WORD == JP2markers.SOC, 'ERROR: input file is not j2c\n');
%% check SIZ marker
WORD = hDsrc.get_word();
assert(WORD == JP2markers.SIZ, 'ERROR: SIZ marker shall be present as the second marker segment.\n');

%% read parameters into SIZ marker
main_header.read_SIZ(hDsrc);

%% parse main header
WORD = hDsrc.get_word();
while WORD ~= JP2markers.SOT
    switch WORD
        case JP2markers.CAP
            main_header.read_CAP(hDsrc);
        case JP2markers.PRF
            fprintf('INFO: PRF is found\n');
            main_header.read_PRF(hDsrc);
        case JP2markers.COD % required
            main_header.read_COD(hDsrc);
        case JP2markers.COC
            main_header.read_COC(hDsrc);
        case JP2markers.QCD % required
            main_header.read_QCD(hDsrc);
        case JP2markers.QCC
            main_header.read_QCC(hDsrc);
        case JP2markers.RGN
            main_header.read_RGN(hDsrc);
        case JP2markers.POC
            main_header.read_POC(hDsrc);
        case JP2markers.PPM
            fprintf('INFO: PPM is found\n');
            main_header.read_PPM(hDsrc);
        case JP2markers.TLM
            fprintf('INFO: TLM is found\n');
            main_header.read_TLM(hDsrc);
        case JP2markers.PLM
            fprintf('INFO: PLM is found\n');
        case JP2markers.CRG
            fprintf('INFO: CRG is found\n');
            main_header.read_CRG(hDsrc);
        case JP2markers.COM
            main_header.read_COM(hDsrc);
        case JP2markers.CPF
            fprintf('INFO: CPF is found\n');
            main_header.read_CPF(hDsrc);
        otherwise
            fprintf('WARNING: Unknown marker 0x%s is found. This will be skipped.\n', dec2hex(WORD));
    end
    WORD = hDsrc.get_word();
end
assert(WORD == JP2markers.SOT);
% rewind 2 bytes for tile-part header parsing.
hDsrc.pos = hDsrc.pos - 2;

% check SIZ marker segment
x0 = zeros(1, main_header.SIZ.Csiz, 'uint32');
x1 = zeros(1, main_header.SIZ.Csiz, 'uint32');
y0 = zeros(1, main_header.SIZ.Csiz, 'uint32');
y1 = zeros(1, main_header.SIZ.Csiz, 'uint32');
component_width = zeros(1, main_header.SIZ.Csiz, 'uint32');
component_height = zeros(1, main_header.SIZ.Csiz, 'uint32');
for c = 0:main_header.SIZ.Csiz - 1
    x0(c + M_OFFSET) = ceil_quotient_int(main_header.SIZ.XOsiz, main_header.SIZ.XRsiz(c + M_OFFSET), 'uint32');
    x1(c + M_OFFSET) = ceil_quotient_int(main_header.SIZ.Xsiz, main_header.SIZ.XRsiz(c + M_OFFSET), 'uint32');
    y0(c + M_OFFSET) = ceil_quotient_int(main_header.SIZ.YOsiz, main_header.SIZ.YRsiz(c + M_OFFSET), 'uint32');
    y1(c + M_OFFSET) = ceil_quotient_int(main_header.SIZ.Ysiz, main_header.SIZ.YRsiz(c + M_OFFSET), 'uint32');
    component_width(c + M_OFFSET) = x1(c + M_OFFSET) - x0(c + M_OFFSET);
    component_height(c + M_OFFSET) = y1(c + M_OFFSET) - y0(c + M_OFFSET);
    if DEBUG == 1
        fprintf('Component #%3d, (width, height) = (%d, %d), subsampling (%d, %d)\n', ...
            c, component_width(c + M_OFFSET), component_height(c + M_OFFSET),...
            main_header.SIZ.XRsiz(c + M_OFFSET), main_header.SIZ.YRsiz(c + M_OFFSET));
    end
    assert(0<=main_header.SIZ.XTOsiz && main_header.SIZ.XTOsiz <= main_header.SIZ.XOsiz, 'ERROR: Tile width is incorrect.\n');
    assert(0<=main_header.SIZ.YTOsiz && main_header.SIZ.YTOsiz <= main_header.SIZ.YOsiz, 'ERROR: Tile height is incorrect.\n');
    assert((main_header.SIZ.XTsiz + main_header.SIZ.XTOsiz) > main_header.SIZ.XOsiz, 'ERROR: Tile size plus tile offset shall be greater than the image area offset.');
    assert((main_header.SIZ.YTsiz + main_header.SIZ.YTOsiz) > main_header.SIZ.YOsiz, 'ERROR: Tile size plus tile offset shall be greater than the image area offset.');
end

% concatenate PPM marker segments
if isempty(main_header.PPM) == false
    num_PPM = length(main_header.PPM);
    header = [];
    buf = [];
    for i = 1:num_PPM
        buf = [buf, main_header.PPM(i).ppmbuf];
    end
    len = length(buf);
    pos = 0;
    while len > pos
        N = 0;
        for i = 0:3
            N = 256*N + int32(buf(pos + M_OFFSET));
            pos = pos + 1;
        end
        header = [header, buf(pos + M_OFFSET:pos + N)];
        pos = pos + N;
    end
    assert(len == pos);
    PPM_header = packet_header_reader(header);
else
    PPM_header = [];
end

assert(main_header.COD.is_read == true, 'ERROR: no COD marker is found in the main header.');
assert(main_header.QCD.is_read == true, 'ERROR: no QCD marker is found in the main header.');
if main_header.SIZ.needCAP == true
    assert(main_header.CAP.is_read == true, 'ERROR: if bit 14 of Rsiz is 1, CAP marker shall appear in the main header.');
end