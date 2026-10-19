# Privacy detector fixtures

`astronaut.png`: NASA portrait of astronaut Eileen Collins, obtained from the
[scikit-image v0.25.2 data collection](https://github.com/scikit-image/scikit-image/blob/v0.25.2/skimage/data/astronaut.png).
[scikit-image documents the image as public domain](https://scikit-image.org/docs/stable/api/skimage.data.html#skimage.data.astronaut).
Used only as a face-detector test fixture; no endorsement or identity-recognition claim.

Street and plate scenes in `tests/privacy_samples.py` are drawn by this project
and covered by its MIT license. The plate text is invented test data, not a real
vehicle record. These tests do not measure recall on real Kazakhstan traffic.

Expected portrait face box (before detector padding): approximately x=175,
y=60, width=105, height=115 in the 512×512 image. Synthetic plate rectangle:
x=615, y=286, width=253, height=66 in the 960×640 street scene.
