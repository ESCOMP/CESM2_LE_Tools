#!/bin/csh -f
### set env variables

## Tag includes sfwf SourceMods!
setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-rc.08
setenv CESM_TOOLS /glade/work/nanr/cesm_tags/CASE_tools/aixue/cesm2-thermal-haline/

set COMPSET = B1850cmip6
set USECOMPSET = B1850cmip6
set MACHINE = cheyenne
set RESOLN = f09_g17
set mbr = 1
set PROJECT = P93300313

setenv CASENAME b.e21.${COMPSET}.f09_g17.thermalHalineConstant.00${mbr}
setenv REFCASE  b.e21.${COMPSET}.f09_g17.thermalHaline.00${mbr}
setenv REFDATE  0151-01-01

setenv CASEROOT /glade/work/nanr/amoc-hosing/cases/$CASENAME
setenv RUNDIR /glade/scratch/nanr/$CASENAME/run/

cd $CESMROOT/cime/scripts/
./create_newcase --case $CASEROOT --res $RESOLN  --compset $USECOMPSET  --project $PROJECT

cd $CASEROOT

./xmlchange RUN_REFCASE=$REFCASE
./xmlchange RUN_REFDATE=$REFDATE
./xmlchange STOP_N=3
./xmlchange STOP_OPTION=nyears
./xmlchange RESUBMIT=49
#./xmlchange JOB_QUEUE=economy --subgroup case.run
./xmlchange GET_REFCASE=FALSE

cp $CESM_TOOLS/pelayout/env_mach_pes.xml .

cp $CESM_TOOLS/user_nl_files/thermalHalineConstant/user_nl_cam $CASEROOT/user_nl_cam
cp $CESM_TOOLS/user_nl_files/thermalHalineConstant/user_nl_pop $CASEROOT/user_nl_pop
cp $CESM_TOOLS/SourceMods/src.pop/haline/* $CASEROOT/SourceMods/src.pop/

if (! -d /glade/scratch/nanr/$CASENAME/run/) then
   mkdir -p /glade/scratch/nanr/$CASENAME/run/
endif

cp /glade/work/nanr/amoc-hosing/fromFred/hosing_AMOChaline_50-70N_years1850-1999.211113.nc /glade/scratch/nanr/$CASENAME/run/
cp /glade/scratch/nanr/archive/b.e21.B1850cmip6.f09_g17.thermalHaline.001/rest/0151-01-01-00000/rpointer.* $RUNDIR
ln -s /glade/scratch/nanr/archive/b.e21.B1850cmip6.f09_g17.thermalHaline.001/rest/0151-01-01-00000/b.e21.B1850cmip6.f09_g17.thermalHaline.001.* $RUNDIR

./case.setup


./preview_namelists

qcmd -- ./case.build >& bld.`date +%m%d-%H%M`

