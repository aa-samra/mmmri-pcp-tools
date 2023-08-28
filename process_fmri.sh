fmri_dirs=()
for dir in /data/DL_subset/fmri/sub-*; do
    fmri_dirs+=("$dir")
done


process_fmri_(){
    dir=$1
    
    bet $dir/T1w $dir/T1w_brain -m -f 0.5 -R

    fslmaths $dir/fMRI $dir/prefiltered_func_data -odt float

    cp $dir/prefiltered_func_data.nii.gz $dir/example_func.nii.gz
    
    # mkdir -p $dir/feat
    # mainfeatreg -F 6.00 -d $dir/feat -i $dir/fMRI -h $dir -w  7 -x 90
    # mkdir -p $dir/feat/reg
    
    fslmaths $dir/T1w_brain $dir/highres
    fslmaths $dir/T1w $dir/highres_head
   

    fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm_brain $dir/standard
    fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm $dir/standard_head
    fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil $dir/standard_mask

    epi_reg --epi=$dir/example_func --t1=$dir/highres_head --t1brain=$dir/highres --out=$dir/example_func2highres

    convert_xfm -inverse -omat $dir/highres2example_func.mat $dir/example_func2highres.mat

    flirt -in $dir/highres -ref $dir/standard -out $dir/highres2standard -omat $dir/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 


    fnirt --iout=$dir/highres2standard_head --in=$dir/highres_head --aff=$dir/highres2standard.mat --cout=$dir/highres2standard_warp --iout=$dir/highres2standard --jout=$dir/highres2highres_jac --config=T1_2_MNI152_2mm --ref=$dir/standard_head --refmask=$dir/standard_mask --warpres=10,10,10

    applywarp -i $dir/highres -r $dir/standard -o $dir/highres2standard -w $dir/highres2standard_warp
    convert_xfm -inverse -omat $dir/standard2highres.mat $dir/highres2standard.mat


    convert_xfm -omat $dir/example_func2standard.mat -concat $dir/highres2standard.mat $dir/example_func2highres.mat

    convertwarp --ref=$dir/standard --premat=$dir/example_func2highres.mat --warp1=$dir/highres2standard_warp --out=$dir/example_func2standard_warp

    applywarp --ref=$dir/standard --in=$dir/example_func --out=$dir/example_func2standard --warp=$dir/example_func2standard_warp

    convert_xfm -inverse -omat $dir/standard2example_func.mat $dir/example_func2standard.mat

    mcflirt -in $dir/prefiltered_func_data -out $dir/prefiltered_func_data_mcf -reffile $dir/example_func -spline_final
    
    slicetimer -i $dir/prefiltered_func_data_mcf --out=$dir/prefiltered_func_data_st -r 3.000000 
    
    fslmaths $dir/prefiltered_func_data_st -Tmean $dir/mean_func

    bet $dir/mean_func $dir/mask -f 0.3 -n -m
    
    immv $dir/mask_mask $dir/mask

    fslmaths $dir/prefiltered_func_data_st -mas $dir/mask $dir/prefiltered_func_data_bet

    fslstats $dir/prefiltered_func_data_bet -p 2 -p 98

    fslmaths $dir/prefiltered_func_data_bet -thr 136.5380371 -Tmin -bin $dir/mask -odt char

    fslstats $dir/prefiltered_func_data_st -k $dir/mask -p 50

    fslmaths $dir/mask -dilF $dir/mask

    fslmaths $dir/prefiltered_func_data_st -mas $dir/mask $dir/prefiltered_func_data_thresh

    fslmaths $dir/prefiltered_func_data_thresh -Tmean $dir/mean_func

    susan $dir/prefiltered_func_data_thresh 602.789703 2.1231422505307855 3 1 1 $dir/mean_func 602.789703 $dir/prefiltered_func_data_smooth

    fslmaths $dir/prefiltered_func_data_smooth -mas $dir/mask $dir/prefiltered_func_data_smooth

    fslmaths $dir/prefiltered_func_data_smooth -inm 10000 $dir/prefiltered_func_data_intnorm

    fslmaths $dir/prefiltered_func_data_intnorm -Tmean $dir/tempMean

    fslmaths $dir/prefiltered_func_data_intnorm -bptf 1.6666666666666667 -1 -add $dir/tempMean $dir/prefiltered_func_data_tempfilt

    imrm $dir/tempMean

    fslmaths $dir/prefiltered_func_data_tempfilt $dir/filtered_func_data
    
    applywarp --ref=$dir/standard --in=$dir/filtered_func_data --out=$dir/filtered_func_data2standard --warp=$dir/example_func2standard_warp
    
    
    # find $dir ! -name 'filtered_func_data2standard.nii.gz' -type f -exec rm -f {} +
}

export -f process_fmri_
declare -x -f process_fmri_ 

parallel --jobs 25 --timeout 400% --progress --joblog /data/DL_subset/fmri_pcp_log.txt process_fmri_ ::: ${fmri_dirs[@]}
