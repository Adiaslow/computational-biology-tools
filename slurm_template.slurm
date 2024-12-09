#!/bin/bash
#SBATCH --job-name=example_job       # Job name
#SBATCH --mail-user=user@ucsc.edu    # Email address for notifications
#SBATCH --mail-type=ALL              # Email notifications for job events
#SBATCH --partition=instruction      # Partition/queue name
#SBATCH --time=04:00:00              # Maximum runtime in HH:MM:SS
#SBATCH --ntasks=1                   # Number of tasks
#SBATCH --cpus-per-task=6            # CPU cores per task
#SBATCH --mem=16G                    # Memory per node
#SBATCH --output=job_%j.out          # Output file name (%j expands to jobID)
#SBATCH --nodes=1                    # Number of nodes
#SBATCH --ntasks-per-node=1          # Tasks per node

# Load the necessary modules
module load <module1_name>
module load <module2_name>

# Run the program with the necessary arguments
<command1> <arguments>
<command2> <arguments>
