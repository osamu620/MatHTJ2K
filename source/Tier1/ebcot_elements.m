classdef ebcot_elements < handle
    properties
        sign_array int32
        dummy_sign int32
        magnitude_array int32
        p_idx int32
        bitplane int32
        p int32
    end
    methods
        function outObj = ebcot_elements(size_x, size_y, inObj)
            if nargin < 3
                assert(size_x <= 128 && size_y <= 128 && size_x * size_y <= 4096);
                outObj.sign_array = zeros(size_y, size_x, 'int32');
                outObj.dummy_sign = zeros(size_y + 2, size_x + 2, 'int32');
                outObj.magnitude_array = zeros(size_y, size_x, 'int32');
                outObj.bitplane = zeros(size_y, size_x, 'int32');
                outObj.p = zeros(size_y, size_x, 'int32');
                outObj.p_idx = 0;
            else
                outObj.sign_array = inObj.sign_array;
                outObj.dummy_sign = inObj.dummy_sign;
                outObj.magnitude_array = inObj.magnitude_array;
                outObj.p_idx = inObj.p_idx;
                outObj.bitplane = inObj.bitplane;
                outObj.p = inObj.p;
            end
        end
        function set_maginitude_bitplane(inObj, p)
            tmp = inObj.bitplane * 2^int32(p);
            inObj.magnitude_array = inObj.magnitude_array + tmp;
        end
        function clear_bitplane(inObj)
            inObj.bitplane = zeros(size(inObj.bitplane), 'int32');
        end
        function update_sign_array(inObj, val, y, x)
            inObj.sign_array(y, x) = val;
            inObj.dummy_sign(2:end - 1, 2:end - 1) = inObj.sign_array;
        end
        function set_sign_array(inObj, sign_matrix)
            inObj.sign_array = sign_matrix;
            inObj.dummy_sign(2:end - 1, 2:end - 1) = inObj.sign_array;
        end
    end
end