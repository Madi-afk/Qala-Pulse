from pathlib import Path
from app.seed import sample_image

target = Path(__file__).resolve().parents[1] / "sample_data/images"
target.mkdir(parents=True, exist_ok=True)
for index in range(3):
    (target / ("demo.jpg" if index == 0 else f"demo-{index+1}.jpg")).write_bytes(sample_image(index))
print("Created 3 original synthetic samples.")
