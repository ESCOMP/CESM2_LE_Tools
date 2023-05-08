#!/bin/bash -fe

# E3SM Water Cycle v2 run_e3sm script template.
#
# Inspired by v1 run_e3sm script as well as SCREAM group simplified run script.
#
# Bash coding style inspired by:
# http://kfirlavi.herokuapp.com/blog/2012/11/14/defensive-bash-programming

   array=( 0201 )
refarray=( 1970 )

set ctr=0

for iyr in "${array[@]}"
do


# For debugging, uncomment libe below
#set -x

main() {

# Year array YYYY:  

echo ${iyr}
echo ${refarray[$ctr]}
set refyear = ${refarray[$ctr]}
echo ${refyear}

# --- Configuration flags ----

# Machine and project
MACHINE=cori-knl
PROJECT="mp9"
#readonly YYYY="0141"
#readonly YYYY=${iyr}

# Simulation
COMPSET="WCYCL20TR" # 20th century transient
RESOLUTION="ne30pg2_EC30to60E2r2"
CASE_NAME="v2.LR.historical_monthly-restarts_${iyr}"
CASE_GROUP="v2.LR"

# Code and compilation
CHECKOUT="20220412"
BRANCH="maint-2.0" # master as of 2021-12-21
CHERRY=(  )
DEBUG_COMPILE=false

# Run options
MODEL_START_TYPE="hybrid"  # 'initial', 'continue', 'branch', 'hybrid'
START_DATE="${refarray[$ctr]}-01-01"

# Additional options for 'branch' and 'hybrid'
GET_REFCASE=TRUE
REFYEAR=${iyr}
RUN_REFDIR="/global/cscratch1/sd/nanr/archive/v2.LR.historical_${iyr}/archive/rest/${refarray[$ctr]}-01-01-00000"
RUN_REFCASE="v2.LR.historical_${iyr}"
RUN_REFDATE="${refarray[$ctr]}-01-01"   # same as MODEL_START_DATE for 'branch', can be different for 'hybrid'

# Set paths
MY_PATH="/global/project/projectdirs/ccsm1/people/nanr"
#readonly CODE_ROOT="${HOME}/E3SMv2/code/${CHECKOUT}"
#readonly CASE_ROOT="${MY_PATH}/cases/e3smv2/${CASE_NAME}"
CODE_ROOT="${MY_PATH}/e3sm_tags/E3SMv2/E3SM/"
CASE_ROOT="/global/cscratch1/sd/${USER}/E3SMv2-monthlyRestarts/${CASE_NAME}"

# Sub-directories
CASE_BUILD_DIR=${CASE_ROOT}/build
CASE_ARCHIVE_DIR=${CASE_ROOT}/archive
#readonly CASE_BUILD_DIR=/global/cscratch1/sd/nanr/E3SMv2/v2.LR.SSP370_0111/build/
#readonly CASE_BUILD_DIR=$SCRATCH/$CASE_NAME/bld
#readonly CASE_ARCHIVE_DIR=$SCRATCH/archive/$CASE_NAME/

# Define type of run
#  short tests: 'XS_2x5_ndays', 'XS_1x10_ndays', 'S_1x10_ndays', 
#               'M_1x10_ndays', 'M2_1x10_ndays', 'M80_1x10_ndays', 'L_1x10_ndays'
#  or 'production' for full simulation
#readonly run='S_1x10_ndays'
#readonly run='S_1x1_nmonths'
#readonly run='M_1x1_nmonths'
#readonly run='L_1x1_nmonths'
#readonly run='XL_1x1_nmonths'
run='production'
if [ "${run}" != "production" ]; then

  # Short test simulations
  tmp=($(echo $run | tr "_" " "))
  layout=${tmp[0]}
  units=${tmp[2]}
  resubmit=$(( ${tmp[1]%%x*} -1 ))
  length=${tmp[1]##*x}

  CASE_SCRIPTS_DIR=${CASE_ROOT}/tests/${run}/case_scripts
  CASE_RUN_DIR=${CASE_ROOT}/tests/${run}/run
  PELAYOUT=${layout}
  WALLTIME="0:30:00"
  STOP_OPTION=${units}
  STOP_N=${length}
  STOP_DATE="-999"    # -999 or specify stop date as yyyyddmm without leading zeros
  REST_OPTION=${STOP_OPTION}
  REST_N=${STOP_N}
  RESUBMIT=${resubmit}
  DO_SHORT_TERM_ARCHIVING=false

else

  # Production simulation
  CASE_SCRIPTS_DIR=${CASE_ROOT}/case_scripts
  CASE_RUN_DIR=${CASE_ROOT}/run
  # nanr changes
  #readonly CASE_SCRIPTS_DIR=${CASE_ROOT}/
  #readonly CASE_RUN_DIR=${SCRATCH}/${CASE_NAME}/run
  # end nanr
  PELAYOUT="L"
  WALLTIME="48:00:00"
  STOP_OPTION="nyears"
  STOP_N="3" # How often to stop the model, should be a multiple of REST_N
  STOP_DATE="20150101"    # -999 or specify stop date as yyyyddmm without leading zeros
  REST_OPTION="nmonths"
  REST_N="1" # How often to write a restart file
  RESUBMIT="10" # Submissions after initial one
  DO_SHORT_TERM_ARCHIVING=false
fi

# Coupler history 
HIST_OPTION="nyears"
HIST_N="1"

# Leave empty (unless you understand what it does)
#OLD_EXECUTABLE=""
OLD_EXECUTABLE="/global/cscratch1/sd/nanr/E3SMv2/EXEROOT/build/e3sm.exe"

# --- Toggle flags for what to do ----
do_fetch_code=false
do_create_newcase=true
do_case_setup=true
do_case_build=false
do_case_submit=false

# --- Now, do the work ---

# Make directories created by this script world-readable
umask 022

# Fetch code from Github
fetch_code

# Create case
create_newcase

# Setup
case_setup

# Build
case_build

# Configure runtime options
runtime_options

# Copy script into case_script directory for provenance
copy_script

# Submit
case_submit

# All done
echo $'\n----- All done -----\n'

}

# =======================
# Custom user_nl settings
# =======================

user_nl() {

cat << EOF >> user_nl_eam
inithist = 'DAILY'

EOF

cat << EOF >> user_nl_elm
! Pointing to new simyr2015 file per Jim Benedict
 fsurdat = '/global/cfs/cdirs/e3sm/inputdata/lnd/clm2/surfdata_map/surfdata_ne30np4.pg2_SSP3_RCP70_simyr2015_c220420.nc'

! Override - updated after EAM/ELM fixes
 check_finidat_fsurdat_consistency = .false.
 check_finidat_pct_consistency = .true.
 check_finidat_year_consistency = .true.

EOF


}

patch_mpas_streams() {

echo

}

######################################################
### Most users won't need to change anything below ###
######################################################

#-----------------------------------------------------
fetch_code() {

    if [ "${do_fetch_code,,}" != "true" ]; then
        echo $'\n----- Skipping fetch_code -----\n'
        return
    fi

    echo $'\n----- Starting fetch_code -----\n'
    local path=${CODE_ROOT}
    local repo=e3sm

    echo "Cloning $repo repository branch $BRANCH under $path"
    if [ -d "${path}" ]; then
        echo "ERROR: Directory already exists. Not overwriting"
        exit 20
    fi
    mkdir -p ${path}
    pushd ${path}

    # This will put repository, with all code
    git clone git@github.com:E3SM-Project/${repo}.git .
    
    # Setup git hooks
    rm -rf .git/hooks
    git clone git@github.com:E3SM-Project/E3SM-Hooks.git .git/hooks
    git config commit.template .git/hooks/commit.template

    # Check out desired branch
    git checkout ${BRANCH}

    # Custom addition
    if [ "${CHERRY}" != "" ]; then
        echo ----- WARNING: adding git cherry-pick -----
        for commit in "${CHERRY[@]}"
        do
            echo ${commit}
            git cherry-pick ${commit}
        done
        echo -------------------------------------------
    fi

    # Bring in all submodule components
    git submodule update --init --recursive

    popd
}

#-----------------------------------------------------
create_newcase() {

    if [ "${do_create_newcase,,}" != "true" ]; then
        echo $'\n----- Skipping create_newcase -----\n'
        return
    fi

    echo $'\n----- Starting create_newcase -----\n'

    ${CODE_ROOT}/cime/scripts/create_newcase \
        --case ${CASE_NAME} \
        --case-group ${CASE_GROUP} \
        --output-root ${CASE_ROOT} \
        --script-root ${CASE_SCRIPTS_DIR} \
        --handle-preexisting-dirs u \
        --compset ${COMPSET} \
        --res ${RESOLUTION} \
        --machine ${MACHINE} \
        --project ${PROJECT} \
        --walltime ${WALLTIME} \
        --pecount ${PELAYOUT}

    if [ $? != 0 ]; then
      echo $'\nNote: if create_newcase failed because sub-directory already exists:'
      echo $'  * delete old case_script sub-directory'
      echo $'  * or set do_newcase=false\n'
      exit 35
    fi

}

#-----------------------------------------------------
case_setup() {

    if [ "${do_case_setup,,}" != "true" ]; then
        echo $'\n----- Skipping case_setup -----\n'
        return
    fi

    echo $'\n----- Starting case_setup -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Setup some CIME directories
    ./xmlchange CIME_OUTPUT_ROOT=${CASE_RUN_DIR}
    ./xmlchange EXEROOT=${CASE_BUILD_DIR}
    ./xmlchange RUNDIR=${CASE_RUN_DIR}
    # nanr changes
    #./xmlchange EXEROOT=/global/cscratch1/sd/nanr/E3SMv2/v2.LR.SSP370_0111/build/

    # Short term archiving
    ./xmlchange DOUT_S=${DO_SHORT_TERM_ARCHIVING}
    ./xmlchange DOUT_S_ROOT=${CASE_ARCHIVE_DIR}

    # Build with COSP, except for a data atmosphere (datm)
    if [ `./xmlquery --value COMP_ATM` == "datm"  ]; then 
      echo $'\nThe specified configuration uses a data atmosphere, so cannot activate COSP simulator\n'
    else
      echo $'\nConfiguring E3SM to use the COSP simulator\n'
      #./xmlchange --id CAM_CONFIG_OPTS --append --val='-cosp'
    fi

    # Extracts input_data_dir in case it is needed for user edits to the namelist later
    local input_data_dir=`./xmlquery DIN_LOC_ROOT --value`

    # Custom user_nl
    user_nl

    # Finally, run CIME case.setup
    ./case.setup --reset


    popd
}

#-----------------------------------------------------
case_build() {

    pushd ${CASE_SCRIPTS_DIR}

    # do_case_build = false
    if [ "${do_case_build,,}" != "true" ]; then

        echo $'\n----- case_build -----\n'

        if [ "${OLD_EXECUTABLE}" == "" ]; then
            # Ues previously built executable, make sure it exists
            if [ -x ${CASE_BUILD_DIR}/e3sm.exe ]; then
                echo 'Skipping build because $do_case_build = '${do_case_build}
            else
                echo 'ERROR: $do_case_build = '${do_case_build}' but no executable exists for this case.'
                exit 297
            fi
        else
            # If absolute pathname exists and is executable, reuse pre-exiting executable
            if [ -x ${OLD_EXECUTABLE} ]; then
                echo 'Using $OLD_EXECUTABLE = '${OLD_EXECUTABLE}
                cp -fp ${OLD_EXECUTABLE} ${CASE_BUILD_DIR}/
            else
                echo 'ERROR: $OLD_EXECUTABLE = '$OLD_EXECUTABLE' does not exist or is not an executable file.'
                exit 297
            fi
        fi
        echo 'WARNING: Setting BUILD_COMPLETE = TRUE.  This is a little risky, but trusting the user.'
        ./xmlchange BUILD_COMPLETE=TRUE

    # do_case_build = true
    else

        echo $'\n----- Starting case_build -----\n'

        # Turn on debug compilation option if requested
        if [ "${DEBUG_COMPILE^^}" == "TRUE" ]; then
            ./xmlchange DEBUG=${DEBUG_COMPILE^^}
        fi

        # Run CIME case.build
        ./case.build

    fi

    # Some user_nl settings won't be updated to *_in files under the run directory
    # Call preview_namelists to make sure *_in and user_nl files are consistent.
    echo $'\n----- Preview namelists -----\n'
    ./preview_namelists

    popd
}

#-----------------------------------------------------
runtime_options() {

    echo $'\n----- Starting runtime_options -----\n'
    pushd ${CASE_SCRIPTS_DIR}

    # Set simulation start date
    ./xmlchange RUN_STARTDATE=${START_DATE}

    # Segment length
    ./xmlchange STOP_OPTION=${STOP_OPTION,,},STOP_N=${STOP_N}

    # End date
    ./xmlchange STOP_DATE=${STOP_DATE}

    # Restart frequency
    ./xmlchange REST_OPTION=${REST_OPTION,,},REST_N=${REST_N}

    # Coupler history
    ./xmlchange HIST_OPTION=${HIST_OPTION,,},HIST_N=${HIST_N}

    # Coupler budgets (always on)
    ./xmlchange BUDGETS=TRUE

    # Set resubmissions
    if (( RESUBMIT > 0 )); then
        ./xmlchange RESUBMIT=${RESUBMIT}
    fi

    # Run type
    # Start from default of user-specified initial conditions
    if [ "${MODEL_START_TYPE,,}" == "initial" ]; then
        ./xmlchange RUN_TYPE="startup"
        ./xmlchange CONTINUE_RUN="FALSE"

    # Continue existing run
    elif [ "${MODEL_START_TYPE,,}" == "continue" ]; then
        ./xmlchange CONTINUE_RUN="TRUE"

    elif [ "${MODEL_START_TYPE,,}" == "branch" ] || [ "${MODEL_START_TYPE,,}" == "hybrid" ]; then
        ./xmlchange RUN_TYPE=${MODEL_START_TYPE,,}
        ./xmlchange GET_REFCASE=${GET_REFCASE}
        ./xmlchange RUN_REFDIR=${RUN_REFDIR}
        ./xmlchange RUN_REFCASE=${RUN_REFCASE}
        ./xmlchange RUN_REFDATE=${RUN_REFDATE}
        echo 'Warning: $MODEL_START_TYPE = '${MODEL_START_TYPE} 
        echo '$RUN_REFDIR = '${RUN_REFDIR}
        echo '$RUN_REFCASE = '${RUN_REFCASE}
        echo '$RUN_REFDATE = '${START_DATE}
    else
        echo 'ERROR: $MODEL_START_TYPE = '${MODEL_START_TYPE}' is unrecognized. Exiting.'
        exit 380
    fi
    ctr=$((ctr+1))

    # Patch mpas streams files
    patch_mpas_streams

    popd
}

#-----------------------------------------------------
case_submit() {

    if [ "${do_case_submit,,}" != "true" ]; then
        echo $'\n----- Skipping case_submit -----\n'
        return
    fi

    echo $'\n----- Starting case_submit -----\n'
    pushd ${CASE_SCRIPTS_DIR}
    
    # Run CIME case.submit
    ./case.submit

    popd
}

#-----------------------------------------------------
copy_script() {

    echo $'\n----- Saving run script for provenance -----\n'

    local script_provenance_dir=${CASE_SCRIPTS_DIR}/run_script_provenance
    mkdir -p ${script_provenance_dir}
    local this_script_name=`basename $0`
    local script_provenance_name=${this_script_name}.`date +%Y%m%d-%H%M%S`
    cp -vp ${this_script_name} ${script_provenance_dir}/${script_provenance_name}

}

#-----------------------------------------------------
# Silent versions of popd and pushd
pushd() {
    command pushd "$@" > /dev/null
}
popd() {
    command popd "$@" > /dev/null
}

# Now, actually run the script
#-----------------------------------------------------
main

done