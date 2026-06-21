import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader
import numpy as np


#load mnist
transform = transforms.Compose(
    [transforms.ToTensor(),
     transforms.Normalize((0.1307,), (0.3081,))
])  #mean and avg

train_data = datasets.MNIST('./data', train=True, download=True, transform=transform)
test_data = datasets.MNIST('./data', train=False, download=True, transform=transform)

train_loader = DataLoader(train_data, batch_size=64, shuffle=True)
test_loader = DataLoader(test_data, batch_size=1000)

#define model; single linear layer w/ 784 input pixels to 10 output classes
model = nn.Linear(784, 10)

#train
optimizer = optim.SGD(model.parameters(), lr=0.01)
loss_fn = nn.CrossEntropyLoss()

print("training!")
for epoch in range(5):
    model.train()
    for images, labels in train_loader:
        images = images.view(-1, 784) #flattens 28x28 to 784
        optimizer.zero_grad()
        loss = loss_fn(model(images), labels)
        loss.backward()
        optimizer.step()


    #check for accuracy
    model.eval()
    correct = 0
    with torch.no_grad():
        for images, labels in test_loader:
            images = images.view(-1, 784)
            preds = model(images).argmax(dim=1)
            correct += (preds == labels).sum().item()
    print(f"epoch {epoch+1}: accuracy = {correct/100:.1f}%")

#quantize 32 bit decimal weights to 8 bit integers
weights = model.weight.detach().numpy() #shape (10,784)
bias = model.bias.detach().numpy() # shape (10,)
w_max = np.abs(weights).max() # min max scaling
scale = w_max / 127.0 #maps [-w_max, w_max] to [-127, 127]

weights_int8 = np.clip(np.round(weights/scale), -128, 127).astype(np.int8)
print(f"\nquantization scale factor: {scale:.6f}")
print(f"weight range before: [{weights.min():.4f}, {weights.max():.4f}]")
print(f"weight range after:  [{weights_int8.min()}, {weights_int8.max()}]")


#export one row as a .mem file for fpga
#run one output neuron row 0 in fpga hardware
#row 0 is weights for digit class 0

row = 2  #since test image is a "2"
w_row = weights_int8[row, :4].view(np.int8)  #first 4 weights of row 0 for 4x4 hardware

print(f"raw int8 values (signed): {w_row}") #quantized weights
print(f"raw int8 dtype: {w_row.dtype}")

print(f"\nfirst 4 int8 weights for class {row}: {w_row}")  #quantized weights for class 0

#write as hex .mem file for $readmemh
with open("docs/weights.mem", "w") as f:
    for w in w_row:
        w_int = int(w) 
        # convert signed int8 to unsigned hex
        f.write(f"{w_int & 0xFF:02x}\n")

print("saved docs/weights.mem")

#save scale factor for verification
np.save("docs/scale_factor.npy", scale)
np.save("docs/weights_int8.npy", weights_int8)
np.save("docs/bias.npy", bias)
print("saved quantization data to docs/")

#one real test image and quantize it 
sample_image, sample_label = test_data[1]
sample_flat = sample_image.view(-1).numpy()
img_2d = sample_flat.reshape(28, 28)

print(f"label: {sample_label}")
print(f"center 4x4 block of raw normalized values:")
print(img_2d[12:16, 12:16])
print(f"Min: {sample_flat.min():.3f}, Max: {sample_flat.max():.3f}")
center_block = img_2d[13:15, 13:15].flatten()  # 4 pixels from the very center

img_scale = np.abs(center_block).max() / 127.0 if np.abs(center_block).max() > 0 else 1.0
sample_int8 = np.clip(np.round(center_block / img_scale), -128, 127).astype(np.int8)

print(f"\nsample image label: {sample_label}")
print(f"center 4 pixel values (int8): {sample_int8}") #quantized weights for the actual digit 2

with open("docs/vector.mem", "w") as f:
    for v in sample_int8:
        v_int = int(v)
        f.write(f"{v_int & 0xFF:02x}\n")

print("saved docs/vector.mem")

expected_result = int(np.dot(w_row.astype(np.int32), sample_int8.astype(np.int32)))
print(f"\nexpected dot product (row 0 · sample image): {expected_result}")
