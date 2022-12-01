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
endif
if ($MACHINE == aleph) then
	setenv CESMROOT /mnt/lustre/share/CESM/cesm2.1.4-rc.07
	setenv CESM2_LE_TOOLS_ROOT $HOME/CESM_CASE_MANAGEMENT_TOOLS
	setenv MYROOT /mnt/lustre/share/CESM
	setenv POSTPROCESS_PATH /home/jedwards/workflow/CESM_postprocessing
	source $POSTPROCESS_PATH/cesm-env2/bin/activate
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

end

setenv CASEROOT $MYROOT/${test}/$CASENAME

echo $CASEROOT
if ( $mbr == $smbr ) then
  set masterroot = $CASEROOT
  $CESMROOT/cime/scripts/create_newcase --case $CASEROOT --res $RESOLN  --mach $MACHINE --compset $COMPSET --output-root /mnt/lustre/share/CESM/output/
  cd $CASEROOT
  
  ./case.setup
  mv user_nl_cam user_nl_cam.`date +%m%d-%H%M`
  mv user_nl_clm user_nl_clm.`date +%m%d-%H%M`
  mv user_nl_cpl user_nl_cpl.`date +%m%d-%H%M`
  mv user_nl_cice user_nl_cice.`date +%m%d-%H%M`
  cp $CESM2_LE_TOOLS_ROOT/user_nl_files/* $CASEROOT/
  mv SourceMods SourceMods.`date +%m%d-%H%M`
  cp -r $CESM2_LE_TOOLS_ROOT/SourceMods $CASEROOT/
 
  ./xmlchange RUN_REFCASE=b.e21.B1850.f09_g17.CMIP6-piControl.001
  ./xmlchange RUN_REFDATE=${USE_REFDATE}-01-01
  ./xmlchange STOP_N=$STOP_N
  ./xmlchange STOP_OPTION=$STOP_OPTION
  ./xmlchange RESUBMIT=$RESUBMIT
  ./xmlchange DOUT_S_ROOT=/mnt/lustre/share/CESM/archive/$CASENAME
  ./preview_namelists

  qcmd -- ./case.build >& bld.`date +%m%d-%H%M`
  $POSTPROCESS_PATH/cesm-env2/bin/create_postprocess --caseroot $CASEROOT 
else
  $CESMROOT/cime/scripts/create_clone --case $CASEROOT --clone $masterroot --keepexe
  cd $CASEROOT
  ./xmlchange DOUT_S_ROOT=/mnt/lustre/share/CESM/archive/$CASENAME
  rm -fr postprocess
  $POSTPROCESS_PATH/cesm-env2/bin/create_postprocess --caseroot $CASEROOT 
  ./xmlchange RUN_REFDATE=${USE_REFDATE}-01-01
  ./xmlchange RESUBMIT=$RESUBMIT
  ./preview_namelists
endif

end             # member loop

exit

