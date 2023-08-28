

bids_dir=$1
export out_dir=$2
n_cpus=$3
sub_dirs=()

mkdir -p $out_dir
echo $out_dir

for dir in $bids_dir/sub-*; do
    sub_dirs+=("$dir")
done


process_dwi(){
    b_dir=$1
    sub_name=$(basename $b_dir)
    o_dir="${out_dir}/${sub_name}"
    mkdir -p $o_dir
    for dir in $b_dir/ses-*/dwi; do
        dwi_dir=$dir
    done
    cp -f $dwi_dir/*.bval $o_dir/bvals
    cp -f $dwi_dir/*.bvec $o_dir/bvecs
    cp -f $dwi_dir/*.nii.gz $o_dir/data.nii.gz
    echo $o_dir    
    eddy_correct $o_dir/data $o_dir/data_ec 0
    echo bet
    bet $o_dir/data_ec $o_dir/nodif_brain -m -f 0.4 -R
    echo dtifit
    dtifit -k $o_dir/data_ec  -m $o_dir/nodif_brain_mask.nii.gz -o $o_dir/DTI -r $o_dir/bvecs -b $o_dir/bvals
    echo flirt
    flirt -ref ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz -in $o_dir/DTI_FA -omat $o_dir/diff2ref.mat
    echo fnirt
    fnirt --in=$o_dir/DTI_FA --aff=$o_dir/diff2ref.mat --cout=$o_dir/diff2ref-warp.nii.gz --config=FA_2_FMRIB58_1mm
    echo applywarp
    mkdir -p $o_dir/scalars_standard/
    applywarp --ref=${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz --in=$o_dir/DTI_FA.nii.gz --warp=$o_dir/diff2ref-warp.nii.gz --out=$o_dir/scalars_standard/DTI_FA.nii.gz
    

    vecreg -i $o_dir/DTI_V1.nii.gz -o $o_dir/scalars_standard/DTI_V1.nii.gz -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz -w $o_dir/diff2ref-warp.nii.gz
    vecreg -i $o_dir/DTI_V2.nii.gz -o $o_dir/scalars_standard/DTI_V2.nii.gz -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz -w $o_dir/diff2ref-warp.nii.gz
    vecreg -i $o_dir/DTI_V3.nii.gz -o $o_dir/scalars_standard/DTI_V3.nii.gz -r ${FSLDIR}/data/standard/FMRIB58_FA_1mm.nii.gz -w $o_dir/diff2ref-warp.nii.gz
    
    echo invwarp
    invwarp -w $o_dir/diff2ref-warp.nii.gz -r $o_dir/nodif_brain.nii.gz -o $o_dir/ref2diff-warp.nii.gz
}

export -f process_dwi

parallel --jobs $n_cpus --timeout 300% --progress --joblog $out_dir/dwi_pcp_log.txt process_dwi ::: ${sub_dirs[@]}
