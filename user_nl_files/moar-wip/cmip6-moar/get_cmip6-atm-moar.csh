#!/bin/tcsh

setenv CASE b.e21.BSSP126cmip6.f09_g17.CMIP6-SSP1-2.6.102
setenv DOUT_S_ROOT /glade/campaign/collections/cmip/CMIP6/timeseries-cmip6/$CASE
setenv outdir /glade/work/nanr/cesm_tags/CASE_tools/cesm2-le/user_nl_files/moar-wip/

ls $DOUT_S_ROOT/atm/proc/tseries/month_1/$CASE.cam.h0.* | cut -d"." -f16 | uniq | sort > $outdir/atm.mon.h0.txt
ls $DOUT_S_ROOT/atm/proc/tseries/day_1/$CASE.cam.h1.* | cut -d"." -f16 | uniq | sort > $outdir/atm.day.h1.txt
ls $DOUT_S_ROOT/atm/proc/tseries/day_1/$CASE.cam.h6.* | cut -d"." -f16 | uniq | sort > $outdir/atm.day.h6.txt
ls $DOUT_S_ROOT/atm/proc/tseries/hour_6/$CASE.cam.h2.* | cut -d"." -f16 | uniq | sort > $outdir/atm.6hr.h2.txt
ls $DOUT_S_ROOT/atm/proc/tseries/hour_1/$CASE.cam.h4.* | cut -d"." -f16 | uniq | sort > $outdir/atm.1hr.h4.txt
ls $DOUT_S_ROOT/atm/proc/tseries/hour_3/$CASE.cam.h3.* | cut -d"." -f16 | uniq | sort > $outdir/atm.3hr.h3.txt
