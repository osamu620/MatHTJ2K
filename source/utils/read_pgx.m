function out = read_pgx(file_name)

fid = fopen(file_name, 'r');
assert(fid ~= -1, 'file %s is not found.', file_name);

assert(fread(fid, 1, 'uint8') == uint8('P'));
assert(fread(fid, 1, 'uint8') == uint8('G'));

a = eat_space(fid);
Endian = 'b';
if a == uint8('L')
    assert(fread(fid, 1, 'uint8') == uint8('M'));
    Endian = 'l';
else
    assert(a == uint8('M'));
    assert(fread(fid, 1, 'uint8') == uint8('L'));
end

a = eat_space(fid);
is_signed = false;
if a == uint8('+') || a == uint8('-')
    if a == uint8('-')
        is_signed = true;
    end

    a = eat_space(fid);
end
bitDepth = 0;

while a ~= ' '
    %     if a == '+' || a == '-'
    %         a = fread(fid, 1, '*char');
    %     end
    bitDepth = bitDepth * 10 + double(a) - 48;
    a = fread(fid, 1, 'uint8');
end

a = eat_space(fid);
width = 0;
while a ~= ' '
    width = width * 10 + double(a) - 48;
    a = fread(fid, 1, 'uint8');
end


a = eat_space(fid);
height = 0;
while a ~= 10 && a ~= 13
    height = height * 10 + double(a) - 48;
    a = fread(fid, 1, 'uint8');
    if a == uint8('\n')
        a = fread(fid, 1, 'uint8');
    end
end

num_samples = width * height;
tmp = zeros(1, num_samples);
byte_per_sample = ceil(bitDepth / 8);
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

out = reshape(tmp, [width, height])';
end

function out = eat_space(fid)
out = fread(fid, 1, 'uint8');
while out == uint8(' ') || out == 10 || out == 13
    out = fread(fid, 1, 'uint8');
end
end
