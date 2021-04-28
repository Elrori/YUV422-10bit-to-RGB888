#
#   Name    :yuv422_to_rgb python testbench
#   Origin  :210428
#   Author  :helrori2011@gmail.com
#
import numpy as np
import matplotlib.pyplot as plt
import os
def RGB2YUV( rgb ):
    '''
    input is a RGB numpy array with shape (height,width,3), can be uint,int, float or double, values expected in the range 0..255
    output is a double YUV numpy array with shape (height,width,3), values in the range 0..255

    '''
    m = np.array([[ 0.29900, -0.16874,  0.50000],
                 [0.58700, -0.33126, -0.41869],
                 [ 0.11400, 0.50000, -0.08131]])
     
    yuv = np.dot(rgb,m)
    yuv[:,:,1:]+=128.0
    return yuv.astype(np.uint8)

def YUV2RGB( yuv ):
    '''
    input is an YUV numpy array with shape (height,width,3) can be uint,int, float or double,  values expected in the range 0..255
    output is a double RGB numpy array with shape (height,width,3), values in the range 0..255

    '''
    m = np.array([[ 1.0, 1.0, 1.0],
                 [-0.000007154783816076815, -0.3441331386566162, 1.7720025777816772],
                 [ 1.4019975662231445, -0.7141380310058594 , 0.00001542569043522235] ])
    
    rgb = np.dot(yuv,m)
    rgb[:,:,0]-=179.45477266423404
    rgb[:,:,1]+=135.45870971679688
    rgb[:,:,2]-=226.8183044444304
    
    return rgb.astype(np.uint8)

def main():
    # img_recover=YUV2RGB(img_yuv)

    # Make the YUV file for verilog module
    img = plt.imread('1.jpg')
    img_yuv=RGB2YUV(img)
    fy=open("./yuv_source/y.txt",'w+')
    fu=open("./yuv_source/u.txt",'w+')
    fv=open("./yuv_source/v.txt",'w+')
    for x in range(img.shape[0]):
        for y in range(img.shape[1]):
            fy.write(hex(img_yuv[x,y,0])[2:]+'\n')
            fu.write(hex(img_yuv[x,y,1])[2:]+'\n')
            fv.write(hex(img_yuv[x,y,2])[2:]+'\n')
    fy.close()
    fu.close()
    fv.close()
    
    os.system('iverilog -y. -y.. -o tb_yuv422_to_rgb.vvp tb_yuv422_to_rgb.v');
    os.system('vvp tb_yuv422_to_rgb.vvp');

    # Read the  RGB data from verilog model output
    fr=open("./rgb_recover/r.txt",'r+')
    fg=open("./rgb_recover/g.txt",'r+')
    fb=open("./rgb_recover/b.txt",'r+')
    rgb=np.empty((img.shape[0],img.shape[1],img.shape[2]),dtype=np.uint8)
    for x in range(img.shape[0]):
        for y in range(img.shape[1]):
            liner=fr.readline()
            lineg=fg.readline()
            lineb=fb.readline()
            rgb[x,y,0]=int(liner[:-1],16)
            rgb[x,y,1]=int(lineg[:-1],16)
            rgb[x,y,2]=int(lineb[:-1],16)
    plt.imshow(rgb)
    plt.title('Recovered image')
    plt.show()
    fr.close()
    fg.close()
    fb.close()

    os.system('gtkwave wave.gtkw');
    os.system('del rgb_recover\\*.txt');
    os.system('del yuv_source\\*.txt');
    os.system('del wave.vcd');
    os.system('del tb_yuv422_to_rgb.vvp');
if __name__ == "__main__":
    main()
