classdef jp2_markers < handle
    properties
        SOC uint16
        SOT uint16
        SOD uint16
        EOC uint16
        SIZ uint16
        PRF uint16
        CAP uint16
        COD uint16
        COC uint16
        RGN uint16
        QCD uint16
        QCC uint16
        POC uint16
        TLM uint16
        PLM uint16
        PLT uint16
        PPM uint16
        PPT uint16
        SOP uint16
        EPH uint16
        CRG uint16
        COM uint16
        CPF uint16
    end
    methods
        function outObj = jp2_markers(is_main)
            if nargin == 0 || is_main == true
                outObj.SOC = uint16(hex2dec('FF4F'));
                outObj.SOT = hex2dec('FF90');
                outObj.SOD = hex2dec('FF93');
                outObj.EOC = hex2dec('FFD9');
                outObj.SIZ = uint16(hex2dec('FF51'));
                outObj.PRF = hex2dec('FF56');
                outObj.CAP = hex2dec('FF50');
                outObj.COD = hex2dec('FF52');
                outObj.COC = hex2dec('FF53');
                outObj.RGN = hex2dec('FF5E');
                outObj.QCD = hex2dec('FF5C');
                outObj.QCC = hex2dec('FF5D');
                outObj.POC = hex2dec('FF5F');
                outObj.TLM = hex2dec('FF55');
                outObj.PLM = hex2dec('FF57');
                outObj.PLT = hex2dec('FF58');
                outObj.PPM = hex2dec('FF60');
                outObj.PPT = hex2dec('FF61');
                outObj.SOP = hex2dec('FF91');
                outObj.EPH = hex2dec('FF92');
                outObj.CRG = hex2dec('FF63');
                outObj.COM = hex2dec('FF64');
                outObj.CPF = hex2dec('FF59');
            elseif is_main == false
                outObj.SOD = hex2dec('FF93');
                outObj.EOC = hex2dec('FFD9');
                outObj.COD = hex2dec('FF52');
                outObj.COC = hex2dec('FF53');
                outObj.RGN = hex2dec('FF5E');
                outObj.QCD = hex2dec('FF5C');
                outObj.QCC = hex2dec('FF5D');
                outObj.POC = hex2dec('FF5F');
                outObj.PLT = hex2dec('FF58');
                outObj.PPT = hex2dec('FF61');
                outObj.COM = hex2dec('FF64');
            end
        end
    end
end
