#!/bin/sh
#######################################################################
# Script to submit jobs on Ares cluster via slurm using T2K containers
#######################################################################
usage () {
  echo "------------------------------------------------"
  echo "ERROR: $1"
  echo "------------------------------------------------"
  echo "Description: Script to submit SLURM jobs on Ares cluster using ND280 highland2 analysis package installed on a Singularity container."
  echo "Usage: $0 [ANALYSISNAME] [ANALYSISVER] [FILELIST] [NJOBS] [WALLHOURS] [WALLMINUTES] [PMEM]"
  echo ""
  echo "ANALYSISNAME - name of the highland analysis package (eg. highland2ControlSamples/stoppingControlSamples, numuCCAnalysis, etc.)"
  echo "ANALYSISVER - version of the highland analysis package (eg. v0r0). Use NONE if no version available."
  echo "FILELIST - txt file with the list of anal files (eg. Production6BNeut4w.list)"
  echo "NJOBS - number of jobs to submit (recommended: at least 100)"
  echo "WALLHOURS - number of hours dedicated for the single job (walltime = WALLHOURS+WALLMINUTES) (recommended: data-0, mc-1)"
  echo "WALLMINUTES - number of minutes dedicated for the single job (walltime = WALLHOURS+WALLMINUTES) (recommended: data-20, mc-30)"
  echo "PMEM - memory in Gb available for single job (recommended: 4)"
  echo "-------------------------------------------------"
  echo "Example 1: $ $0 highland2ControlSamples/stoppingControlSamples NONE Prod6TNeut2w.list 100 0 10 1"
  echo "-------------------------------------------------"
  echo "Useful commands:"
  echo "$ squeue: check job status"
  echo "$ watch -n 10 squeue: check job status every 10 sec"
  echo "$ hpc-jobs-history -j jobid -v: display more useful details about the job (memory usage, time elapsed etc.)"
  echo "-------------------------------------------------"
  exit 1
}
#############################################################################################
# Hard-coded additional arguments - paths to ND280 software. They have to be modified here...
#############################################################################################
#Directory with containers on Ares
CONTAINERDIR=/net/pr2/projects/plgrid/plggt2k/containers
#Name of the actual container that you would like to use
CONTAINERNAME=centos7-superxsllhfitter-t2kreweight-highland-matchingControlSamples-stoppingControlSamples.sif
#Grant ID on Ares
GRANTID=plggt2k2022ares-cpu
#Directory with highland2 installation in container
HIGHLAND2INSTALLATIONDIR=/usr/local/t2k/current
#Version of the highland2Master package installed in the container
HIGHLAND2MASTERVERSION=2.82
##################################
# Get arguments from the command line...
##################################
ANALYSISNAME=$1
shift
ANALYSISVER=$1
shift
FILELIST=$1
shift
NJOBS=$1
shift
WALLHOURS=$1
shift
WALLMINUTES=$1
shift
PMEM=$1
shift
#
CURRDIR=`pwd`
#
##################################
# Sanity checks...
##################################
if [ "x$ANALYSISNAME" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ "x$ANALYSISVER" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ "x$FILELIST" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ "x$NJOBS" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ "x$WALLHOURS" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ "x$WALLMINUTES" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ "x$PMEM" == "x" ]; then
  usage "WRONG NUMBER OF ARGUMENTS!"
fi
if [ ! -d ${CONTAINERDIR} ]; then
  usage "!CONTAINERDIR. Please check additional arguments in the script code."
fi
if [ ! -f ${CONTAINERDIR}/${CONTAINERNAME} ]; then
  usage "!CONTAINERNAME. Please check additional arguments in the script code."
fi
##################################
# Prepare output file and working dir names
##################################
OUTPUT_BASE=`basename $FILELIST`
OUTPUT_HEAD=${OUTPUT_BASE%.*}
####
##################################
# Create working dir
#
OUTPUT_DIR=$OUTPUT_HEAD
#
if [ -d "${OUTPUT_DIR}" ]; then
  OUTPUT_DIR=`mktemp -d ${OUTPUT_HEAD}_XXX` || exit 1
  echo "WARNING: Output directory ${OUTPUT_HEAD} already exists! Will save files in ${OUTPUT_DIR} directory!"
  read -r -p "Do you want to continue the script? [Y/n] " response
  response=${response,,} # tolower
  if [[ $response =~ ^(no|n| ) ]]; then
    echo "SCRIPT ABORTED!"
    #Clean up the temporary dir
    if [ -d "${OUTPUT_DIR}" ]; then
      rm -rf ${OUTPUT_DIR}
    fi
    exit 1
  #else
  #  continue
  fi
