import numpy as np, cv2
from PIL import Image
from pymatting import estimate_foreground_ml
R='experiments/mushroom-removal/'; O='experiments/edge-extraction/'
rgb=np.array(Image.open(R+'present/before.png').convert('RGB')).astype(np.float64)/255
def alpha_from(mask,erode=1,feather=1.0):
    m=(mask>127).astype(np.uint8)
    if erode: m=cv2.erode(m,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(2*erode+1,)*2))
    return np.clip(cv2.GaussianBlur(m.astype(np.float32),(0,0),feather),0,1).astype(np.float64)
def cutout(a):
    fg=estimate_foreground_ml(rgb,a); return fg,a
def comp(fg,a,bg):
    b=np.zeros_like(rgb); b[:]=np.array(bg)/255
    return (np.clip(fg,0,1)*a[...,None]+b*(1-a[...,None]))
def save(x,p): Image.fromarray((np.clip(x,0,1)*255).astype(np.uint8)).save(p)
if __name__=='__main__':
    old=np.array(Image.open(R+'mask_raw.png').convert('L')); sam=np.array(Image.open(O+'sam_mask.png'))
    box=(740,340,1330,640)
    rows=[]
    for name,a in [('before_ellipse',alpha_from(old,0,1.0)),('after_sam_e1f1',alpha_from(sam,1,1.0))]:
        fg,a=cutout(a)
        save(np.dstack([fg,a])[...,:3] if False else comp(fg,a,(255,0,255)),O+f'{name}_magenta.png')
        rows.append(np.hstack([comp(fg,a,bg)[box[1]:box[3],box[0]:box[2]] for bg in [(255,0,255),(255,255,255),(0,0,0)]]))
        rgba=np.dstack([np.clip(fg,0,1),a]); Image.fromarray((rgba*255).astype(np.uint8)).save(O+f'{name}_rgba.png')
    save(np.vstack(rows),O+'compare_ellipse_vs_sam.png')
