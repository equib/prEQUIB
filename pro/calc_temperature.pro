; docformat = 'rst'

function calc_temperature, line_flux_ratio=line_flux_ratio, density=density, $
                          upper_levels=upper_levels, lower_levels=lower_levels, $
                          elj_data=elj_data, omij_data=omij_data, $
                          aij_data=aij_data
;+
;     This function determines electron temperature from given 
;     flux intensity ratio for specified ion with upper level(s)
;     lower level(s) by solving atomic level populations and 
;     line emissivities in statistical equilibrium 
;     for given electron density.
;
; :Returns:
;    type=double. This function returns the electron temperature.
;
; :Keywords:
;     line_flux_ratio  :     in, required, type=float
;                            flux intensity ratio
;     density          :     in, required, type=float
;                            electron density
;     upper_levels     :     in, required, type=string,
;                            upper atomic level(s) e.g '1,2/', '1,2,1,3/'
;     lower_levels     :     in, required, type=string
;                            lower atomic level(s) e.g '1,2/', '1,2,1,3/'
;     elj_data         :     in, required, type=array/object
;                            energy levels (Ej) data
;     omij_data        :     in, required, type=array/object
;                            collision strengths (omega_ij) data
;     aij_data         :     in, required, type=array/object
;                            transition probabilities (Aij) data
;
; :Examples:
;    For example::
;
;     IDL> base_dir = file_dirname(file_dirname((routine_info('$MAIN$', /source)).path))
;     IDL> data_dir = ['atomic-data', 'chianti70']
;     IDL> Atom_Elj_file = filepath('AtomElj.fits', root_dir=base_dir, subdir=data_dir )
;     IDL> Atom_Omij_file = filepath('AtomOmij.fits', root_dir=base_dir, subdir=data_dir )
;     IDL> Atom_Aij_file = filepath('AtomAij.fits', root_dir=base_dir, subdir=data_dir )
;     IDL> atom='s'
;     IDL> ion='ii'
;     IDL> s_ii_elj=atomneb_read_elj(Atom_Elj_file, atom, ion, level_num=5) ; read Energy Levels (Ej)
;     IDL> s_ii_omij=atomneb_read_omij(Atom_Omij_file, atom, ion) ; read Collision Strengths (Omegaij)
;     IDL> s_ii_aij=atomneb_read_aij(Atom_Aij_file, atom, ion) ; read Transition Probabilities (Aij)
;     IDL> upper_levels='1,2,1,3/'
;     IDL> lower_levels='1,5/'
;     IDL> density = double(2550)
;     IDL> line_flux_ratio=double(10.753)
;     IDL> temperature=calc_temperature(line_flux_ratio=line_flux_ratio, density=density, $
;     IDL>                              upper_levels=upper_levels, lower_levels=lower_levels, $
;     IDL>                              elj_data=s_ii_elj, omij_data=s_ii_omij, $
;     IDL>                              aij_data=s_ii_aij)
;     IDL> print, "Electron Temperature:", temperature
;        Electron Temperature:       7920.2865
;
; :Categories:
;   Plasma Diagnostics, Collisionally Excited Lines
;
; :Dirs:
;  ./
;      Main routines
;
; :Author:
;   Ashkbiz Danehkar
;
; :Copyright:
;   This library is released under a GNU General Public License.
;
; :Version:
;   0.0.6
;
; :History:
;     15/09/2013, A. Danehkar, Translated from FORTRAN to IDL code.
;
;     20/10/2016, A. Danehkar, Replaced str2int with strnumber.
;
;     20/10/2016, A. Danehkar, Replaced CFY, SPLMAT, and CFD with
;          IDL function INTERPOL( /SPLINE).
;
;     20/10/2016, A. Danehkar, Replaced LUSLV with IDL LAPACK function
;                       LA_LINEAR_EQUATION.
;
;     15/11/2016, A. Danehkar, Replaced LA_LINEAR_EQUATION (not work in GDL)
;           with IDL function LUDC & LUSOL.
;
;     19/11/2016, A. Danehkar, Replaced INTERPOL (not accurate) with
;                    SPL_INIT & SPL_INTERP.
;
;     20/11/2016, A. Danehkar, Made a new function calc_populations()
;       for solving atomic level populations and separated it from
;       calc_abundance(), calc_density() and calc_temperature().
;
;     10/03/2017, A. Danehkar, Integration with AtomNeb, now uses atomic data
;                      input elj_data, omij_data, aij_data.
;     
;     12/06/2017, A. Danehkar, Cleaning the function, and remove unused varibales
;                        from calc_temperature().
;                        
;     27/06/2019, A. Danehkar, fix a bug in the atomic level assumption, and 
;                        use the simplified calc_populations() routine.
;
; FORTRAN HISTORY:
;
;     03/05/1981, I.D.Howarth,  Version 1.
;
;     05/05/1981, I.D.Howarth,  Minibug fixed!
;
;     07/05/1981, I.D.Howarth,  Now takes collision rates or strengths.
;
;     03/08/1981, S.Adams,      Interpolates collision strengths.
;
;     07/08/1981, S.Adams,      Input method changed.
;
;     19/11/1984, R.E.S.Clegg,  SA files entombed in scratch disk. Logical
;                               filenames given to SA's data files.
;
;     08/1995, D.P.Ruffle, Changed input file format. Increased matrices.
;
;     02/1996, X.W.Liu,   Tidy up. SUBROUTINES SPLMAT, HGEN, CFY and CFD
;                         modified such that matrix sizes (i.e. maximum
;                         of Te and maximum no of levels) can now be cha
;                         by modifying the parameters NDIM1, NDIM2 and N
;                         in the Main program. EASY!
;                         Now takes collision rates as well.
;                         All variables are declared explicitly
;                         Generate two extra files (ionpop.lis and ionra
;                         of plain stream format for plotting.
;
;     06/1996, C.J.Pritchet, Changed input data format for cases IBIG=1,2.
;                         Fixed readin bug for IBIG=2 case.
;                         Now reads reformatted upsilons (easier to see
;                         and the 0 0 0 data end is excluded for these c
;                         The A values have a different format for IBIG=.
;
;     2006, B.Ercolano,   Converted to F90.
;-

;+
; NAME:
;     cal_temperature
;
; PURPOSE:
;     This function determines electron temperature from given 
;     flux intensity ratio for specified ion with upper level(s)
;     lower level(s) by solving atomic level populations and 
;     line emissivities in statistical equilibrium 
;     for given electron density.
;
; CALLING SEQUENCE:
;     Result = calc_temperature(LINE_FLUX_RATIO=line_flux_ratio, DENSITY=density, $
;                              UPPER_LEVELS=upper_levels, LOWER_LEVELS=lower_levels, $
;                              ELJ_DATA=elj_data, OMIJ_DATA=omij_data, $
;                              AIJ_DATA=aij_data)
;
; KEYWORD PARAMETERS:
;     LINE_FLUX_RATIO  :     in, required, type=float, flux intensity ratio
;     DENSITY          :     in, required, type=float, electron density
;     UPPER_LEVELS     :     in, required, type=string, upper atomic level(s) e.g '1,2/', '1,2,1,3/'
;     LOWER_LEVELS     :     in, required, type=string, lower atomic level(s) e.g '1,2/', '1,2,1,3/'
;     ELJ_DATA         :     in, required, type=array/object, energy levels (Ej) data
;     OMIJ_DATA        :     in, required, type=array/object, collision strengths (omega_ij) data
;     AIJ_DATA         :     in, required, type=array/object, transition probabilities (Aij) data
;     
; OUTPUTS:  This function returns a double as the electron temperature.
; 
; PROCEDURE: This function calls calc_populations.
;
; EXAMPLE:
;     base_dir = file_dirname(file_dirname((routine_info('$MAIN$', /source)).path))
;     data_dir = ['atomic-data', 'chianti70']
;     Atom_Elj_file = filepath('AtomElj.fits', root_dir=base_dir, subdir=data_dir )
;     Atom_Omij_file = filepath('AtomOmij.fits', root_dir=base_dir, subdir=data_dir )
;     Atom_Aij_file = filepath('AtomAij.fits', root_dir=base_dir, subdir=data_dir )
;     atom='s'
;     ion='ii'
;     s_ii_elj=atomneb_read_elj(Atom_Elj_file, atom, ion, level_num=5) ; read Energy Levels (Ej)
;     s_ii_omij=atomneb_read_omij(Atom_Omij_file, atom, ion) ; read Collision Strengths (Omegaij)
;     s_ii_aij=atomneb_read_aij(Atom_Aij_file, atom, ion) ; read Transition Probabilities (Aij)
;     upper_levels='1,2,1,3/'
;     lower_levels='1,5/'
;     density = double(2550)
;     line_flux_ratio=double(10.753)
;     temperature=calc_temperature(line_flux_ratio=line_flux_ratio, density=density, $
;                                  upper_levels=upper_levels, lower_levels=lower_levels, $
;                                  elj_data=s_ii_elj, omij_data=s_ii_omij, $
;                                  aij_data=s_ii_aij)
;     print, "Electron Temperature:", temperature
;     > Electron Temperature:       7920.2865
;
; MODIFICATION HISTORY:
;     15/09/2013, A. Danehkar, Translated from FORTRAN to IDL code.
;     20/10/2016, A. Danehkar, Replaced str2int with strnumber.
;     20/10/2016, A. Danehkar, Replaced CFY, SPLMAT, and CFD with
;          IDL function INTERPOL( /SPLINE).
;     20/10/2016, A. Danehkar, Replaced LUSLV with IDL LAPACK function
;                       LA_LINEAR_EQUATION.
;     15/11/2016, A. Danehkar, Replaced LA_LINEAR_EQUATION (not work in GDL)
;           with IDL function LUDC & LUSOL.
;     19/11/2016, A. Danehkar, Replaced INTERPOL (not accurate) with
;                    SPL_INIT & SPL_INTERP.
;     20/11/2016, A. Danehkar, Made a new function calc_populations()
;       for solving atomic level populations and separated it from
;       calc_abundance(), calc_density() and calc_temperature().
;     10/03/2017, A. Danehkar, Integration with AtomNeb, now uses atomic data
;                      input elj_data, omij_data, aij_data.
;     12/06/2017, A. Danehkar, Cleaning the function, and remove unused varibales
;                        from calc_temperature().
;     27/06/2019, A. Danehkar, fix a bug in the atomic level assumption, and 
;                        use the simplified calc_populations() routine.
; 
; FORTRAN HISTORY:
;     03/05/1981, I.D.Howarth,  Version 1.
;     05/05/1981, I.D.Howarth,  Minibug fixed!
;     07/05/1981, I.D.Howarth,  Now takes collision rates or strengths.
;     03/08/1981, S.Adams,      Interpolates collision strengths.
;     07/08/1981, S.Adams,      Input method changed.
;     19/11/1984, R.E.S.Clegg,  SA files entombed in scratch disk. Logical
;                               filenames given to SA's data files.
;     08/1995, D.P.Ruffle, Changed input file format. Increased matrices.
;     02/1996, X.W.Liu,    Tidy up. SUBROUTINES SPLMAT, HGEN, CFY and CFD
;                          modified such that matrix sizes (i.e. maximum
;                          of Te and maximum no of levels) can now be cha
;                          by modifying the parameters NDIM1, NDIM2 and N
;                          in the Main program. EASY!
;                          Now takes collision rates as well.
;                          All variables are declared explicitly
;                          Generate two extra files (ionpop.lis and ionra
;                          of plain stream format for plotting.
;     06/1996, C.J.Pritchet, Changed input data format for cases IBIG=1,2.
;                          Fixed readin bug for IBIG=2 case.
;                          Now reads reformatted upsilons (easier to see
;                          and the 0 0 0 data end is excluded for these c
;                          The A values have a different format for IBIG=.
;     2006, B.Ercolano,    Converted to F90.
;- 
;  common share1, Atomic_Data_Path
  
  h_Planck = 6.62606957e-27 ; erg s
  c_Speed = 2.99792458e10 ; cm/s 
  
  iteration= long(0)
  
  I= long(0) 
  I1= long(0) 
  I2= long(0) 
  J= long(0) 
  K= long(0) 
  L= long(0) 
  JT= long(0) 
  JJD= long(0)
  level_num= long(0) 
  temp_num= long(0) 
  IRATS= long(0) 
  INT= long(0) 
  IND= long(0) 
  IT= long(0)
  IKT= long(0) 
  IA= long(0) 
  IB= long(0) 
     
  TEMPI=double(0) 
  TINC=double(0)
  DENSI=double(0) 
  DINC=double(0)
  temperature=double(0)
  EJI=double(0)
  WAV=double(0)
  emis_sum_a=double(0)
  emis_sum_b=double(0)
  QX=double(0)
  AX=double(0)
  EX=double(0)
  FRAT=double(0)
  DEE=double(0)
  LTEXT = '';
  
  result1=double(0)
     
  I= long(0)
  J= long(0)
  K= long(0)
  
  temp=size(elj_data,/DIMENSIONS)
  level_num=temp[0]
  temp=size(omij_data[0].strength,/DIMENSIONS)
  temp_num=temp[0]
  temp=size(omij_data,/DIMENSIONS)
  omij_num=temp[0]
  
  WAVA=dblarr(level_num+1)
  WAVB=dblarr(level_num+1)
  Omij=dblarr(temp_num,level_num,level_num)
  check_value=dblarr(3+1)
     
  LABEL1=STRARR(level_num+1)
  
  upper_levels_str=strsplit(upper_levels, ',', ESCAPE='/', /EXTRACT)
  lower_levels_str=strsplit(lower_levels, ',', ESCAPE='/', /EXTRACT)
  
  temp=size(upper_levels_str, /N_ELEMENTS)
  upper_levels_num=long(temp[0]/2)
  temp=size(lower_levels_str, /N_ELEMENTS)
  lower_levels_num=long(temp[0]/2)
  
  ITRANA=lonarr(2,upper_levels_num)
  ITRANB=lonarr(2,lower_levels_num)
  
  ITRANA[*,*]=0
  ITRANB[*,*]=0
  
  upper_levels_i=0
  for i=0, upper_levels_num-1 do begin 
    res=_strnumber(upper_levels_str[upper_levels_i], val)
    if res eq 1 then ITRANA[0,i]=long(val)
    res=_strnumber(upper_levels_str[upper_levels_i+1], val)
    if res eq 1 then ITRANA[1,i]=long(val)
    upper_levels_i = upper_levels_i + 2
    ;if upper_levels_i ge 2*upper_levels_num then break
  endfor

  lower_levels_i=0
  for i=0, lower_levels_num-1 do begin 
    res=_strnumber(lower_levels_str[lower_levels_i], val)
    if res eq 1 then ITRANB[0,i]=long(val)
    res=_strnumber(lower_levels_str[lower_levels_i+1], val)
    if res eq 1 then ITRANB[1,i]=long(val)
    lower_levels_i = lower_levels_i + 2
    ;if lower_levels_i ge 2*lower_levels_num then break;
  endfor
  IRATS=0
  for k = 1, omij_num-1 do begin
    I = omij_data[k].level1
    J = omij_data[k].level2
    if I le level_num and J le level_num then begin
      Omij[0:temp_num-1,I-1,J-1] = omij_data[k].strength
    endif
  endfor
  ;level_max=max([max(ITRANA),max(ITRANB)]) ! mistake
  level_max=level_num
  Aij =aij_data.AIJ
  Elj =elj_data.Ej
  ; set temperature iterations
  ; start of iterations
  ; ****************************
  for iteration = 1, 9 do begin
    if (iteration eq 1) then begin
      TEMPI=5000.0
    endif else begin 
      TEMPI= check_value[1]
    endelse
    INT=4
    TINC=(15000.0)/((INT-1)^(iteration))
;    INT=15
;    TINC=(50000.0)/((INT-1)^(iteration))
;    INT=20
;    TINC=(70000.0)/((INT-1)^(iteration))
;    INT=50
;    TINC=(250000.0)/((INT-1)^(iteration))
;    INT=15
;    TINC=(70000.0)/((INT-1)^(iteration))
;    INT=30
;    TINC=(100000.0)/((INT-1)^(iteration))
    densi=density
    dinc=0
    ind=1
    
    RESULTS=dblarr(3+1,INT+1)
    if (densi le 0) then densi=1
    if (tempi lt 5000) then tempi=5000 ; add
    ; Start of temperature iteration
    for JT = 1, INT do begin
      temperature=TEMPI+(JT-1)*TINC 
      ; Start of density iteration=
      for JJD = 1, IND  do begin
        density=DENSI+(JJD-1)*DINC
        if (temperature le 0.D0) or (density le 0.D0) then begin
            print,'temperature = ', temperature, ', density = ', density
            return, 0
        endif
        if level_max gt level_num then begin
          print, "error outside level range"
          retunr, 0
        endif
        Nlj=calc_populations(temperature=temperature, density=density, $
                             elj_data=elj_data, omij_data=omij_data, $
                             aij_data=aij_data, $
                             coeff_omij=Omij, level_num=level_max, irats=irats)
        
        ; Search ITRANA, ITRANB for transitions & sum up   
        emis_sum_a=double(0.0)
        emis_sum_b=double(0.0)
        for IKT=0, upper_levels_num-1 do begin 
          I=ITRANA[0,IKT]
          J=ITRANA[1,IKT]
          emissivity_line=double(0.0)
          if (Aij[J-1,I-1] ne 0.D0) then begin
            EJI = Elj[J-1] - Elj[I-1]
            WAV = 1.D8 / EJI
            emissivity_line=Nlj[J-1]*Aij[J-1,I-1]*h_Planck*c_Speed*1.e8/WAV
            emis_sum_a=emis_sum_a+emissivity_line
          endif
        endfor
        for IKT=0, lower_levels_num-1 do begin 
          I=ITRANB[0,IKT]
          J=ITRANB[1,IKT]
          emissivity_line=double(0.0)
          if (Aij[J-1,I-1] ne 0.D0) then begin
            EJI = Elj[J-1] - Elj[I-1]
            WAV = 1.D8 / EJI
            emissivity_line=Nlj[J-1]*Aij[J-1,I-1]*h_Planck*c_Speed*1.e8/WAV
            emis_sum_b=emis_sum_b+emissivity_line
          endif
        endfor
        FRAT=emis_sum_a/emis_sum_b
        RESULTS[1, JT] = temperature
        RESULTS[2, JT] = density
        RESultS[3, JT] = FRAT-line_flux_ratio
      endfor
      for IA = 0, upper_levels_num-1 do begin
        I1=ITRANA[0,IA]
        I2=ITRANA[1,IA]
        DEE=Elj[I2-1]-Elj[I1-1]
        WAVA[IA]=1.D8/DEE
      endfor
      for IB = 0, lower_levels_num-1 do begin
        I1=ITRANB[0,IB]
        I2=ITRANB[1,IB]
        DEE=Elj[I2-1]-Elj[I1-1]
        WAVB[IB]=1.D8/DEE
      endfor
    ; End of the temperature iteration
    endfor
    ; iteration and detect the sign change.
    for I=2,INT do begin
      check=0
      if (_sign(results[3,I],results[3,1]) ne results[3,I]) then begin 
        ;if this condition, the values have a different sign
        check_value[*] = results[*,I-1] ; the value before the sign change returned
        check=1
        break
      endif
    endfor
    if(check eq 0) and (iteration lt 9) then begin ; check if there is any change of sign,
                             ;and checks if it should be upper or lower limit
      if(abs(results[3,1])) lt (abs(results[3,INT])) then begin
          check_value[*]=results[*,1]
      endif else begin 
                if(abs(results[3,INT]) lt abs(results[3,1])) then begin
                check_value[*]=results[*,INT-1]
            endif else begin
                print,'check_value is wrong'
                return, 0
           endelse
      endelse
    endif else begin 
      if (check eq 0) and (iteration eq 9) then begin ;check if no change of sign,
                             ;and checks if it should be upper or lower limit
      if(abs(results[3,1]) lt abs(results[3,INT])) then begin
         check_value[*]=results[*,1]
      endif else begin 
                if (abs(results[3,INT]) lt abs(results[3,1])) then begin
                check_value[*]=results[*,INT]
            endif else begin
                print,'check_value is wrong'
                return, 0
            endelse
          endelse
      endif
    endelse
  endfor
  ; end of iterations
  ;****************************
  result1 = check_value[1]
  return, result1
end
