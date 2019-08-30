function out = read_pgx(file_name)

fid = fopen(file_name, 'r');
assert(fid ~= -1, 'file %s is not found.', file_name);

assert(fread(fid, 1, '*char') == 'P');
assert(fread(fid, 1, '*char') == 'G');

a = fread(fid, 1, '*char');
while a == ' '
   a = fread(fid, 1, '*char');
end

Endian = 'b';
if a == 'L'
    assert(fread(fid, 1, '*char') == 'M');
    Endian = 'l';
else
    assert(a == 'M');
    assert(fread(fid, 1, '*char') == 'L');
end

a = fread(fid, 1, '*char');
while a == ' '
   a = fread(fid, 1, '*char');
end

is_signed = false;
if a == '-'
    is_signed = true;
end

bitDepth = 0;
%a = fread(fid, 1, '*char');
while a ~= ' '
    if a == '+' || a == '-'
        a = fread(fid, 1, '*char');
    end
    bitDepth = bitDepth*10 + str2num(a);
    a = fread(fid, 1, '*char');
end

width = 0;
a = fread(fid, 1, '*char');
while a ~= ' '
    width = width*10 + str2num(a);
    a = fread(fid, 1, '*char');
end

height = 0;
a = fread(fid, 1, '*char');
while a ~= 10 && a~= 13
    height = height*10 + str2num(a);
    a = fread(fid, 1, '*char');
    if a == '\n'
        a = fread(fid, 1, '*char');
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



