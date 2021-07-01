#!/bin/csh
#
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH -p dav
#SBATCH -J LAR
#SBATCH --account=P93300313
#SBATCH -e LAR.err.%J
#SBATCH -o LAR.out.%J
#SBATCH --mail-type=ALL
#SBATCH --mail-user=nanr@ucar.edu
#
set disk = /glade/scratch/cesmsf/archive
set arcd = /glade/campaign/cesm/collections/CESM2-SF/restarts
#
cd ${disk}
#
#foreach case ( b.e21.B1850cmip6.f09_g17.CESM2-SF-AAER.00[1-5] )
#foreach case ( b.e21.B1850cmip6.f09_g17.CESM2-SF-EE.00[1-5] )
foreach case ( b.e21.B1850cmip6.f09_g17.CESM2-SF-AAER.011 b.e21.B1850cmip6.f09_g17.CESM2-SF-AAER.014 )
  date
  if ! ( -d ${arcd}/${case} ) then
    mkdir -p ${arcd}/${case}
  endif
  if ( -d ${disk}/${case}/rest ) then
    cd ${disk}/${case}/rest
    set year = `/bin/ls -1d {1853,1865,1880,1895,1910,1925,1940,1955,1970,1985,2000,2015}-*`
    foreach rest ( `echo ${year}`)
      if ! ( -f ${arcd}/${case}/${case}.rest.${rest}.tar ) then
        echo "Processing restarts: "${rest}
        tar -cf ${arcd}/${case}/${case}.rest.${rest}.tar ${rest}
        if ($status == 0) then
          echo 'tar -cf '${arcd}'/'${case}'/'${case}'.rest.'${rest}'.tar '${rest}
        else
           echo 'tar -cf failed on '${case}' '${rest}
        endif
      else
         echo ${arcd}"/"${case}"/"${case}".rest."${rest}".tar exists."
      endif
    end
  endif
end
#
exit
