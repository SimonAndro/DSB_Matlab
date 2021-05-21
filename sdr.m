clear 
%% 发射机
N = 1200;
n1 = 1:N;
fs1 = 150000;
t = N / fs1*1000;%ms
w1 = 2000/fs1*2*pi;
w2 = 3000/fs1*2*pi;
fn = sin(w1*n1) + sin(w2*n1);
subplot(221);
plot(n1,fn)
xlabel('n');ylabel('f(n)')
title('基带信号(fs=150K)');


fs2 =15000000;
N2 = fs2/fs1*N;
n2 = 1:N2;
fc = 208001*4;
wc = fc/fs2*2*pi;
cn = cos(wc*n2); 
subplot(222);
plot(n1,cn(1:N))
xlabel('n');ylabel('C(n)')
title('载波信号(fs=15M)');



%%%%%%%%%%%%%%%%%%%%%%%%%%
%插0值
%I =100倍 使得采样率升高 I = 100 = 2 * 2 *25
%内插2倍 fs=300k
fn1 = interp_zero(fn,2);
%fir
fir = load('fir.fcf');
fn1 = filter(fir,1,fn1);

%内插2倍 fs = 600k
fn2=interp_zero(fn1,2);
%hb
hb=load('hb.fcf');
fn2=filter(hb,1,fn2);

%内插25倍 fs = 15M;
%cic
dd  = 1;     % Differential delay.
fp  = 3e3;    % Passband of interest.
ast = 60;    % Minimum attenuation of alias components in passband.
fs  = 600e3;   % Sampling frequency for input signal.
l   = 25;    % Interpolation factor.
d   = fdesign.interpolator(l,'cic',dd,'fp,ast',fp,ast,l*fs);
Hcic = design(d);
fn3 = filter (Hcic ,fn2);
fn3 = double(fn3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%线性内插
% fn3=interp(fn,100);

%DSB 调制 I 路为f（n），Q路为0 (fs = 15M)
I = fn3;
Q = zeros(1,N*100);
theta = pi/6;
nco1_cos = cos(wc*n2+theta); 
nco1_sin = sin(wc*n2+theta) ;
xn = I .* nco1_cos + Q .* nco1_sin;
subplot(223);
plot(n2,xn)
xlabel('n');ylabel('X(n)')
title('已调信号(fs=15M)');

%发射DAC频谱
XN = fft(xn);
subplot(224);
w = n2(1:N2)/(N*100)*2;
Xw = abs(XN(1:N2));
plot(w ,Xw )
xlabel('w/pi');ylabel('abs（X(w)）')
title('已调信号频谱');


%对dac数据插值模拟模拟射频信号
%线性内插
 xt=interp(xn,100);

%% 接收机
%整频带采样
m = 1:200;
b = fc ./(m+1/2);

M = 41;
%B = 2.004828915662651e+04; %整频带带宽
B = 20048; %取整
fs3 = 2*B; %高效结构

Tn = 100*fs2/fs3; %对发射机信号采样 等效为接收端天线ad采样

Ny = 300;
ny = 1:Ny;
%采样
yn = zeros(1,Ny);
for j = 1:Ny
    yn(j) = xt(round(Tn*j));
end
figure(2)
subplot(221);
plot(ny,yn )
xlabel('n');ylabel('yn')
title('带通采样信号');

YN = fft(yn);
subplot(222);
w = ny ./Ny*2;
Yw = abs(YN);
plot( w ,Yw )
xlabel('w/pi');ylabel('abs（Y(w)）')
title('带通采样后频谱');


nco2_cos = round(cos(pi/2*ny));
nco2_sin = round(-sin(pi/2*ny));


 I = yn .* nco2_cos ;
 Q = yn .* nco2_sin ;


fir2 = load('fir2.fcf');
zBI = filter(fir2,1,I );
zBQ = filter(fir2,1,Q );
figure(3)
subplot(221);
plot(ny,zBI )
xlabel('n');ylabel('ZBI')
title('ZBI信号');
ZBI= fft(zBI);
subplot(222);
w = ny ./Ny*2;
ZBIw = abs(ZBI);
plot( w ,ZBIw )
xlabel('w/pi');ylabel('abs（X(w)）')
title('ZBI频谱');

subplot(223);
plot(ny,zBQ )
xlabel('n');ylabel('ZBQ')
title('ZBQ信号');
ZBQ= fft(zBQ);
subplot(224);
w = ny ./Ny*2;
ZBQw = abs(ZBQ);
plot( w ,ZBQw )
xlabel('w/pi');ylabel('abs（X(w)）')
title('ZBQ频谱');
%平方和开方算法
figure(2)
An = sqrt(zBI .* zBI+ zBQ .* zBQ);
subplot(223);
plot(ny,An )
xlabel('n');ylabel('An')
title('平方和开方解调输出信号');

%相位估计再补偿算法
delta_theta = -atan(zBQ/zBI);
ZBI_1 = cos(delta_theta).*zBI - sin(delta_theta).*zBQ;
ZBQ_1 = sin(delta_theta).*zBI + cos(delta_theta).*zBQ;

An = ZBI_1;
subplot(224);
plot(ny,An )
xlabel('n');ylabel('An')
title('相位估计再补偿解调输出信号');

