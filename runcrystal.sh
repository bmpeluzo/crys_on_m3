#! /bin/bash

while getopts n:o:p:e:f: flag
do
	case ${flag} in
		n) nodes=${OPTARG};;
		o) out=${OPTARG};;
		p) part=${OPTARG};;
		e) prop=${OPTARG};;
		f) file=${OPTARG};;
	esac
done


if [ -z $out ]; then
	echo "Job name not specified"
else
	echo "#!/bin/bash
#SBATCH -J job_name
#SBATCH -o job_name
#SBATCH -p job_queue
#SBATCH --mem=500G
#SBATCH -N nodes
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=2

module purge
module load crystal/23/1.0.1

# Crystal Versions
#
# See documentation:
# https://www.crystal.unito.it/documentation.html
#
# Serial:
# Set \`--cpus-per-task=1\` and use \`crystalOMP\`
#
# Parallel:
# Set \`--cpus-per-task=<threads_per_task_integer>\` and use \`srun PcrystalOMP\`

job_dir=\${SCRATCH}/\${SLURM_JOB_ID}
mkdir -p \${job_dir}
export OMP_NUM_THREADS=\${SLURM_CPUS_PER_TASK}


########## copying additional input files ###############

if [ -e ${out}.f9 ]; then
	cp ${out}.f9 \${job_dir}/fort.9
fi

if [ -e BASISSET.DAT ]; then
	cp BASISSET.DAT \${job_dir}/
fi

if [ -e ${out}.f65 ]; then
	cp ${out}.f65 \${job_dir}/fort.65
fi

if [ -e ${out}.f75 ]; then
	cp ${out}.f75 \${job_dir}/fort.75
fi

if [ -e ${out}.f77 ]; then
	cp ${out}.f77 \${job_dir}/fort.77
fi


if [ -e ${out}.f21 ]; then
	cp ${out}.f21 \${job_dir}/fort.21
fi

if [ -e ${out}.f20 ]; then
	cp ${out}.f20 \${job_dir}/fort.20
fi


if [ -e ${out}.f34 ]; then
	cp ${out}.f34 \${job_dir}/fort.34
fi

if [ -e ${out}.f13 ]; then
	cp ${out}.f13 \${job_dir}/fort.13
fi

if [ -e ${out}.f80 ]; then
	cp ${out}.f80 \${job_dir}/fort.80
fi

if [ -e ${out}.freqinfo ]; then
	cp ${out}.freqinfo \${job_dir}/FREQINFO.DAT
fi

if [ -e ${out}.tensraman ]; then
	cp ${out}.tensraman \${job_dir}/TENS_RAMAN.DAT
fi

if [ -e ${out}.tensir ]; then
	cp ${out}.tensir \${job_dir}/TENS_IR.DAT
fi

if [ -e ${out}.vibpot ]; then
	cp ${out}.vibpot \${job_dir}/VIBPOT.DAT
fi

if [ -e ${out}.born ]; then
	cp ${out}.born \${job_dir}/BORN.DAT
fi

if [ -e ${out}.elasinfo ]; then
	cp ${out}.elasinfo \${job_dir}/ELASINFO.DAT
fi

if [ -e ${out}.eosinfo ]; then
	cp ${out}.eosinfo \${job_dir}/EOSINFO.DAT
fi

if [ -e ${out}.scanpes ]; then
	cp ${out}.scanpes \${job_dir}/SCANPES.DAT
fi

if [ -e ${out}.opthess ]; then
	cp ${out}.opthess \${job_dir}/OPTHESS.DAT
fi

if [ -e ${out}.optinfo ]; then
	cp ${out}.optinfo \${job_dir}/OPTINFO.DAT
fi

if [ -e ${out}.hessopt ]; then
	cp ${out}.hessopt \${job_dir}/HESSOPT.DAT
fi
" > ${out}.sbatch

# It defaults to read files from units with the same name as the input, In case the user wants to specify an additional FORT file to be read (will keep updating following this logic. IT ONLY WORKS FOR FORT FILES!!!!!!!) :

