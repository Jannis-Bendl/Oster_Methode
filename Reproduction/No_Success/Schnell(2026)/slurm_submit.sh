#!/bin/bash
#SBATCH -A p31568
#SBATCH --partition=long
#SBATCH --time=120:00:00
#SBATCH --job-name=Schnell2026_Replication
#SBATCH --output=code/log/slurm%A.out
#SBATCH --error=code/log/slurm%A.err

#SBATCH --nodes=3
#SBATCH --ntasks=3
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=100G

# Thread safety
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1

cd "$SLURM_SUBMIT_DIR/code"

#####################################################
# 1. Run Stata jobs (single node)
#####################################################

srun --nodes=1 --ntasks=1 -c 16 --exclusive \
     bash -lc "module purge; module load stata/17; stata-mp -b do C0_stata_clean.do"
srun --nodes=1 --ntasks=1 -c 16 --exclusive \
     bash -lc "module purge; module load stata/17; stata-mp -b do C1_stata_analysis.do"
srun --nodes=1 --ntasks=1 -c 1 --exclusive \
     bash -lc "module purge; module load stata/17; stata-se -b do C2_stata_matlab_prep.do"
rm -f *.log

#####################################################
# 2. Run MATLAB jobs in parallel
#####################################################

srun --nodes=1 --ntasks=1 -c 16 --exclusive \
    bash -lc "module purge; module load matlab/r2022b-rhel7; matlab -batch \"run('C3_matlab_analysis_main.m')\"" &
srun --nodes=1 --ntasks=1 -c 16 --exclusive \
     bash -lc "module purge; module load matlab/r2022b-rhel7; matlab -batch \"run('C3_matlab_analysis_altmkts.m')\"" &
srun --nodes=1 --ntasks=1 -c 16 --exclusive \
     bash -lc "module purge; module load matlab/r2022b-rhel7; matlab -batch \"run('C3_matlab_analysis_altR.m')\"" &

wait # wait for parallel MATLAB jobs to finish

srun --nodes=1 --ntasks=1 -c 16 --exclusive \
     bash -lc "module purge; module load matlab/r2022b-rhel7; matlab -batch \"run('C4_matlab_post.m')\"" 

#####################################################
# 3. Stata post-processing (single node) 
#####################################################

srun --nodes=1 --ntasks=1 -c 16 --exclusive \
     bash -lc "module purge; module load stata/17; stata-mp -b do C5_stata_matlab_post.do"
rm -f *.log