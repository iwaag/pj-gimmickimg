import sys, numpy as np, torch
from PIL import Image
from transformers import pipeline
src,out=sys.argv[1],sys.argv[2]
dev="mps" if torch.backends.mps.is_available() else "cpu"
p=pipeline("depth-estimation",model="depth-anything/Depth-Anything-V2-Large-hf",device=dev)
img=Image.open(src).convert("RGB")
d=p(img)["predicted_depth"].squeeze().float().cpu().numpy()
d=np.array(Image.fromarray(d).resize(img.size,Image.BICUBIC))
d=(d-d.min())/(d.max()-d.min())
Image.fromarray((d*65535).astype(np.uint16)).save(out+"/depth.png")
Image.fromarray((d*255).astype(np.uint8)).save(out+"/depth_preview.png")
print(np.percentile(d,[10,25,50,75,90]))
