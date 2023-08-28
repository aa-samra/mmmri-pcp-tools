# Multi-Modal MRI preprocessing toolkit

For several decades, magnetic resonance imaging (MRI) have been used to assist in neurological disease diagnosis. Deep models have reduced the need for manual feature extraction from MRI images. Recent models aim to fuse multiple modalities of MRI to increase accuracy. The most common modalities are the functional MRI (fMRI) which is  blood-oxygen level dependent (BOLD) imaging, and Diffusion-Weighted Imaging (DWI) which provides information about tissue structure and connections.
In this contexts, available datasets introduce many difficulties in preprocessing for benchmarking models, due to inconsistency, missing data and other issues.

In this repo, we aim to develop and implement docker-container with interface (API). This API includes pipelines for creation and preprocessing of fMRI, sMRI and DTI datasets. 

## Buiding docker image
this image contains FSL tools, Anaconda, and scripts for preprocessing of various modalities, to build docker image use the command in the directory you clone the repo to:
```
docker build . -t mmmri-pcp-tools
```

## Running the API
to run the API, use the command: 
```
docker container run \
    -it \
    --gpus=1 \
    --cpus=4 \
    --name my-mmmri-pcp \
    -v <your_data_dir>:<data_dir_in_containter>
    mmmri-pcp-tools
```
### Bonus: using Jupyter Lab on a remote server:
for ease of usage, use the same port number for all forwaring command, make sure it is available everywhere (local, remote, container), I used 9876  
* Connect to ramote on your local terminal, don't forget to forward ports:
``` ssh -L 9876:<remote_address>:9876 <username>@<remote_address> ```
* On remote terminal, run this command:
``` docker run <same opition above> -p 9876:9876 mmmri-pcp-tools ```
* On container terminal, run this:
``` jupyter lab --ip=0.0.0.0 --port=9876 --allow-root ```
