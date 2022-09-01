from setuptools import setup, find_packages

setup(name='DLAC',
    version='1.1',
    description='Deep learning anti-cheat for CSGO',
    author='LaihoE',
    packages=find_packages(),

    install_requires=[
    "numpy==1.21.5",
    "onnxruntime",
    "pandas==1.3.5",
    "scikit-learn==1.0.1"
    ],
     )
