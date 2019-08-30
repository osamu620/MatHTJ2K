function [quantStyle, quantStyleComponent] = get_quant_Styles(main_header, tilepart_header, c)

if isempty(findobj(tilepart_header.QCC, 'Cqcc', c)) == false
    quantStyleComponent = findobj(tilepart_header.QCC, 'Cqcc', c);
elseif isempty(tilepart_header.QCD) == false
    quantStyleComponent = tilepart_header.QCD;
elseif isempty(findobj(main_header.QCC, 'Cqcc', c)) == false
    quantStyleComponent = findobj(main_header.QCC, 'Cqcc', c);
else
    quantStyleComponent = main_header.QCD;
end

if isempty(tilepart_header.QCD) == false
    quantStyle = tilepart_header.QCD;
else
    quantStyle = main_header.QCD;
end