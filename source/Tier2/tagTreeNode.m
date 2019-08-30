classdef tagTreeNode < matlab.mixin.Copyable
    properties
        level uint8
        parent_idx  int32
        child_idx  int32
        idx  int32
        state  uint8
        current_value uint16
        value  uint16
        is_set logical % used only in encoder
    end
    methods
        function outObj = tagTreeNode
            outObj.level = uint8(0);
            outObj.parent_idx = int32(0);
            outObj.idx = int32(-1);
            outObj.state = uint8(0);
            outObj.current_value = uint16(0);
            outObj.value = uint16(0);
            outObj.is_set = false;
        end
        function set_value(inObj, v)
            inObj.value = uint16(v);
            inObj.is_set = true;
        end
    end
    methods (Access = protected)
        function cp = copyElement(inObj)
            cp = tagTreeNode;
            cp.level = inObj.level;
            cp.parent_idx = inObj.parent_idx;
            cp.child_idx = inObj.child_idx;
            cp.idx = inObj.idx;
            cp.state = inObj.state;
            cp.current_value = inObj.current_value;
            cp.value = inObj.value;
            cp.is_set = inObj.is_set;
        end
    end
end