if [ -z ${file} ]; then
	echo "User did not specify additional input files"
	else
	file_name=$(ls ${file} | cut -d. -f1)
	file_ext=$(ls ${file} | cut -d. -f2)
	let size=${#file_ext} ## accessing the number of characters in the extension string
	new_ext=$(echo ${file_ext[@]:1:${size}})
	echo "You gave me ${file}, I will copy this file as fort.${new_ext}"
	echo "cp ${file} \${job_dir}/fort.${new_ext} " >> ${out}.sbatch
fi
 

#################################################################################


## It defaults to running crystal. If the user aims to run properties, the flag -pp should be specified

if [ -z ${prop} ]; then
	echo "cp ${out}.d12 \${job_dir}/INPUT
cd \${job_dir}
srun PcrystalOMP < INPUT >> ${out}.out " >> ${out}.sbatch
else
	echo "cp ${out}.d3 \${job_dir}/INPUT
cd \${job_dir}
srun Pproperties < INPUT >> ${out}.out " >> ${out}.sbatch
fi

echo "
echo \"JOD ID: \${SLURM_JOB_ID}\" >> ${out}.out 

cat INPUT >> ${out}.out " >> ${out}.sbatch


	sed -i 's/SBATCH -J job_name/SBATCH -J '${out}'/g' ${out}.sbatch
	sed -i 's/SBATCH -o job_name/SBATCH -o '${out}'.out/g' ${out}.sbatch
	
	if [ -z $nodes ]; then
		echo "Number of nodes not specified"
	else
		sed -i 's/SBATCH -N nodes/SBATCH -N '${nodes}'/g' ${out}.sbatch

		if [ -z $part ]; then
			echo "Partition not specified"
		else
			sed -i 's/SBATCH -p job_queue/SBATCH -p '${part}'/g' ${out}.sbatch
			if [[ "${part}" == "${high}" ]]; then
				sed -i 's/SBATCH --mem=500G/SBATCH --mem=1950GB/g' ${out}.sbatch
			fi
		fi
	fi
fi

echo "
if [ -e KAPPA.DAT ]
then
   cp KAPPA.DAT \${SLURM_SUBMIT_DIR}/${out}.KAPPA.DAT
fi

if [ -e POWER_C.DAT ]
then
   cp POWER_C.DAT \${SLURM_SUBMIT_DIR}/${out}.POWER_C.DAT
fi

if [ -e POWER.DAT ]
then
   cp POWER.DAT \${SLURM_SUBMIT_DIR}/${out}.POWER.DAT
fi

if [ -e SEEBECK.DAT ]
then
   cp SEEBECK.DAT \${SLURM_SUBMIT_DIR}/${out}.SEEBECK.DAT
fi

if [ -e SIGMA.DAT ]
then
   cp SIGMA.DAT \${SLURM_SUBMIT_DIR}/${out}.SIGMA.DAT
fi

if [ -e SIGMAS.DAT ]
then
   cp SIGMAS.DAT \${SLURM_SUBMIT_DIR}/${out}.SIGMAS.DAT
fi

if [ -e TDF.DAT ]
then
   cp TDF.DAT \${SLURM_SUBMIT_DIR}/${out}.TDF.DAT
fi

if [ -e fort.34 ]
then
   cp fort.34 \${SLURM_SUBMIT_DIR}/${out}.f34
fi

if [ -e fort.9 ]
then
   cp fort.9 \${SLURM_SUBMIT_DIR}/${out}.f9
fi

if [ -e fort.20 ]
then
   cp fort.20 \${SLURM_SUBMIT_DIR}/${out}.f20
fi

if [ -e OPTHESS.DAT ]
then
   cp OPTHESS.DAT \${SLURM_SUBMIT_DIR}/${out}.opthess
fi

if [ -e OPTINFO.DAT ]
then
   cp OPTINFO.DAT \${SLURM_SUBMIT_DIR}/${out}.optinfo
fi

if [ -e XMETRO.COR ]
then
   cp XMETRO.COR \${SLURM_SUBMIT_DIR}/${out}.xmetro
fi

if  [ -e BORN.DAT ]
then
   cp BORN.DAT \${SLURM_SUBMIT_DIR}/${out}.born
fi

if  [ -e IRREFR.DAT ]
then
   cp IRREFR.DAT \${SLURM_SUBMIT_DIR}/${out}.irrefr
fi

if  [ -e IRDIEL.DAT ]
then
   cp IRDIEL.DAT \${SLURM_SUBMIT_DIR}/${out}.irdiel
fi

if [ -e ADP.DAT ]
then
   cp ADP.DAT \${SLURM_SUBMIT_DIR}/${out}.adp
fi

if [ -e ELASINFO.DAT ]
then
   cp ELASINFO.DAT \${SLURM_SUBMIT_DIR}/${out}.elasinfo
fi

if [ -e EOSINFO.DAT ]
then
   cp EOSINFO.DAT \${SLURM_SUBMIT_DIR}/${out}.eosinfo
fi

if [ -e GEOMETRY.CIF ]
then
   cp GEOMETRY.CIF \${SLURM_SUBMIT_DIR}/${out}.cif
fi

if [ -e GAUSSIAN.DAT ]
then
   cp GAUSSIAN.DAT \${SLURM_SUBMIT_DIR}/${out}.gjf
fi

if [ -e FINDSYM.DAT ]
then
   cp FINDSYM.DAT \${SLURM_SUBMIT_DIR}/${out}.FINDSYM
fi

if ls \$TMPDIR/opt* &>/dev/null
then
  mkdir \${SLURM_SUBMIT_DIR}/${out}.optstory &> /dev/null
  for file in \$TMPDIR/opt*
  do
     cp \$file \${SLURM_SUBMIT_DIR}/${out}.optstory
  done
fi


if [ -e fort.69 ]
then
   cp fort.69 \${SLURM_SUBMIT_DIR}/${out}.f69
fi

if [ -e fort.98 ]
then
   cp fort.98 \${SLURM_SUBMIT_DIR}/${out}.f98
fi

if [ -e fort.80 ]
then
   cp fort.80 \${SLURM_SUBMIT_DIR}/${out}.f80
fi

if [ -e fort.13 ]
then
   cp fort.13 \${SLURM_SUBMIT_DIR}/${out}.f13
fi

if [ -e fort.85 ]
then
   cp fort.85 \${SLURM_SUBMIT_DIR}/${out}.f85
fi

if [ -e fort.90 ]
then
   cp fort.90 \${SLURM_SUBMIT_DIR}/${out}.f90
fi

if [ -e fort.21 ]
then
   cp fort.21 \${SLURM_SUBMIT_DIR}/${out}.f21
fi

if [ -e fort.75 ]
then
   cp fort.75 \${SLURM_SUBMIT_DIR}/${out}.f75
fi

if [ -e FREQINFO.DAT ]
then
   cp FREQINFO.DAT \${SLURM_SUBMIT_DIR}/${out}.freqinfo
fi

if [ -e TENS_IR.DAT ]
then
   cp TENS_IR.DAT \${SLURM_SUBMIT_DIR}/${out}.tensir
fi

if [ -e IRSPEC.DAT ]
then
   cp IRSPEC.DAT \${SLURM_SUBMIT_DIR}/${out}_IRSPEC.DAT
fi

if [ -e TENS_RAMAN.DAT ]
then
   cp TENS_RAMAN.DAT \${SLURM_SUBMIT_DIR}/${out}.tensraman
fi

if [ -e RAMSPEC.DAT ]
then
   cp RAMSPEC.DAT \${SLURM_SUBMIT_DIR}/${out}_RAMSPEC.DAT
fi

if [ -e SCANPES.DAT ]
then
   cp SCANPES.DAT \${SLURM_SUBMIT_DIR}/${out}.scanpes
fi

if [ -e VIBPOT.DAT ]
then
   cp VIBPOT.DAT \${SLURM_SUBMIT_DIR}/${out}.vibpot
fi

if [ -e MOLDRAW.DAT ]
then
   cp MOLDRAW.DAT \${SLURM_SUBMIT_DIR}/${out}.mol
fi

if [ -e fort.92 ]
then
   cp fort.92 \${SLURM_SUBMIT_DIR}/${out}.com
fi

if [ -e fort.33 ]
then
   cp fort.33 \${SLURM_SUBMIT_DIR}/${out}.xyz
fi

#----------------------------------------------------
# OUTPUT FILES generated from MOLDYN MODULE
# see library moldyn.f90, module Moldyn

if [ -e PCF.DAT ]
then
   cp PCF.DAT \${SLURM_SUBMIT_DIR}/PCF_${out}.DAT
fi

if [ -e INTEGRATED_PCF.DAT ]
then
   cp INTEGRATED_PCF.DAT \${SLURM_SUBMIT_DIR}/INTEGRATED_PCF_${out}.DAT
fi

if [ -e INTERPOL_PCF.DAT ]
then
   cp INTERPOL_PCF.DAT \${SLURM_SUBMIT_DIR}/INTERPOL_PCF_${out}.DAT
fi

if [ -e SCFOUT.LOG ]
then
   cp SCFOUT.LOG \${SLURM_SUBMIT_DIR}/${out}.out2
fi

if [ -e FREQUENCIES.DAT ]
then
   cp FREQUENCIES.DAT \${SLURM_SUBMIT_DIR}/FREQUENCIES_${out}.DAT
fi

if [ -e FREQPLOT.DAT ]
then
   cp FREQPLOT.DAT \${SLURM_SUBMIT_DIR}/FREQPLOT_${out}.DAT
fi

if [ -e HESSFREQ.DAT ]
then
   cp HESSFREQ.DAT \${SLURM_SUBMIT_DIR}/${out}.hessfreq
fi
---------------------------------------------------- " >> ${out}.sbatch


sbatch ${out}.sbatch
