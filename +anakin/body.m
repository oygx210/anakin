%{
DESCRIPTION:
body: class to model a rigid body. Subclass of frame.

SYNTAX:
b = anakin.body();  % returns default object  
b = anakin.body(...,<S1>); 
where:
- <> denotes optional arguments
- b is a body
- ... denotes a list of one or more of the following. Later inputs can
  overwrite previous inputs: 
    - body object
    - particle object: denotes the mass and center of mass
    - point object: denotes the center of mass
    - scalar (0th-order tensor): mass
    - scalar numeric or symbolic value: mass
    - vector (1st-order tensor): denotes the center of mass
    - one dimensional array: denotes the center of mass
    - A second order tensor: denotes the tensor of inertia about G in the
      canonical vector basis
    - A square matrix: denotes the tensor of inertia about G in the
      canonical vector basis 
    - basis: denotes the body-fixed basis
    - triangulation object: for plotting purposes
- S1 is a frame. If given, all previous inputs are relative to that frame
 
PROPERTIES
* mass: mass of the rigid body
* IG: tensor of inertia about the center of mass in the canonical vector
  basis
* triangulation: triangulation object with the body geometry, used for
  plotting. 

METHODS: 
* p: linear momentum in a given reference frame
* H: angular momentum about a point in a given reference frame
* T: kinetic energy in a given reference frame
* equations: returns a vector of (symbolic) equations, m*a = F, dH/dt = M,
  projected along the vectors of one basis 
* I: tensor of inertia about a point
* subs: takes values of the symbolic unknowns and returns a particle
  object which is purely numeric
* force_equation: returns the force equation projected along a desired
  direction. Requires symbolic particle 
* torque_equation: returns the torque equation about a point, projected
  along a desired direction. Requires symbolic particle

STATIC METHODS:
* box, cylinder, sphere, cone: convenience methods for quick body creation

To add: instantaneous axis of rotation and slip, slip velocity, velocity of
a point, acceleration of a point, add inertia tensor given at a point,
facilities to add forces at a point, torques, visualize them, frame
AUTHOR: 
Mario Merino <mario.merino@uc3m.es>
%}
classdef body < anakin.frame
    properties
        mass anakin.tensor = anakin.tensor(1); % mass of the object        
        IG anakin.tensor = anakin.tensor([1,0,0;0,1,0;0,0,1]); % tensor of inertia of the body at the center of mass in the canonical vector basis 
    end
    properties (Hidden = true) 
        triangulation triangulation = anakin.triangulations.box; % Triangulation of the rigid body geometry with external pointing normals
    end 
    methods % creation b  = anakin.body(<b|<<mass>,inertia>,S|(<A>,<B>)>,<S1>);
        function b = body(varargin) % constructor
            if isempty(varargin) % Default body
                return;
            elseif length(varargin) > 1 && isa(varargin{end},'anakin.frame') % Last argin is frame
                S1 = varargin{end};
                varargin = varargin(1:end-1); 
            else % No frame is provided; use default
                S1 = anakin.frame;
            end 
            b.r = S1.r;
            b.m = S1.m;
            for i = 1:length(varargin) % later inputs overwrite former inputs
                temp = varargin{i};
                if isa(temp,'anakin.body')
                    b.mass = temp.mass;
                    b.IG = anakin.tensor(temp.IG,S1);
                    b.r = anakin.tensor(S1.r.components + S1.m * temp.r.components);
                    b.m = temp.matrix(S1);
                    b.triangulation = temp.triangulation;
                elseif isa(temp,'anakin.particle')
                    b.mass = temp.mass;
                    b.r = anakin.tensor(S1.r.components + S1.m * temp.r.components);
                elseif isa(temp,'anakin.frame')
                    b.r = anakin.tensor(S1.r.components + S1.m * temp.r.components);
                    b.m = temp.matrix(S1);
                elseif isa(temp,'anakin.point')
                    b.r = anakin.tensor(S1.r.components + S1.m * temp.r.components); 
                elseif isa(temp,'anakin.basis')
                    b.m = temp.matrix(S1);
                elseif isa(temp,'anakin.tensor')
                    if temp.ndims == 0 % assume it is mass
                        b.mass = temp;
                    elseif temp.ndims == 1 % assume it is r
                        b.r = anakin.tensor(S1.r.components + S1.m * temp.components);
                    elseif temp.ndims == 2 % assume it is IG
                        b.IG = anakin.tensor(temp.components,S1);
                    else
                        error('Cannot take tensors of order higher than 2 as inputs');
                    end
                elseif isa(temp,'triangulation')
                    b.triangulation = temp; 
                else % Array 
                    v_ = anakin.tensor(temp);
                    if v_.ndims == 0 % assume it is mass
                        b.mass = v_;
                    elseif v_.ndims == 1 % assume it is r
                        b.r = anakin.tensor(S1.r.components + S1.m * v_.components);
                    elseif v_.ndims == 2 % assume it is IG
                        b.IG = anakin.tensor(v_.components,S1);
                    else
                        error('Cannot take arrays of order higher than 2 as inputs');
                    end 
                end
            end 
        end
        function b = set.mass(b,value) % on setting mass
            b.mass = anakin.tensor(value);  
            if b.mass.ndims ~= 0
                error('Mass must be a scalar');
            end
        end 
        function b = set.IG(b,value) % on setting IG
            b.IG = anakin.tensor(value); 
            if b.IG.ndims ~= 2
                error('Inertia tensor must be given as a matrix');
            end
        end
    end
    methods (Hidden = true) % overloads
        function value = eq(b1,b2) % overload ==. Compares only r, mass, IG.  
            IG1 = b1.IG;
            IG2 = b2.IG; 
            value = (b1.mass == b2.mass) && (IG1 == IG2) && (b1.r == b2.r);
        end
        function value = ne(b1,b2) % overload =~
            value = ~eq(b1,b2);
        end
        function disp(b) % display
            disp('Rigid body with mass:')
            disp(b.mass.components)      
            disp('Inertia tensor at the center of mass in body basis:')
            I = b.IG.components(b);
            try
                I = double(I);
            catch
                % pass
            end
            disp(I)
            disp('Coordinates of the center of mass:')
            disp(b.r.components)            
            disp('And basis with rotation matrix:')
            disp(b.m)                
        end
    end
    methods (Static = true) % convenience body creation methods
        function b = sphere(mass,O,B,R,varargin) % New sphere
            b = anakin.body;
            if exist('mass','var')
                b.mass = mass;
            end
            if exist('O','var')
                b.r = anakin.tensor(O);
            end
            if exist('B','var')
                b.m = anakin.basis(B).matrix;
            end 
            if ~exist('R','var')
                R = 1;
            end 
            b.IG = anakin.tensor(eye(3)*2*b.mass*R^2/5,b); 
            b.triangulation = anakin.triangulations.sphere(R,varargin{:});
        end  
        function b = box(mass,O,B,Lx,Ly,Lz,varargin) % New parallelepiped
            b = anakin.body;
            if exist('mass','var')
                b.mass = mass;
            end
            if exist('O','var')
                b.r = anakin.tensor(O);
            end
            if exist('B','var')
                b.m = anakin.basis(B).matrix;
            end 
            if ~exist('Lx','var')
                Lx = 1;
            end
            if ~exist('Ly','var')
                Ly = 1;
            end
            if ~exist('Lz','var')
                Lz = 1;
            end
            b.IG = anakin.tensor(b.mass/12*[Ly^2+Lz^2,0,0;0,Lx^2+Lz^2,0;0,0,Lx^2+Ly^2],b);  
            b.triangulation = anakin.triangulations.box(Lx,Ly,Lz,varargin{:}); 
        end  
        function b = cylinder(mass,O,B,R,Lz,varargin) % New cylinder along Z axis
            b = anakin.body;
            if exist('mass','var')
                b.mass = mass;
            end
            if exist('O','var')
                b.r = anakin.tensor(O);
            end
            if exist('B','var')
                b.m = anakin.basis(B).matrix;
            end 
            if ~exist('R','var')
                R = 1;
            end
            if ~exist('Lz','var')
                Lz = 1;
            end 
            b.IG = anakin.tensor(b.mass/12*[3*R^2+Lz^2,0,0;0,3*R^2+Lz^2,0;0,0,6*R^2],b); 
            b.triangulation = anakin.triangulations.prism(R,Lz,varargin{:});
        end  
        function b = cone(mass,O,B,R,Lz,varargin) % New cone along Z axis
            b = anakin.body;
            if exist('mass','var')
                b.mass = mass;
            end
            if exist('O','var')
                b.r = anakin.tensor(O);
            end
            if exist('B','var')
                b.m = anakin.basis(B).matrix;
            end 
            if ~exist('R','var')
                R = 1;
            end
            if ~exist('Lz','var')
                Lz = 1;
            end  
            b.IG = anakin.tensor(3*b.mass/20*[R^2+Lz^2/4,0,0;0,R^2+Lz^2/4,0;0,0,2*R^2],b); 
            b.triangulation = anakin.triangulations.pyramid(R,Lz,varargin{:});
        end  
    end
    methods % general functionality    
        function p = p(b,S1) % linear momentum in S1
            if exist('S1','var')
                p = b.mass*b.vel(S1);
            else
                p = b.mass*b.vel;
            end            
        end
        function H = H(b,O,S1) % angular momentum about O in S1
            if ~exist('O','var')
                O = anakin.point; % default point
            end
            if ~exist('S1','var')
                S1 = anakin.frame; % default frame
            end  
            H = cross(b.pos-O.pos, b.p(S1)) + b.IG * b.omega(S1); 
        end
        function T = T(b,S1) % kinetic energy in S1
            if ~exist('S1','var')
                S1 = anakin.frame; % default frame
            end  
            vel = b.vel(S1);
            omega = b.omega(S1);
            T = b.mass * norm(vel)^2 / 2 + omega * b.IG * omega / 2; 
        end 
        function I = I(b,O) % inertia tensor of the body with respect to point O in canonical vector basis
            if ~exist('O','var')
                O = anakin.point; % default point is the origin
            end
            r = b.r - O.r;
            I = b.IG + b.mass * (norm(r)^2 * eye(3) - product(r,r)); 
        end
        function b_ = subs(b,variables,values) % particularize symbolic body
            b_ = b;
            b_.mass = b.mass.subs(variables,values);
            b_.IG = b.IG.subs(variables,values);
            b_.r = b.r.subs(variables,values); 
            b_.m = subs(b.m,variables,values);
            try
                b_.m = double(b_.m);
            catch
                % pass
            end
        end
        function h = plotbody(b,varargin) % Plots body surface
            % Translate and rotate surface object
            P = b.triangulation.Points;
            X = P(:,1);
            Y = P(:,2);
            Z = P(:,3);
            for i = 1:length(X(:))
                temp = b.coordinates + b.matrix * [X(i);Y(i);Z(i)];
                X(i) = temp(1);
                Y(i) = temp(2);
                Z(i) = temp(3);
            end
            C = b.triangulation.ConnectivityList;
            n = length(C(:,1));
            h(n) = 0; % Allocate
            for j = 1:n
                h(j) = patch(X(C(j,:)),Y(C(j,:)),Z(C(j,:)),'b');
                for iv = 1:2:length(varargin)
                    try
                        set(h(j),varargin{iv:iv+1});
                    catch
                        % pass
                    end
                end
            end 
        end
    end      
    methods % dynamics
        function eq = force_equation(b,F,e,S) % force equation along direction e, assuming S is inertial. Requires symbolic body
            if ~exist('S','var')
                S = anakin.frame; % default to canonical frame
            end
            lhs = b.p(S).dt(S)*e;
            rhs = F*e; 
            eq = sym(lhs.components - rhs.components); % expression equal to zero is the equation
        end  
        function eq = torque_equation(b,A,MA,e,S) % force equation along direction e, assuming S is inertial. Requires symbolic body
            if ~exist('S','var')
                S = anakin.frame; % default to canonical frame
            end
            lhs = b.H(A,S).dt(S)*e;
            rhs = (MA - cross(A.vel,b.p(S)))*e; 
            eq = sym(lhs.components - rhs.components); % expression equal to zero is the equation
        end  
        function eqs = equations(b,F,A,MA,S) % The six equations for 3d bodies, assuming S is inertial. Requires symbolic body
            if b.spacedim ~= 3
                error('This functionality is only available for bodies in 3D space');
            end
            if ~exist('S','var')
                S = anakin.frame; % default to canonical frame
            end
            eqs(6,1) = sym(0); % allocate
            p = b.p(S);
            dp = p.dt(S);            
            dH = b.H(A,S).dt(S);
            c = cross(A.vel,p);
            for i = 1:3
                eqs(i) = sym(dp.x(i,S) - F.x(i,S)); 
                eqs(3+i) = sym(dH.x(i,S) + c.x(i,S) - MA.x(i,S));
            end 
        end
    end
end




