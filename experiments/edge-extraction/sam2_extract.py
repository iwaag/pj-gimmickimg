# Step 1-2 of ch-0001: SAM2 box+point masks (from the old ellipse mask's components), then erode/feather + foreground colour estimation.
import numpy as np, cv2, torch, sys
from PIL import Image
from scipy import ndimage as ndi
from transformers import Sam2Processor, Sam2Model
from pymatting import estimate_foreground_ml
R='experiments/mushroom-removal/'; O='experiments/edge-extraction/'
img=Image.open(R+'present/before.png').convert('RGB'); rgb=np.array(img)
old=np.array(Image.open(R+'mask_raw.png').convert('L'))>127
lab,n=ndi.label(old); print('components',n,[int((lab==i).sum()) for i in range(1,n+1)])
dev='mps' if torch.backends.mps.is_available() else 'cpu'
proc=Sam2Processor.from_pretrained('facebook/sam2.1-hiera-large'); model=Sam2Model.from_pretrained('facebook/sam2.1-hiera-large').to(dev).eval()
sam=np.zeros(old.shape,bool)
for i in range(1,n+1):
    c=lab==i
    if c.sum()<300: continue
    ys,xs=np.where(c); box=[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())]
    # positive point = deepest interior point of the old mask; reddish-ness picks it too
    d=ndi.distance_transform_edt(c); py,px=[int(v) for v in np.unravel_index(d.argmax(),d.shape)]
    pts=[[px,py]]
    if i==1:  # top-right mushroom: old ellipse clipped it; widen box, add cap and stem points
        box=[1175,350,1310,465]; pts=[[1245,385],[1243,420],[1238,445]]
    inp=proc(images=img,input_boxes=[[box]],input_points=[[pts]],input_labels=[[[1]*len(pts)]],return_tensors='pt').to(dev)
    with torch.no_grad(): out=model(**inp,multimask_output=False)
    m=proc.post_process_masks(out.pred_masks.cpu(),inp['original_sizes'].cpu(),binarize=True)[0][0,0].numpy()>0
    print(i,box,'old',int(c.sum()),'sam',int(m.sum()))
    sam|=m
Image.fromarray((sam*255).astype(np.uint8)).save(O+'sam_mask.png')
