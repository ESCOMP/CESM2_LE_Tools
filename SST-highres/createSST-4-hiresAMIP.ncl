load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;************************************************
begin
  print ("=========================================")
  print ("Starting:  createSST-4-hiresAMIP.ncl")
  print ("Start Time: "+systemfunc("date") )
  print ("=========================================")
  wkdir   = getenv(".")

  dd = systemfunc("date -u +%y%m%d")

  syr = 1949
  lyr = 2015
do y = syr,lyr
  uyr = y
  isleap = isleapyear(uyr)

  ifile1 = "tos_input4MIPs_SSTsAndSeaIce_HighResMIP_MOHC-HadISST-2-2-0-0-0_gn_"+uyr+"0101-"+uyr+"1231.nc"
  ifile2 = "siconc_input4MIPs_SSTsAndSeaIce_HighResMIP_MOHC-HadISST-2-2-0-0-0_gn_"+uyr+"0101-"+uyr+"1231.nc"
  ofile1 = "sst_HADISST_0.25_MOHC-HADISST-"+uyr+"0101-"+uyr+"1231.nc"

  in1  = addfile("/glade/scratch/nanr/SST-highres/"+ifile1,"r")
  in2  = addfile("/glade/scratch/nanr/SST-highres/"+ifile2,"r")
  system("rm " + "/glade/scratch/nanr/SST-highres/"+ofile1)
  of1  = addfile("/glade/scratch/nanr/SST-highres/"+ofile1,"c")

; vars       = getfilevarnames (in)
; nvars      = dimsizes(vars)

of1@author = "created by nanr; hiResAMIP forcing.  Script="+get_script_name + " on " + dd
; copy global attributes from SST file
in1_global= getvaratts(in1)
in1_vars = getfilevarnames(in1)
; copy global attributes
if (.not.all(ismissing(in1_global))) then
do i = 0, dimsizes(in1_global) - 1
;print("copy_fileatts: global attributes->" + in1_global(i) )
of1@$in1_global(i) $ = in1@$in1_global(i)$
end do
end if

; copy global attributes from sea ice file
in2_global= getvaratts(in2)
in2_vars = getfilevarnames(in2)
; copy global attributes
if (.not.all(ismissing(in2_global))) then
do i = 0, dimsizes(in2_global) - 1
if (in2_global(i) .eq. "tracking_id" .or. in2_global(i) .eq. "realm" .or. in2_global(i) .eq. "variable_id")
;print("copy_fileatts: global attributes->" + in2_global(i) )
of1@$in2_global(i) $ = in2@$in2_global(i)$
end if
end do
end if


  lat  = dble2flt(in1->latitude)
  lon  = dble2flt(in1->longitude)
  nlat = dimsizes(lat)
  nlon = dimsizes(lon)
  if (isleap .eq. True) then

        filedimdef(of1,"time",-1,True)
        print("I'm a leapyear " + uyr)
        ut = in2->time
        ymdh = ut_calendar(ut, 0)
        ; index values of all but 2/29
        usei = ind(.not.(ymdh(:,1).eq.2 .and. ymdh(:,2).eq.29) )
        SST_cpl = in1->tos(usei,:,:)
        ice_cov = in2->siconc(usei,:,:)
        lat!0 = "lat"
        lon!0 = "lon"
        SST_cpl!0 = "time"
        SST_cpl!1 = "lat"
        SST_cpl&lat = lat
        SST_cpl!2   = "lon"
        SST_cpl&lon = lon
        copy_VarCoords(SST_cpl,ice_cov)
        of1->time      = in1->time(usei)
        of1->time_bnds = in1->time_bnds(usei,:)
        of1->SST_cpl = SST_cpl
        of1->ice_cov = ice_cov

  	delete([/usei,lat,lon,ymdh,ut,SST_cpl,ice_cov/])

  else
  	SST_cpl = in1->tos
  	ice_cov = in2->siconc
  	filedimdef(of1,"time",-1,True) 

  	lat!0 = "lat"
  	lon!0 = "lon"
  	SST_cpl!0 = "time"
  	SST_cpl!1 = "lat"
  	SST_cpl&lat = lat
  	SST_cpl!2   = "lon"
  	SST_cpl&lon = lon
  	copy_VarCoords(SST_cpl,ice_cov)
  	of1->time_bnds = in1->time_bnds
  	of1->SST_cpl = SST_cpl
  	of1->ice_cov = ice_cov

  	delete([/lat,lon,SST_cpl,ice_cov/])

  end if

;===================================================================
; make time an UNLIMITED dimension; recommended  for most applications
;===================================================================



end do

end