else
  #OUTPUT_DIR=${OUTPUT_HEAD}
  mkdir ${OUTPUT_DIR}
  echo "${OUTPUT_DIR} directory created."
fi
###################
#Get the tail of the path to the analysis exec
ANALYSISEXEC=`echo ${ANALYSISNAME} | cut -d'/' -f2-`
# Prepare the name of the executable (need to change first letter to uppercase)
#ANALYSISEXEC=`echo ${ANALYSISNAME} | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }'`
ANALYSISEXEC=`echo ${ANALYSISEXEC} | awk '{ print toupper(substr($0, 1, 1)) substr($0, 2) }'`
ANALYSISEXECHEAD=`echo ${ANALYSISEXEC} | awk '{print substr($0,1,3)}'`
ANALYSISEXEC="Run${ANALYSISEXEC}.exe"

# If analysis name if p0d... then need to change exec name from RunP0d... to RunP0D...
if [ "$ANALYSISEXECHEAD" == "P0d" ]; then
ANALYSISEXEC=`echo ${ANALYSISNAME} | awk '{ print toupper(substr($0, 1, 3)) substr($0, 4) }'`
ANALYSISEXEC="Run${ANALYSISEXEC}.exe"
fi

# In the case of incNCAnalysis prepare the name of the executable without changing first letter to uppercase
if [ "$ANALYSISNAME" == "incNCAnalysis" ]; then
ANALYSISEXEC=`echo ${ANALYSISNAME}`
ANALYSISEXEC="Run${ANALYSISEXEC}.exe"
fi
##################################
echo "########################"
echo "List of parameters:"
echo "------------------------"
echo "ANALYSISNAME (The name of your highland2 package): $ANALYSISNAME"
echo "ANALYSISVER (The version of your highland2 package): $ANALYSISVER"
echo "ANALYSISEXEC (The name of the executable for your package): $ANALYSISEXEC"
echo "FILELIST (The list of the input files): $FILELIST"
echo "NJOBS (Number of jobs to submit): $NJOBS"
echo "WALLHOURS (Walltime: number of hours per job): $WALLHOURS"
echo "WALLMINUTES (Walltime: number of minutes per job): $WALLMINUTES"
echo "PMEM (Memory per job in GB): $PMEM"
echo "CURRDIR (Current working directory): $CURRDIR"
echo "OUTPUT_DIR (Output directory): $OUTPUT_DIR"
echo "GRANTID (Grant ID on PL-GRID): $GRANTID"
echo "CONTAINERDIR (Path to the directory with containers): $CONTAINERDIR"
echo "CONTAINERNAME (Name of the container .sif): $CONTAINERNAME"
echo "HIGHLAND2INSTALLATIONDIR (Highland2 installation directory in the container): $HIGHLAND2INSTALLATIONDIR"
echo "HIGHLAND2MASTERVERSION (Version of the highland2Master package installed in the container): $HIGHLAND2MASTERVERSION"
echo "#######################"
###################################
read -r -p "Are these parameters OK? Do you want to continue the script? [Y/n] " response
response=${response,,} # tolower
if [[ $response =~ ^(no|n| ) ]]; then
  echo "SCRIPT ABORTED! Please change the appropriate parameters and run the script again!"
  #Clean up the temporary dir
  if [ -d "${OUTPUT_DIR}" ]; then
    rm -rf ${OUTPUT_DIR}
  fi
  exit 1
#else
#  continue
fi
##################################
if [ ! -f "$FILELIST" ]; then
  echo "ERROR: File list file $FILELIST doesn't exist! Please check the path!"
  #Clean up the temporary dir
  if [ -d "${OUTPUT_DIR}" ]; then
    rm -rf ${OUTPUT_DIR}
  fi
  exit 1
fi
if [ ! -d "${CONTAINERDIR}" ]; then
  echo "ERROR: No $CONTAINERDIR directory! Please check the path!"
  #Clean up the temporary dir
  if [ -d "${OUTPUT_DIR}" ]; then
    rm -rf ${OUTPUT_DIR}
  fi
  exit 1
