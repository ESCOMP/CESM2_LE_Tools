#!/bin/csh 
### set env variables
module load ncl nco

setenv CESM2_TOOLS_ROOT /glade/work/nanr/cesm_tags/CASE_tools/cesm2-L83/
setenv DOUT_S_ROOT  /glade/scratch/nanr/archive/
setenv CASEROOT /glade/scratch/nanr/post-proc/

module use /glade/work/bdobbins/Software/Modules
module load cesm_postprocessing

# ...
# case name counter
set smbr =  2
set embr =  2

@ mb = $smbr
@ me = $embr

foreach mbr ( `seq $mb $me` )
if ($mbr < 10) then
        #set CASE = f.e21.FHIST_BGC.f09_f09_mg17.L83_cam6.00${mbr}
        set CASE = f.e21.FHIST_BGC.f09_f09_mg17.L83_cam6_nudging_clim.00${mbr}
else
        #set CASE = f.e21.FHIST_BGC.f09_f09_mg17.L83_cam6.0${mbr}
        set CASE = f.e21.FHIST_BGC.f09_f09_mg17.L83_cam6_nudging_clim.0${mbr}
endif

mkdir -p $CASEROOT/$CASE
cd $CASEROOT/$CASE

if ( ! -d "postprocess" ) then
   create_postprocess -caseroot=`pwd`
endif

cd postprocess

#pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/scratch/nanr/timeseries/$CASE/
pp_config --set TIMESERIES_OUTPUT_ROOTDIR=/glade/collections/cdg/timeseries-cmip6/$CASE
pp_config --set CASE=$CASE
pp_config --set DOUT_S_ROOT=$DOUT_S_ROOT/hist/$CASE
pp_config --set ATM_GRID=0.9x1.25
pp_config --set LND_GRID=0.9x1.25
pp_config --set ICE_GRID=0.9x1.25
pp_config --set OCN_GRID=0.9x1.25
pp_config --set ICE_NX=288
pp_config --set ICE_NY=192


echo "Made it here"

# =========================
# change a few things
# =========================
mv timeseries timeseries-OTB
cp $CESM2_TOOLS_ROOT/pp/timeseries $CASEROOT/$CASE/postprocess/
cp $CESM2_TOOLS_ROOT/pp/env_timeseries.xml $CASEROOT/$CASE/postprocess/

end             # member loop

exit

