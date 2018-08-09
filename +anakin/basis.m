%{
basis: class to define orthonormal, right-handed vector bases.

B0 = anakin.basis();  % no arguments return default object 
B  = anakin.basis(B|m|((a|c|x,y,z),(a|c|x,y,z),(a|c|x,y,z))|q|(axis,angle),<B1>);

where:
- <> denotes optional arguments
- | denotes alternative arguments
- () groups argument options
- B0 is the default basis (canonical vector basis)
- B  is a basis
- m  is a matrix
- a is a vector
- c is an array with the three vector components
- x,y,z are the three vector components
- q are quaternions
- axis is the unit vector of the axis of rotation
- angle is angle of rotation about axis
- B1 is a basis. If given, all previous input as relative to that basis

METHODS:
* matrix: transformation matrix to another basis 
* i,j,k: returns the vectors of the basis (with respect to a chosen
  basis) 
* rotaxis, rotangle: returns unit vector and angle of rotation of B wrt
  B1 
* quaternions: returns the quaternions with respect to another basis
* euler: returns the euler angles (of a chosen type) with respect to
  another basis
* rotatex,rotatey,rotatez: create simply rotated frame about one
  coordinated axis of another basis
* omega, alpha: returns the angular velocity/acceleration vector omega
  with respect to another basis (symbolic variables must be used)
* subs: takes values of the symbolic unknowns and returns a basis with
  purely numeric matrix (symbolic variables must be used)    
* isunitary, isrighthanded: checks the corresponding property and
  returns true or false  
* plot: plots the basis with quiver, at a chosen position

AUTHOR: Mario Merino <mario.merino@uc3m.es>
%}
classdef basis
    properties (Hidden = true, Access = protected)        
        m = [1,0,0;0,1,0;0,0,1]; % transformation matrix: [a(in B0)] = m * [a(in B)]. Or equivalently: the rotation matrix to go from B0 to B
    end 
    methods % creation
        function B = basis(varargin) % constructor
            for i = 1:length(varargin)
               if isa(varargin{i},'sym')
                   varargin{i} = formula(varargin{i}); % enforce formula to allow indexing
               end
            end
            switch nargin
                case 0 % no arguments 
                    return; 
                case 1
                    B.m = anakin.basis(varargin{1},anakin.basis).m; 
                case 2 
                    if isa(varargin{end},'anakin.basis') 
                        if isa(varargin{1},'anakin.basis') % relative basis, basis
                            B.m = varargin{2}.m * varargin{1}.m;
                        elseif numel(varargin{1}) == 4 % relative quaternions, basis
                            qq = varargin{1}; % quaternions with the scalar component last
                            mm = [qq(4)^2+qq(1)^2-qq(2)^2-qq(3)^2,     2*(qq(1)*qq(2)-qq(4)*qq(3)),     2*(qq(1)*qq(3)+qq(4)*qq(2)); % matrix whose columns are the components of the ijk vectors of B expressed in B1
                                      2*(qq(1)*qq(2)+qq(4)*qq(3)), qq(4)^2-qq(1)^2+qq(2)^2-qq(3)^2,     2*(qq(2)*qq(3)-qq(4)*qq(1));
                                      2*(qq(1)*qq(3)-qq(4)*qq(2)),     2*(qq(2)*qq(3)+qq(4)*qq(1)), qq(4)^2-qq(1)^2-qq(2)^2+qq(3)^2];
                            B.m = varargin{2}.m * mm;
                        else % relative matrix, basis
                            B.m = varargin{2}.m * varargin{1};
                        end
                    else % relative matrix, basis
                        B.m = anakin.basis(varargin{1},varargin{2},anakin.basis).m; 
                    end 
                case 3 
                    if isa(varargin{end},'anakin.basis') % relative axis, relative angle, basis
                        axis = anakin.vector(varargin{1},varargin{3}).components;
                        angle = varargin{2};
                        c = cos(angle);
                        s = sin(angle);
                        C = 1-c;                        
                        B.m = [              axis(1)^2*C+c, axis(1)*axis(2)*C-axis(3)*s, axis(1)*axis(3)*C+axis(2)*s;
                               axis(1)*axis(2)*C+axis(3)*s,               axis(2)^2*C+c, axis(2)*axis(3)*C-axis(1)*s;
                               axis(1)*axis(3)*C-axis(2)*s, axis(2)*axis(3)*C+axis(1)*s,               axis(3)^2*C+c];
                    else 
                        B.m = anakin.basis(varargin{1},varargin{2},varargin{3},anakin.basis).m;  
                    end
                case 4 % relative i,j,k (component columns) and basis
                    B.m = [anakin.vector(varargin{1},varargin{4}).components,...
                           anakin.vector(varargin{2},varargin{4}).components,...
                           anakin.vector(varargin{3},varargin{4}).components];
                case 5 
                    B.m = anakin.basis(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5},anakin.basis).m;  
                case 6 
                    if ~isa(varargin{1},'anakin.vector') && numel(varargin{1}) == 1 % relative xyz,j,k, basis
                        B.m = [anakin.vector(varargin{1},varargin{2},varargin{3},varargin{6}).components,...
                               anakin.vector(varargin{4},varargin{6}).components,...
                               anakin.vector(varargin{5},varargin{6}).components];
                    elseif ~isa(varargin{2},'anakin.vector') && numel(varargin{2}) == 1 % relative i,xyz,k, basis
                        B.m = [anakin.vector(varargin{1},varargin{6}).components,...
                               anakin.vector(varargin{2},varargin{3},varargin{4},varargin{6}).components,...
                               anakin.vector(varargin{5},varargin{6}).components];
                    else % relative i,j,xyz, basis
                        B.m = [anakin.vector(varargin{1},varargin{6}).components,...
                               anakin.vector(varargin{2},varargin{6}).components,...
                               anakin.vector(varargin{3},varargin{4},varargin{5},varargin{6}).components];
                    end
                case 7 
                    B.m = anakin.basis(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5},varargin{6},varargin{7},anakin.basis).m;  
                case 8
                    if isa(varargin{1},'anakin.vector') || numel(varargin{1}) == 3 % relative i,xyz,xyz, basis
                        B.m = [anakin.vector(varargin{1},varargin{8}).components,...
                               anakin.vector(varargin{2},varargin{3},varargin{4},varargin{8}).components,...
                               anakin.vector(varargin{5},varargin{6},varargin{7},varargin{8}).components];
                    elseif isa(varargin{4},'anakin.vector') || numel(varargin{4}) == 3 % relative xyz,j,xyz, basis
                        B.m = [anakin.vector(varargin{1},varargin{2},varargin{3},varargin{8}).components,...
                               anakin.vector(varargin{4},varargin{8}).components,...
                               anakin.vector(varargin{5},varargin{6},varargin{7},varargin{8}).components];
                    else % relative i,j,xyz, basis
                        B.m = [anakin.vector(varargin{1},varargin{2},varargin{3},varargin{8}).components,...
                               anakin.vector(varargin{4},varargin{5},varargin{6},varargin{8}).components,...
                               anakin.vector(varargin{7},varargin{8}).components];
                    end
                case 9 
                    B.m = anakin.basis(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5},varargin{6},varargin{7},varargin{8},varargin{9},anakin.basis).m;  
                case 10 % relative xyz, xyz, xyz, B
                    B.m = anakin.basis([varargin{1},varargin{2},varargin{3}],[varargin{4},varargin{5},varargin{6}],[varargin{7},varargin{8},varargin{9}],varargin{10}).m;  
                otherwise
                    error('Wrong number of arguments in basis');
            end  
        end 
        function B = set.m(B,value) % on setting m
            B.m = reshape(value,3,3);
            if isa(B.m,'sym') % symbolic input
                B.m = formula(simplify(B.m)); % simplify and force sym rather than symfun to allow indexing
            end
        end     
    end
    methods % overloads 
        function value = eq(B1,B2) % overload ==
            if isa(B1.m,'sym') || isa(B1.m,'sym') % symbolic inputs
                value = isAlways(B1.m==B2.m,'Unknown','false'); % In case of doubt, false
            else % numeric input
                value = (abs(B1.m - B2.m) < 10*eps(B1.m)+10*eps(B2.m)); 
            end
            value = all(value(:));
        end
        function value = ne(B1,B2) % overload ~=
            value = ~eq(B1,B2);
        end
        function B3 = mtimes(B1,B2) % overloaded * (multiplication of two rotation matrices)
            B3 = B1;
            B3.m = B1.m * B2.m;
        end 
        function B3 = mrdivide(B1,B2) % overloaded /
            B3 = B1;
            B3.m = B1.m / B2.m;
        end 
        function B3 = mldivide(B1,B2) % overloaded \
            B3 = B1;
            B3.m = B1.m \ B2.m;
        end 
    end
    methods % functionality
        function matrix = matrix(B,B1) % transformation matrix to another basis: [a(in B1)] = m * [a(in B)]
            if ~exist('B1','var')
                matrix = B.m; % if no basis is given, use the canonical vector basis
            else
                matrix = B1.m' * B.m;
            end
            if isa(matrix,'sym')
                matrix = formula(simplify(matrix));
            end
        end
        function i = i(B) % vector i of the basis
             i = anakin.vector([1;0;0],B);
        end
        function j = j(B) % vector j of the basis
             j = anakin.vector([0;1;0],B);
        end
        function k = k(B) % vector k of the basis
             k = anakin.vector([0;0;1],B);
        end 
        function axis = rotaxis(B,B1) % rotation axis unit vector from B1
            if ~exist('B1','var')
                B1 = anakin.basis; % if no basis is given, use the canonical vector basis
            end
            mm = B.matrix(B1);
            axis = anakin.vector([mm(3,2)-mm(2,3);mm(1,3)-mm(3,1);mm(2,1)-mm(1,2)],B1).dir; % fails if rotation angle is 0 or 180 deg
        end 
        function angle = rotangle(B,B1) % angle of rotation from B1
            if ~exist('B1','var')
                B1 = anakin.basis; % if no basis is given, use the canonical vector basis
            end
            mm = B.matrix(B1);
            angle = acos((trace(mm)-1)/2);
            if isa(angle,'sym') % symbolic input
                angle = formula(simplify(angle)); % simplify and force sym rather than symfun
            end

        end
        function quaternions = quaternions(B,B1) % quaternions of rotation from B1. Fails when rotation angle is 180 deg
            if ~exist('B1','var')
                B1 = anakin.basis; % if no basis is given, use the canonical vector basis
            end
            mm = B.matrix(B1); 
            quaternions(4) = sqrt(trace(mm)+1)/2; % scalar term q4
            quaternions(1) = -(mm(2,3)-mm(3,2))/(4*quaternions(4)); % q1
            quaternions(2) = -(mm(3,1)-mm(1,3))/(4*quaternions(4)); % q2
            quaternions(3) = -(mm(1,2)-mm(2,1))/(4*quaternions(4)); % q3
            quaternions = reshape(quaternions,4,1); % Force column
            if isa(quaternions,'sym') % symbolic input
                quaternions = formula(simplify(quaternions)); % simplify and force sym rather than symfun to allow indexing
            end
        end
        function euler = euler(B3,B0,type) % Euler angles of chosen type from B1. Fails depending on the value of the intermediate angle: symmetric Euler angles fail for theta2 = 0,180 deg. Asymmetric Euler angles fail for theta2 = 90,270 deg 
            if ~exist('B1','var')
                B0 = anakin.basis; % if no basis is given, use the canonical vector basis
            end
            if ~exist('type','var') % type: a vector like [3,1,3] or [1,2,3] indicating the intrinsic axes of rotation
                type = [3,1,3];            
            end
            m0 = eye(3); % this is B0 here!
            m3 = B3.matrix(B0);
            
            one = anakin.vector(m0(:,type(1))); % first rotation direction
            three = anakin.vector(m3(:,type(3))); % third rotation direction 
            if type(1)==type(3) % symmetric Euler angles
                euler(2) = angle(one,three);
                two = cross(one,three); 
            else % asymmetric Euler angles 
                even = det(m0(:,type)); % get even/odd of permutation of type 
                euler(2) = even * asin(dot(one,three)); 
                two = -even * cross(one,three);
            end 
            two = two.dir; % second rotation direction, normalized
            euler(1) = angle(anakin.vector(m0(:,type(2))),two,one);
            euler(3) = angle(two,anakin.vector(m3(:,type(2))),three); 
            
            euler = reshape(euler,1,3); % Force row
            if isa(euler,'sym') % symbolic input
                euler = formula(simplify(euler)); % simplify and force sym rather than symfun to allow indexing
            end 
        end
        function Bx = rotatex(B,angle) % returns rotated basis about x axis of B by angle
            Bx = B;
            Bx.m = B.m * [1,0,0;0,cos(angle),-sin(angle);0,sin(angle),cos(angle)];            
        end
        function By = rotatey(B,angle) % returns rotated basis about y axis of B by angle
            By = B;
            By.m = B.m * [cos(angle),0,sin(angle);0,1,0;-sin(angle),0,cos(angle)];
        end
        function Bz = rotatez(B,angle) % returns rotated basis about z axis of B by angle
            Bz = B;
            Bz.m = B.m * [cos(angle),-sin(angle),0;sin(angle),cos(angle),0;0,0,1];
        end        
        function omega = omega(B,B1) % Returns the symbolic angular velocity vector with respect to B1
            omega = anakin.vector([dot(B.k,B.j.dt); dot(B.i,B.k.dt); dot(B.j,B.i.dt)],B); % If B1 is not given, assume the canonical vector basis B0
            if exist('B1','var') % If B1 is given, correct previous value
                omega = omega - B1.omega; 
            end 
        end
        function alpha = alpha(B,B1) % Returns the symbolic angular acceleration vector with respect to B1
            alpha = B.omega.dt; % If B1 is not given, assume the canonical vector basis B0
            if exist('B1','var') % If B1 is given, correct previous value
                alpha = alpha - cross(B1.omega,B.omega) - B1.alpha; 
            end
        end
        function B_ = subs(B,variables,values) % particularize symbolic basis
            B_ = B;
            B_.m = double(subs(B.m,variables,values));
        end
    end
    methods % logical tests
        function isunitary = isunitary(B) % all vectors are unitary and mutually orthogonal
            if isa(B.m,'sym') % symbolic inputs
                isunitary = isAlways(B.m' * B.m == eye(3),'Unknown','false'); % In case of doubt, false
            else % numeric input            
                isunitary = (abs(B.m' * B.m - eye(3))<eps(max(abs(B.m(:))))); 
            end 
            isunitary = all(isunitary(:));
        end    
        function isrighthanded = isrighthanded(B) % basis is righthanded
            isrighthanded = (det(B.m) > 0);
            if isa(isrighthanded,'sym')
                isrighthanded = isAlways(isrighthanded,'Unknown','false'); % In case of doubt, false
            end
        end   
    end
    methods % plotting
        function h = plot(B,varargin) % plot. First argument in varargin must be the O vector, if any
            if mod(nargin,2) == 1 % no origin vector is given
                O = anakin.vector; % null vector
            else
                O = varargin{1};
                varargin = varargin(2:end);
            end
            cc = O.components;
            mm = B.m;
            hold on            
            h = quiver3([cc(1),cc(1),cc(1)],[cc(2),cc(2),cc(2)],[cc(3),cc(3),cc(3)],...
            mm(1,:),mm(2,:),mm(3,:),0,'color','k');
            hold off
            if ~isempty(varargin)
                set(h,varargin{:}); % set options stored in varargin
            end
        end
    end
end