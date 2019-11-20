function out = read_pgx(file_name)

fid = fopen(file_name, 'r');
assert(fid ~= -1, 'file %s is not found.', file_name);

[HEADER0] = textscan(fid, '%s %s %s', 1, 'Delimiter', {' ', '\n'}, 'MultipleDelimsAsOne',1);

assert(strcmp(HEADER0{1}{1}, 'PG'));

Endian = 'b';
if strcmp(HEADER0{2}{1}, 'LM') == true
    Endian = 'l';
end
is_signed = {};
S = HEADER0{3}{1};
if length(S) ~= 1
    if strcmp(S(1), '+') == true
        is_signed = false;
        bitDepth = str2double(S(2:end));
    elseif strcmp(S(1), '-') == true
        is_signed = true;
        bitDepth = str2double(S(2:end));
    else
        bitDepth = str2double(S);
    end
else
    if strcmp(S(1), '+') == true
        is_signed = false;
    elseif strcmp(S(1), '-') == true
        is_signed = true;
    else
        bitDepth = str2double(S(1));
    end
end

if length(S) ~= 1
    if isempty(is_signed) == true
        is_signed = false;
    end
    HEADER1 = textscan(fid, '%d %d', 1, 'Delimiter', {' ', '\n'}, 'MultipleDelimsAsOne',1);
    width = double(HEADER1{1});
    height = double(HEADER1{2});
else
    if isempty(is_signed) == true
        is_signed = false;
        bitDepth = str2double(S(1));
        HEADER1 = textscan(fid, '%d %d', 1, 'Delimiter', {' ', '\n'}, 'MultipleDelimsAsOne',1);
        width = double(HEADER1{1});
        height = double(HEADER1{2});
    else
        HEADER1 = textscan(fid, '%d %d %d', 1, 'Delimiter', {' ', '\n'}, 'MultipleDelimsAsOne',1);
        bitDepth = double(HEADER1{1});
        width = double(HEADER1{2});
        height = double(HEADER1{3});
    end
end

num_samples = width * height;
tmp = zeros(1, num_samples);
byte_per_sample = ceil(bitDepth/8);
if byte_per_sample == 1
    if is_signed == true
        tmp = fread(fid, num_samples, 'int8');
    else
        tmp = fread(fid, num_samples, 'uint8');
    end
elseif byte_per_sample == 2
    if is_signed == true
        tmp = fread(fid, num_samples, 'int16', Endian);
    else
        tmp = fread(fid, num_samples, 'uint16', Endian);
    end
elseif byte_per_sample == 4
    if is_signed == true
        tmp = fread(fid, num_samples, 'int32', Endian);
    else
        tmp = fread(fid, num_samples, 'uint32', Endian);
    end
end

out = reshape(tmp, [width height])';
