#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=100
#SBATCH --ntasks-per-node=20
#SBATCH --ntasks-per-core=1
#SBATCH --time=4:00:00
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=ctokita@princeton.edu

module load anaconda3
cd InformationCascades/
srun python3 scripts/2_parallel-networkbreaking.py [g_array] [rep_array]