classdef tile_parameters < handle
    properties
        idx uint32
        parent
        layers(:, :) {mustBeScalarIfExist, mustBePositiveIfExist, mustBeLessThanOrEqualIfExist(layers, 65535)}
        order(:, :) {mustBeScalarIfExist, mustBeNonnegativeIfExist, mustBeIntegerIfExist, mustBeLessThanOrEqualIfExist(order, 4)}
        ycc(1, :) char {mustBeMemberIfExist(ycc, {'yes', 'no'})}
        use_SOP(1, :) char {mustBeMemberIfExist(use_SOP, {'yes', 'no'})}
        use_EPH(1, :) char {mustBeMemberIfExist(use_EPH, {'yes', 'no'})}
        %
        levels(1, :) {mustBeNonnegativeIfExist, mustBeLessThanOrEqualIfExist(levels, 32)}
        reversible(1, :) char {mustBeMemberIfExist(reversible, {'yes', 'no'})}
        blk(1, :) {mustBeValidBlkIfExist}
        use_precincts(1, :) char {mustBeMemberIfExist(use_precincts, {'yes', 'no'})}
        precincts(:, 2) {mustBePositiveIfExist, mustBeLog2IntegerIfExist, mustBeLessThanOrEqualIfExist(precincts, 32768)}
        qstep(:, :) {mustBeScalarIfExist, mustBePositiveIfExist, mustBeLessThanOrEqualIfExist(qstep, 2)}
        guard(:, :) {mustBeScalarIfExist, mustBePositiveIfExist, mustBeIntegerIfExist, mustBeLessThanOrEqualIfExist(guard, 7)}
        Cmodes(:, :) {mustBeScalarIfExist, mustBeNonnegativeIfExist, mustBeIntegerIfExist}
        tilepart_POC POC_marker
    end
    methods
        function outObj = tile_parameters(t, lay, ord, lev, rev, yc, cblk, upre, pre, mode, sop, eph, qs, ng)
            if nargin == 1
                outObj.idx = t;
            end
            if nargin > 1
                outObj.layers = lay;
                outObj.order = ord;
                outObj.levels = lev;
                outObj.reversible = rev;
                outObj.ycc = yc;
                outObj.blk = cblk;
                outObj.use_precincts = upre;
                outObj.precincts = pre;
                outObj.qstep = qs;
                outObj.guard = ng;
                outObj.Cmodes = mode;
                outObj.use_SOP = sop;
                outObj.use_EPH = eph;
            end
        end
    end
end

function mustBeScalarIfExist(a)
if isempty(a) == false
    if isscalar(a) == false
        error('Values assigned to this property must be integer');
    end
end
end
function mustBeIntegerIfExist(a)
if isempty(a) == false
    b = floor(a);
    if sum(b - a) ~= 0
        error('Values assigned to this property must be integer');
    end
end
end
function mustBeLog2IntegerIfExist(a)
if isempty(a) == false
    b = floor(log2(a));
    if sum(b - log2(a)) ~= 0
        error('Values assigned to this property must be log2-integer');
    end
end
end
function mustBePositiveIfExist(a)
if isempty(a) == false
    if any(a(:) <= 0)
        error('Values assigned to this property must be positive');
    end
end
end
function mustBeNonnegativeIfExist(a)
if isempty(a) == false
    if any(a(:) < 0)
        error('Values assigned to this property must be non-negative');
    end
end
end

function mustBeLessThanOrEqualIfExist(a, b)
if isempty(a) == false
    if any(a(:) > b)
        error('Values assigned to this property must be less than equal to %d', b);
    end
end
end

function mustBeMemberIfExist(a, b)
if isempty(a) == false
    if ismember(a, b) == false
        error('Values assigned to this property must be member of ''yes'' or ''no''');
    end
end
end

function mustBeValidBlkIfExist(a)
if isempty(a) == false
    b = floor(log2(a));
    assert(sum(log2(a) - b) == 0);
    assert(size(a, 1) == 1 && size(a, 2) == 2);
    if any(a(:) > 64) || any(a(:) < 4) || a(1) * a(2) > 4096
        error('codeblock size error');
    end
end
end