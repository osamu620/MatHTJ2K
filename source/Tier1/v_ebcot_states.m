classdef v_ebcot_states 
    properties
        sigma int32
        sigma_ int32
        dummy_sigma int32
        pi_ int32
        is_causal logical
    end
    methods
        function outObj = v_ebcot_states(inObj)
            outObj.sigma = inObj.sigma;
            outObj.sigma_ = inObj.sigma_;
            outObj.dummy_sigma = inObj.dummy_sigma;
            outObj.pi_  = inObj.pi_;
            outObj.is_causal = inObj.is_causal;
        end
    end
end