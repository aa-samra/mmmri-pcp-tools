# Multi-Modal MRI preprocessing toolkit

For several decades, magnetic resonance imaging (MRI) have been used to assist in neurological disease diagnosis. Deep models have reduced the need for manual feature extraction from MRI images. Recent models aim to fuse multiple modalities of MRI to increase accuracy. The most common modalities are the functional MRI (fMRI) which is  blood-oxygen level dependent (BOLD) imaging, and Diffusion-Weighted Imaging (DWI) which provides information about tissue structure and connections.
In this contexts, available datasets introduce many difficulties in preprocessing for benchmarking models, due to inconsistency, missing data and other issues.

In this repo, we aim to develop and implement docker-container with interface (API). This API includes pipelines for creation and preprocessing of fMRI, sMRI and DTI datasets. 

## Buiding docker image
this image contains FSL tools, Anaconda, and scripts for preprocessing of various modalities, to build docker image use the command in the directory you clone the repo to:
```
docker build . -t mmmri-pcp-tools
```
