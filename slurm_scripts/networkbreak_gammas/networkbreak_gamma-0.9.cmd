#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=0-99%20
#SBATCH --time=3:59:00
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=ctokita@princeton.edu
#SBATCH --output=slurm_outfiles/slurm-%A_%a.out

##Load anaconda python packages
module load anaconda3 
##Run script with (1) gamma variable, and (2) replicate number
srun python3 scripts/2_parallel-networkbreaking.py -0.9 $SLURM_ARRAY_TASK_ID 