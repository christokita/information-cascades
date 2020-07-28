#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=3:59:00
#SBATCH --mail-type=NONE
#SBATCH --mail-user=ctokita@princeton.edu
#SBATCH --output=slurm_outfiles/slurm-%A.out


module load anaconda3 
srun python3 scripts/track_assort_NBmodel.py