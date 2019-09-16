#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --array=0-99%20
#SBATCH --time=3:59:00
#SBATCH --mail-type=begin
#SBATCH --mail-type=end
#SBATCH --mail-user=ctokita@princeton.edu

module load anaconda3
srun python3 scripts/2_parallel-networkbreaking.py 0 $SLURM_ARRAY_TASK_ID
