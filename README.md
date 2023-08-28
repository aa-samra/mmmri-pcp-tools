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
```
ssh -L 9876:<remote_address>:9876 <username>@<remote_address>
 ```
* On remote terminal, run this command:
```
docker run <same opition above> -p 9876:9876 mmmri-pcp-tools
```
* On container terminal, run this:
```
jupyter lab --ip=0.0.0.0 --port=9876 --allow-root
```
## Usage
### DWI preprocessing pipeline:
We expect you to have your data in the BIDS format where each subject has at least one session that contains a DWI scan. To use this tool, run the command:
```
./code/process_dwi.sh <input_bids_dir> <output_dir> <number_of_parallel_processes>
```
all argument are required.
### the output format:
```
___out_dir___sub-1____data.nii.gz
            |       |_data_ec.nii.gz
            |       |_.....
            |       |_standard_scalars____DTI_FA.nii.gz
            |                            |_DTI_V1.nii.gz
            |                            |_DTI_V2.nii.gz
            |                            |_DTI_V3.nii.gz
            |_sub-2____data.nii.gz
                    |_data_ec.nii.gz
                    |_.....
                    |_standard_scalars____DTI_FA.nii.gz
                                        |_DTI_V1.nii.gz
                                        |_DTI_V2.nii.gz
                                        |_DTI_V3.nii.gz

```

### FMRI and T1-weighted preprocessing pipeline:
We expect you to have your data in the BIDS format where each subject has at least one session that contains a DWI scan. To use this tool, run the command:
```
./code/process_fmri.sh <input_bids_dir> <output_dir> <number_of_parallel_processes>
```
all argument are required.
### the output format:
```
___out_dir___sub-1____T1w.nii.gz
            |       |_prefiltered_func_data.nii.gz
            |       |_.....
            |       |_filtered_func_data2standard.nii.gz
            |       
            |_sub-2___T1w.nii.gz
                    |_prefiltered_func_data.nii.gz
                    |_.....
                    |_filtered_func_data2standard.nii.gz

```
