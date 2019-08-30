classdef tagTree < matlab.mixin.Copyable
    properties
        level uint8
        node tagTreeNode
        numNode uint32
        numCblkX uint32
        numCblkY uint32
    end
    methods
        % Constructor
        function Obj = tagTree(x, y)
            if nargin ~= 0
                Obj.level = uint8(1);
                Obj.numCblkX = uint32(x);
                Obj.numCblkY = uint32(y);
                num_nodes = uint32(0);
                x = Obj.numCblkX;
                y = Obj.numCblkY;
                while 1
                    n = x * y;
                    num_nodes = num_nodes + uint32(n);
                    x = ceil(x/2);
                    y = ceil(y/2);
                    if ~(n > 1)
                        break;
                    else
                        Obj.level = Obj.level + 1;
                    end
                end
                Obj.numNode = num_nodes;
                for i=1:Obj.numNode
                    if i==1
                        Obj.node = tagTreeNode;
                    else
                        Obj.node = [Obj.node tagTreeNode];
                    end
                end
                nodeidx = int32(1);
                node = Obj.node(nodeidx);
                parentnum = 1;
                x = Obj.numCblkX;
                y = Obj.numCblkY;
                
                % build tag-tree from leaf nodes
                level = Obj.level - 1; % temporal value
                while 1
                    n = x * y;
                    if ~(n > 1)
                        break;
                    end
                    parentnum = parentnum + n;
                    row_parent_idx = parentnum;
                    for j=1:y
                        parent_idx = row_parent_idx;
                        for i=1:x
                            node.level = level;
                            parent = Obj.node(parent_idx);
                            node.idx = nodeidx;
                            node.parent_idx = parent_idx;
                            parent.child_idx = [parent.child_idx nodeidx];
                            nodeidx = nodeidx + 1;
                            node = Obj.node(nodeidx);
                            
                            if mod(i, 2) == 0 && i ~= x
                                parent_idx = parent_idx + 1; % move to next parent in horizontal
                            end
                        end
                        if mod(j, 2) == 0
                            row_parent_idx = row_parent_idx + ceil(x/2); % move to next parent in vertical
                        end
                    end
                    x = ceil(x/2); % number of horizontal elements for next level
                    y = ceil(y/2); % number of vertical elements for next level
                    level = level - 1;
                end
                rootNode = Obj.node(num_nodes);
                rootNode.parent_idx = int32(0); % parent = 0 means I am ROOT
                rootNode.idx = int32(nodeidx); % index of current node
                rootNode.level = uint8(level);
            else
                Obj.level = uint8(0);
                Obj.numNode = uint32(0);
                Obj.numCblkX = uint32(0);
                Obj.numCblkY = uint32(0);
            end
        end
        % Destructor
        function delete(inObj)
            if ~isempty(inObj.node)
                inObj = [];
            end
        end
        % Build tagTree from each leaf's value at encoder
        function set_value_for_tagTreeNodes(inObj)
            N = length(inObj.node);
            for i = 1:N
                if inObj.node(i).is_set == false
                    child_values = zeros(1, length(inObj.node(i).child_idx));
                    for j = 1:length(inObj.node(i).child_idx)
                        child_values(j) = inObj.node(inObj.node(i).child_idx(j)).value;
                    end
                    inObj.node(i).set_value(min(child_values));
                end
            end
        end
    end
    methods (Access = protected)
        function cp = copyElement(inObj)
            cp = tagTree;
            cp.level = inObj.level;
            cp.node = copy(inObj.node);
            cp.numNode = inObj.numNode;
            cp.numCblkX = inObj.numCblkX;
            cp.numCblkY = inObj.numCblkY;
        end
    end
end
