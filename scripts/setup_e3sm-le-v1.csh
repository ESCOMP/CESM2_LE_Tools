#!/bin/csh -f

set MACHINE = cori-knl

set EXPERIMENT = hist
set RESOLN       = ne30_oECv3_ICG
set RESOLNSHORT  = ne30
set COMPSET      = A_WCYCL20TRS_CMIP6
set COMPSETSHORT = 20TR_CMIP6
set PROJECT = mp9
set TAG = E3SM
set TAG = e3sm-le-v1

set mbr=1

if ($mbr < 10) then
	setenv CASE b.e3smv1.${COMPSETSHORT}.${RESOLNSHORT}.${EXPERIMENT}.00${mbr}
else
	setenv CASE b.e3smv1.${COMPSETSHORT}.${RESOLNSHORT}.${EXPERIMENT}.0${mbr}
endif

set PATH      = /global/project/projectdirs/ccsm1/people/$USER/
set RUNDIR    = $SCRATCH/$USER/$CASE/run
set BLDDIR    = $SCRATCH/$USER/$CASE/bld
setenv CASEROOT $PATH/cases/e3smv1-le/$CASE
set TOOLSROOT = /global/homes/n/nanr/CESM_tools/e3sm/

#setenv E3SMROOT ${PATH}/e3sm_tags/${TAG}/
#setenv E3SMROOT /global/u2/x/xyhuang/e3sm-le-v1/
setenv E3SMROOT ${PATH}/e3sm_tags/${TAG}/

#$E3SMROOT/cime/scripts/create_newcase --case MCSP_CMT_5_coupled --compset A_WCYCL20TRS_CMIP6 --res ne30_oECv3_ICG --pecount L --handle-preexisting-dirs u --mach cori-knl --output-root /global/cscratch1/sd/sglanvil/ --script-root /global/homes/s/sglanvil/cases/MCSP_CMT_5_coupled -project mp9

$E3SMROOT/cime/scripts/create_newcase --case $CASE --compset $COMPSET --res $RESOLN --pecount L --handle-preexisting-dirs u --mach $MACHINE --output-root $SCRATCH --script-root $CASEROOT -project $PROJECT

cd $CASEROOT

cp $TOOLSROOT/SourceMods/src.cam/cam_diagnostics.F90 ./SourceMods/src.cam/
cp $TOOLSROOT/user_nl_files/le-hist/user_nl_cam $CASEROOT/

./case.setup
./case.build

