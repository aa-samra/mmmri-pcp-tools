bids_dir=$1
export out_dir=$2
n_cpus=$3
sub_dirs=()

mkdir -p $out_dir
echo $out_dir

for dir in $bids_dir/sub-*; do
    sub_dirs+=("$dir")
done

process_fmri_(){
    b_dir=$1
    sub_name=$(basename $b_dir)
    o_dir="${out_dir}/${sub_name}"
    mkdir -p $o_dir
    for dir in $b_dir/ses-*/func; do
        func_dir=$dir
    done
    for dir in $b_dir/ses-*/anat; do
        anat_dir=$dir
    done
    cp -f $anat_dir/*.nii.gz $o_dir/T1w.nii.gz
    cp -f $_dir/*.nii.gz $o_dir/prefiltered_func_data.nii.gz
    
    
    bet $o_dir/T1w $o_dir/T1w_brain -m -f 0.5 -R

    fslmaths $o_dir/fMRI $o_dir/prefiltered_func_data -odt float

    cp $o_dir/prefiltered_func_data.nii.gz $o_dir/example_func.nii.gz
    
    # mkdir -p $o_dir/feat
    # mainfeatreg -F 6.00 -d $o_dir/feat -i $o_dir/fMRI -h $o_dir -w  7 -x 90
    # mkdir -p $o_dir/feat/reg
    
    fslmaths $o_dir/T1w_brain $o_dir/highres
    fslmaths $o_dir/T1w $o_dir/highres_head
   

    fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm_brain $o_dir/standard
    fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm $o_dir/standard_head
    fslmaths ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask_dil $o_dir/standard_mask

    epi_reg --epi=$o_dir/example_func --t1=$o_dir/highres_head --t1brain=$o_dir/highres --out=$o_dir/example_func2highres

    convert_xfm -inverse -omat $o_dir/highres2example_func.mat $o_dir/example_func2highres.mat

    flirt -in $o_dir/highres -ref $o_dir/standard -out $o_dir/highres2standard -omat $o_dir/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 


    fnirt --iout=$o_dir/highres2standard_head --in=$o_dir/highres_head --aff=$o_dir/highres2standard.mat --cout=$o_dir/highres2standard_warp --iout=$o_dir/highres2standard --jout=$o_dir/highres2highres_jac --config=T1_2_MNI152_2mm --ref=$o_dir/standard_head --refmask=$o_dir/standard_mask --warpres=10,10,10

    applywarp -i $o_dir/highres -r $o_dir/standard -o $o_dir/highres2standard -w $o_dir/highres2standard_warp
    convert_xfm -inverse -omat $o_dir/standard2highres.mat $o_dir/highres2standard.mat


    convert_xfm -omat $o_dir/example_func2standard.mat -concat $o_dir/highres2standard.mat $o_dir/example_func2highres.mat

    convertwarp --ref=$o_dir/standard --premat=$o_dir/example_func2highres.mat --warp1=$o_dir/highres2standard_warp --out=$o_dir/example_func2standard_warp

    applywarp --ref=$o_dir/standard --in=$o_dir/example_func --out=$o_dir/example_func2standard --warp=$o_dir/example_func2standard_warp

    convert_xfm -inverse -omat $o_dir/standard2example_func.mat $o_dir/example_func2standard.mat

    mcflirt -in $o_dir/prefiltered_func_data -out $o_dir/prefiltered_func_data_mcf -reffile $o_dir/example_func -spline_final
    
    slicetimer -i $o_dir/prefiltered_func_data_mcf --out=$o_dir/prefiltered_func_data_st -r 3.000000 
    
    fslmaths $o_dir/prefiltered_func_data_st -Tmean $o_dir/mean_func

    bet $o_dir/mean_func $o_dir/mask -f 0.3 -n -m
    
    immv $o_dir/mask_mask $o_dir/mask

    fslmaths $o_dir/prefiltered_func_data_st -mas $o_dir/mask $o_dir/prefiltered_func_data_bet

    fslstats $o_dir/prefiltered_func_data_bet -p 2 -p 98

    fslmaths $o_dir/prefiltered_func_data_bet -thr 136.5380371 -Tmin -bin $o_dir/mask -odt char

    fslstats $o_dir/prefiltered_func_data_st -k $o_dir/mask -p 50

    fslmaths $o_dir/mask -dilF $o_dir/mask

    fslmaths $o_dir/prefiltered_func_data_st -mas $o_dir/mask $o_dir/prefiltered_func_data_thresh

    fslmaths $o_dir/prefiltered_func_data_thresh -Tmean $o_dir/mean_func

    susan $o_dir/prefiltered_func_data_thresh 602.789703 2.1231422505307855 3 1 1 $o_dir/mean_func 602.789703 $o_dir/prefiltered_func_data_smooth

    fslmaths $o_dir/prefiltered_func_data_smooth -mas $o_dir/mask $o_dir/prefiltered_func_data_smooth

    fslmaths $o_dir/prefiltered_func_data_smooth -inm 10000 $o_dir/prefiltered_func_data_intnorm

    fslmaths $o_dir/prefiltered_func_data_intnorm -Tmean $o_dir/tempMean

    fslmaths $o_dir/prefiltered_func_data_intnorm -bptf 1.6666666666666667 -1 -add $o_dir/tempMean $o_dir/prefiltered_func_data_tempfilt

    imrm $o_dir/tempMean

    fslmaths $o_dir/prefiltered_func_data_tempfilt $o_dir/filtered_func_data
    
    applywarp --ref=$o_dir/standard --in=$o_dir/filtered_func_data --out=$o_dir/filtered_func_data2standard --warp=$o_dir/example_func2standard_warp
    
    
    # find $o_dir ! -name 'filtered_func_data2standard.nii.gz' -type f -exec rm -f {} +
}

export -f process_fmri_
declare -x -f process_fmri_ 

parallel --jobs $n_cpus --timeout 400% --progress --joblog /data/DL_subset/fmri_pcp_log.txt process_fmri_ ::: ${sub_dirs[@]}
