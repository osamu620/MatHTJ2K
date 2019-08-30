classdef ebcot_states < handle
    properties
        sigma int32
        sigma_ int32
        dummy_sigma int32
        pi_ int32
        is_causal logical
    end
    methods
        function outObj = ebcot_states(size_x, size_y, inObj)
            if nargin < 3
                assert(size_x <= 128 && size_y <= 128 && size_x * size_y <= 4096);
                outObj.sigma       = zeros(size_y, size_x, 'int32');
                outObj.sigma_      = zeros(size_y, size_x, 'int32');
                outObj.dummy_sigma = zeros(size_y + 2, size_x + 2, 'int32');
                outObj.pi_         = zeros(size_y, size_x, 'int32');
                outObj.is_causal = false;
            else
                outObj.sigma = inObj.sigma;
                outObj.sigma_ = inObj.sigma_;
                outObj.dummy_sigma = inObj.dummy_sigma;
                outObj.pi_ = inObj.pi_;
                outObj.is_causal = inObj.is_causal;
            end
        end
        function update_sigma(inObj, val, y, x)
            inObj.sigma(y, x) = val;
            inObj.dummy_sigma(2:end-1, 2:end-1) = inObj.sigma;
        end
    end
end