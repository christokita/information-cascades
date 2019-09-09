#!/bin/bash
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 1:00:00
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=ctokita@princeton.edu

module load anaconda3
cd InformationCascades/
srun python3 multiproc_test.py