fi
if [ ! -f "${CONTAINERDIR}/${CONTAINERNAME}" ]; then
  echo "ERROR: No $CONTAINERDIR/$CONTAINERNAME file! Please provide the proper container name!"
  #Clean up the temporary dir
  if [ -d "${OUTPUT_DIR}" ]; then
    rm -rf ${OUTPUT_DIR}
  fi
  exit 1
fi
#################################
# Split file list into NJOBS lists
#################################
echo "## Splitting $FILELIST into $NJOBS lists..."
# number of files in the original files list
NFILES=`cat $FILELIST | wc -l`
#
# number of files per job
# this number is ceiled 
NFILESPERJOB=$(expr "$NFILES" / "$NJOBS" + 1)
#
for (( i0 = 1 ; i0 <= $NJOBS; i0++ ))
do
  #Trick to add leading zeros to the job number (eg. 1->001 etc.)
  i=`printf %03d $i0`
  #
  HEADNUMBER=$(expr "$i" \* "$NFILESPERJOB")
  #
  head -${HEADNUMBER} ${FILELIST} | tail -${NFILESPERJOB} > ${OUTPUT_DIR}/list${i}.txt
done
echo "## Done!"
##################################
# Run NJOBS jobs
##################################
cd ${OUTPUT_DIR}
echo "## Submitting $NJOBS jobs..."
for (( i0 = 1 ; i0 <= $NJOBS; i0++ ))
do
  #Trick to add leading zeros to the job number (eg. 1->001 etc.)
  i=`printf %03d $i0`
  #
  OUTPUT_FILE=${OUTPUT_HEAD}_job${i}_output.root
  #
  if [ "$ANALYSISVER" == "NONE" ]; then
    ANALYSISSCRIPT="${HIGHLAND2INSTALLATIONDIR}/${ANALYSISNAME}/bin/setup.sh"
  else
    ANALYSISSCRIPT="${HIGHLAND2INSTALLATIONDIR}/${ANALYSISNAME}_${ANALYSISVER}/bin/setup.sh"
  fi
########################################################
  cat >> job_$i.sh <<EOF
#!/bin/bash -l
#
## Set necessary environment (ND280 software, highland2, analysis)
source ${HIGHLAND2INSTALLATIONDIR}/nd280SoftwarePilot/nd280SoftwarePilot.profile
source ${HIGHLAND2INSTALLATIONDIR}/highland2SoftwarePilot/highland2SoftwarePilot.profile
source ${HIGHLAND2INSTALLATIONDIR}/highland2Master_${HIGHLAND2MASTERVERSION}/bin/setup.sh
source ${ANALYSISSCRIPT}
#
#Run the actual application
cd ${CURRDIR}/${OUTPUT_DIR}
${ANALYSISEXEC} -o ${CURRDIR}/${OUTPUT_DIR}/${OUTPUT_FILE} ${CURRDIR}/${OUTPUT_DIR}/list${i}.txt
EOF
########################################################
  cat >> runjob_$i.sh <<EOF
#!/bin/bash -l
#
## Main setup...
#
#SBATCH -p plgrid
#SBATCH -A ${GRANTID}
#
## Job Resources
#
#SBATCH -t ${WALLHOURS}:${WALLMINUTES}:0
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem-per-cpu=${PMEM}gb
#
## Set output/input format
#
#SBATCH -o job_${i}.sh.out
#SBATCH -e job_${i}.sh.err
#
## Set email options - Currently turned off
#
##SBATCH --mail-type=FAIL
##SBATCH --mail-user=test@gmail.com
#
## Set this option to be able to run singularity
#SBATCH -C memfs
#
##Run the singularity with the job_$i.sh script
cd ${CONTAINERDIR}
singularity run -B /net ${CONTAINERNAME} ${CURRDIR}/${OUTPUT_DIR}/job_$i.sh
EOF
##########################################################
  #
  chmod u+x job_$i.sh
  #
  echo "# Job $i..."
  sbatch runjob_${i}.sh
  echo "# Submitted!"
  #echo "# ${OUTPUT_FILE}"
  #echo "# list${i}.txt"
  #
  #rm -rf list${i}.txt
done
###################################
echo "## All jobs submitted successfully!"
#
#rm -rf fileList.txt
