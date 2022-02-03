#!/bin/csh -fx
### set env variables

set MACHINE = aleph
set MACHINE = cheyenne
#if ($USER==jedwards)
#set test=test
#else
set test=nanr
#endif

if ($MACHINE == cheyenne) then
	setenv CESMROOT /glade/work/nanr/cesm_tags/cesm2.1.4-rc.07
	setenv CESM2_LE_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-le/
	setenv MYROOT /glade/scratch/nanr/aleph/
  	setenv ARCHDIR /glade/scratch/nanr/archive/
  	setenv SCRATCH /glade/scratch/nanr/
else
	setenv CESMROOT /mnt/lustre/share/CESM/cesm2.1.4-rc.07
	setenv CESM2_LE_TOOLS_ROOT $HOME/CESM_CASE_MANAGEMENT_TOOLS
	setenv MYROOT /mnt/lustre/share/CESM
	setenv POSTPROCESS_PATH /home/jedwards/workflow/CESM_postprocessing
	source $POSTPROCESS_PATH/cesm-env2/bin/activate
  	setenv ARCHDIR /mnt/lustre/share/CESM/archive/
  	setenv SCRATCH /mnt/lustre/share/CESM/output/
endif


set COMPSET = BHISTsmbb
set RESOLN = f09_g17
set RESUBMIT = 1
set STOP_N=10
set STOP_OPTION=nyears

set smbr =  2
set embr =  20

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb 2 $me` )
@ USE_REFDATE = 1001 + ( $mbr - 1 ) * 10

if    ($mbr < 10) then
	setenv CASENAME b.e21${test}.${COMPSET}.${RESOLN}.LE2-${USE_REFDATE}.00${mbr}
else if ($mbr >= 10 && $mbr < 100) then
	setenv CASENAME b.e21${test}.${COMPSET}.${RESOLN}.LE2-${USE_REFDATE}.0${mbr}
else
	setenv CASENAME b.e21${test}.${COMPSET}.${RESOLN}.LE2-${USE_REFDATE}.${mbr}
endif

echo $CASENAME

setenv CASEROOT $MYROOT/${test}/$CASENAME

echo $CASEROOT
if ( $mbr == $smbr ) then
  set masterroot = $CASEROOT
  #$CESMROOT/cime/scripts/create_newcase --case $CASEROOT --res $RESOLN  --mach $MACHINE --compset $COMPSET --output-root /mnt/lustre/share/CESM/output/
  $CESMROOT/cime/scripts/create_newcase --case $CASEROOT --res $RESOLN  --mach $MACHINE --compset $COMPSET --output-root $SCRATCH
  cd $CASEROOT
  
  ./case.setup
  mv user_nl_cam user_nl_cam.`date +%m%d-%H%M`
  mv user_nl_clm user_nl_clm.`date +%m%d-%H%M`
  mv user_nl_cpl user_nl_cpl.`date +%m%d-%H%M`
  mv user_nl_cice user_nl_cice.`date +%m%d-%H%M`
  cp $CESM2_LE_TOOLS_ROOT/user_nl_files/BHISTsmbb-moar/* $CASEROOT/
  cp -r $CESM2_LE_TOOLS_ROOT/SourceMods/src.pop/BHISTsmbb-MOAR/* $CASEROOT/SourceMods/src.pop/
  cp -r $CESM2_LE_TOOLS_ROOT/SourceMods/src.clm/* $CASEROOT/SourceMods/src.clm/
  cp -r $CESM2_LE_TOOLS_ROOT/SourceMods/src.cam/* $CASEROOT/SourceMods/src.cam/
 
  ./xmlchange RUN_REFCASE=b.e21.B1850.f09_g17.CMIP6-piControl.001
  ./xmlchange RUN_REFDATE=${USE_REFDATE}-01-01
  ./xmlchange STOP_N=$STOP_N
  ./xmlchange STOP_OPTION=$STOP_OPTION
  ./xmlchange RESUBMIT=$RESUBMIT
 #./xmlchange DOUT_S_ROOT=/mnt/lustre/share/CESM/archive/$CASENAME
  ./xmlchange DOUT_S_ROOT=$ARCHDIR/$CASENAME

# turn on cosp
  ./xmlchange --append CAM_CONFIG_OPTS=-cosp

#  Save 4 restarts a year
  ./xmlchange REST_N=3
  ./xmlchange REST_OPTION=nmonths
  ./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE

if ($MACHINE == cheyenne) then
  ./xmlchange NTASKS_ICE=36
  ./xmlchange NTASKS_LND=504
  ./xmlchange ROOTPE_ICE=504
endif


  ./preview_namelists

  qcmd -- ./case.build >& bld.`date +%m%d-%H%M`
  #$POSTPROCESS_PATH/cesm-env2/bin/create_postprocess --caseroot $CASEROOT 
else
  $CESMROOT/cime/scripts/create_clone --case $CASEROOT --clone $masterroot --keepexe
  cd $CASEROOT
 #./xmlchange DOUT_S_ROOT=/mnt/lustre/share/CESM/archive/$CASENAME
  ./xmlchange DOUT_S_ROOT=$ARCHDIR/$CASENAME
  if ($MACHINE == cheyenne) then
      ./xmlchange NTASKS_ICE=36
      ./xmlchange NTASKS_LND=504
      ./xmlchange ROOTPE_ICE=504
  endif
  #rm -fr postprocess
  #$POSTPROCESS_PATH/cesm-env2/bin/create_postprocess --caseroot $CASEROOT 
  ./xmlchange RUN_REFDATE=${USE_REFDATE}-01-01
  ./xmlchange RESUBMIT=$RESUBMIT
  ./preview_namelists
  ./case.setup --reset; ./case.setup; ./xmlchange BUILD_COMPLETE=TRUE
endif

end             # member loop

exit
