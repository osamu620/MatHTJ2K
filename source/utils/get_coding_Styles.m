function [codingStyle, codingStyleComponent] = get_coding_Styles(main_header, tilepart_header, c)

if isempty(tilepart_header.COD) == false
    codingStyle = tilepart_header.COD;
else
    codingStyle = main_header.COD;
end

if nargin == 3
    if isempty(findobj(tilepart_header.COC, 'Ccoc', c)) == false
        codingStyleComponent = findobj(tilepart_header.COC, 'Ccoc', c);
    elseif isempty(tilepart_header.COD) == false
        codingStyleComponent = tilepart_header.COD;
    elseif isempty(findobj(main_header.COC, 'Ccoc', c)) == false
        codingStyleComponent = findobj(main_header.COC, 'Ccoc', c);
    else
        codingStyleComponent = main_header.COD;
    end
    if codingStyle.get_multiple_component_transform() == 1
        assert(codingStyle.get_transformation() == codingStyleComponent.get_transformation(), ...
            'DWT filter(9x7 or 5x3) may be different among components only if ''ycc'' for corresponding tile or main header is ''no.''');
    end
end