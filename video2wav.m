%% 读取视频
path = 'D:\Onedrive\Project\badAppleOscilloscope'; % 设置工作文件夹
rawVideo = VideoReader([path,'\badApple.mp4']); % 读取原视频
% 设置压缩后的文件信息
videoWriter = VideoWriter([rawVideo.Path,'\badApple_Compressed'],'Uncompressed AVI'); % 创建一个VideoWriter用于写入视频
videoWriter.FrameRate = rawVideo.FrameRate; % 设置新视频的帧率与原视频一样
open(videoWriter); % 打开写入视频通道
%设置压缩后视频的长宽
if rawVideo.Height >= rawVideo.Width
    height = 256;
    width = round(rawVideo.Width / rawVideo.Height * heigth);
else
    width = 256;
    height = round(rawVideo.Height / rawVideo.Width * width);
end
%%
for i = 1: rawVideo.NumFrames % 遍历原视频每一帧
    frame = read(rawVideo, i); % 读取原视频第i帧
    newFrame = imresize(frame, [height width]); % 将新的帧压缩
    writeVideo(videoWriter, newFrame); % 写入压缩后的帧到新视频
    i / rawVideo.NumFrames
end
close(videoWriter); % 写完后关闭写入通道
%% 读取压缩后的视频文件并把视频分解为bmp并写入文件夹
compressedVideo = VideoReader([path, '\', videoWriter.Filename]); % 读取压缩后的视频
for i = 1: compressedVideo.NumFrames 
    frame = read(compressedVideo, i); 
    imwrite(frame,[path, '\bmp\', num2str(i), '.bmp']); % 作为为bmp文件写入\bmp\文件夹
    i / rawVideo.NumFrames
end
%% 找出轮廓并记录
for i = 1: compressedVideo.NumFrames %遍历所有帧
    str = [path,'\bmp\',num2str(i),'.bmp']; %读取所有bmp文件
    gray = rgb2gray(imread(str)); % 将彩色转为黑白
    pic = edge(gray,'canny'); % 获取边缘
    [y,x] = find(pic == 1); % 得到边缘点的坐标
    edgeArray{i} = [x, compressedVideo.height - y]; % 记录在edgeLoc数组
    i / rawVideo.NumFrames
end
%% 按轮廓排序
for i = 1: compressedVideo.NumFrames
   [len,wid] = size(edgeArray{i}); % 得到数组的大小
   if len > 2 % 如果小于等于两个数据点，就没必要排序了
       for j = 1: len - 1 
           temp = 100000; % 设置临时变量
           % 对于未排序的所有点，
           for k = j + 1: len
               if ((edgeArray{i}(k,2) - edgeArray{i}(j,2))^2 + (edgeArray{i}(k,1) - edgeArray{i}(j,1))^2) < temp % 如果距离小于临时变量
                   temp = (edgeArray{i}(k,2) - edgeArray{i}(j,2))^2 + (edgeArray{i}(k,1) - edgeArray{i}(j,1))^2; % 把临时变量更新为新的
                   tempLoc = k; % 记录下临时变量的所在行
               end
           end
           % 交换当前行的下一行与最小值所在行
           temp1 = edgeArray{i}(tempLoc, 1);
           temp2 = edgeArray{i}(tempLoc, 2);
           edgeArray{i}(tempLoc, 1) = edgeArray{i}(j + 1, 1);
           edgeArray{i}(tempLoc, 2) = edgeArray{i}(j + 1, 2);
           edgeArray{i}(j + 1, 1) = temp1;
           edgeArray{i}(j + 1, 2) = temp2;
           clear temp1; clear temp2;
       end
   end
   i / rawVideo.NumFrames
end
%% 播放 可以先用Maltab 的plot函数播放看看效果 （这步可以省略）
for i = 1: compressedVideo.NumFrames 
    min = fix(i / compressedVideo.FrameRate / 60);
    sec = mod(fix(i / compressedVideo.FrameRate), 60);
    fra = fix(mod(i, compressedVideo.FrameRate));
    time = ['', num2str(min), ':', num2str(sec,'%02d'), '.', num2str(fra,'%02d'),' / 3:39']
    plot(edgeArray{i}(:, 1), edgeArray{i}(:, 2), '.');
    axis equal;
    axis([0 compressedVideo.Width 0 compressedVideo.Height]);
    set(gca, 'xtick', [0 : compressedVideo.Width / 4 : compressedVideo.Width]);
    set(gca, 'ytick', [0 : compressedVideo.Height / 4 : compressedVideo.Height]);
    pause(0.01);
end
%% 设置wav头文件
samplingRate = 88200; % 音频采样率
soundChannel = 2; % 左右声道对应示波器的 Channel 1 和 Channel 2
bitsPerSample = 8; % 每个采样的位数，8位能表示 256 个梯度就足够了
sampPerFrame = round(samplingRate / compressedVideo.FrameRate); % 每帧的采样数
frameRateWav = samplingRate / sampPerFrame; % 实际在示波器上播放的帧数
dataSize = compressedVideo.NumFrames * sampPerFrame * 2;
fileSize = dataSize + 36; % 生成的wav文件的大小-8，为数据大小加上wav的数据头 44 byte - 'R''I''F''F'(4 byte) - fileSize(4 byte) 
byteRate = samplingRate * 2; % 采样率 * 2声道
blockAlign = soundChannel * bitsPerSample / 8; % 每个采样字节数 2 * 8 / 8 = 2

%format = [ R  I  F  F/  fileSize / W  A  V  E   f   m   t   /Subchunk1Size/AudioFormat/soundChannels/samplingRate/bytePerSec/blockAlign/bitsPerSample/ d  a   t  a/  dataSize
%HEX    = [52 49 46 46  -  -  -  - 57 41 56 45  66  6D  74 20/ 10 00 00 00     01 00       -  -        -  -  -  -  -  -  -  -/   -  -        -  -      64 61  74 61  -  -  -  -];
data    = [82;73;70;70; 0; 0; 0; 0;87;65;86;69;102;109;116;32; 16; 0; 0; 0;    1; 0;       0; 0;       0; 0; 0; 0; 0; 0; 0; 0;   2; 0;       8; 0;    100;97;116;97; 0; 0; 0; 0];
data(5) = mod(fileSize, 256);
data(6) = fix(mod(fileSize, 65536) / 256);
data(7) = fix(mod(fileSize, 16777216) / 65536);
data(8) = fix(samplingRate / 16777216);
data(23) = mod(soundChannel, 256);
data(24) = fix(soundChannel / 256);
data(25) = mod(samplingRate, 256);
data(26) = fix(mod(samplingRate, 65536) / 256);
data(27) = fix(mod(samplingRate, 16777216) / 65536);
data(28) = fix(samplingRate / 16777216);
data(29) = mod(byteRate, 256);
data(30) = fix(mod(byteRate, 65536) / 256);
data(31) = fix(mod(byteRate, 16777216) / 65536);
data(32) = fix(byteRate / 16777216);
data(33) = mod(blockAlign, 256);
data(34) = fix(blockAlign / 256);
data(35) = mod(bitsPerSample, 256);
data(36) = fix(mod(bitsPerSample, 65536) / 256);
data(41) = mod(dataSize,256);
data(42) = fix(mod(dataSize,65536) / 256);
data(43) = fix(mod(dataSize,16777216) / 65536);
data(44) = fix(dataSize / 16777216);

%% 设置wav数据文件
data = [data; zeros(dataSize,1)]; % 生成dataSize大小的数组加到文件头后面
for i = 1: compressedVideo.NumFrames
    [len,wid] = size(edgeArray{i}); % 获取每帧轮廓点的个数
    if (len > 0)
        for j = 1: sampPerFrame % 均匀映射到该帧的文件位置上
            data(44+(i-1)*2*sampPerFrame+j*2-1) = edgeArray{i}(fix((j - 1) * len / sampPerFrame) + 1, 1); % 左声道
            data(44+(i-1)*2*sampPerFrame+j*2) = edgeArray{i}(fix((j - 1) * len / sampPerFrame) + 1, 2);   % 右声道
        end
    end
end
%% 写入文件
fid = fopen([path,'\badApple.wav'],'w');
fwrite(fid,data,'uint8','n');
fclose(fid);