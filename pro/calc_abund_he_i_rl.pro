; docformat = 'rst'

function calc_abund_he_i_rl, temperature=temperature, density=density, $
                      linenum=linenum, line_flux=line_flux, $
                      he_i_aeff_data=he_i_aeff_data, h_i_aeff_data=h_i_aeff_data
;+
;     This function determines the ionic abundance from the observed 
;     flux intensity for the given wavelength of He I recombination line 
;     by using the recombination coefficients from Porter et al. 
;     2012MNRAS.425L..28P.
;
; :Returns:
;    type=double. This function returns the ionic abundanc.
;
; :Keywords:
;     temperature    :    in, required, type=float
;                         electron temperature
;     density        :    in, required, type=float
;                         electron density
;     linenum        :    in, required, type=int
;                         Line Number for Wavelength
;                         
;                         Wavelength=4120.84:linenum=7,  
;                         
;                         Wavelength=4387.93: linenum=8, 
;                         
;                         Wavelength=4437.55: linenum=9, 
;                         
;                         Wavelength=4471.50: linenum=10, 
;                         
;                         Wavelength=4921.93: linenum=12, 
;                         
;                         Wavelength=5015.68: linenum=13, 
;                         
;                         Wavelength=5047.74: linenum=14, 
;                         
;                         Wavelength=5875.66: linenum=15, 
;                         
;                         Wavelength=6678.16: linenum=16, 
;                         
;                         Wavelength=7065.25: linenum=17, 
;                         
;                         Wavelength=7281.35: linenum=18. 
;                         
;     line_flux      :    in, required, type=float
;                         line flux intensity
;     he_i_aeff_data :    in, required, type=array/object
;                         He I recombination coefficients
;     h_i_aeff_data  :    in, required, type=array/object
;                         H I recombination coefficients
;
; :Examples:
;    For example::
;
;     IDL> base_dir = file_dirname(file_dirname((routine_info('$MAIN$', /source)).path))
;     IDL> data_rc_dir = ['atomic-data-rc']
;     IDL> Atom_RC_He_I_file= filepath('rc_he_ii_PFSD12.fits', root_dir=base_dir, subdir=data_rc_dir )
;     IDL> Atom_RC_SH95_file= filepath('rc_SH95.fits', root_dir=base_dir, subdir=data_rc_dir )
;     IDL> atom='h'
;     IDL> ion='ii' ; H I
;     IDL> h_i_rc_data=atomneb_read_aeff_sh95(Atom_RC_SH95_file, atom, ion)
;     IDL> h_i_aeff_data=h_i_rc_data[0].Aeff
;     IDL> atom='he'
;     IDL> ion='ii' ; He I
;     IDL> he_i_rc_data=atomneb_read_aeff_he_i_pfsd12(Atom_RC_He_I_file, atom, ion)
;     IDL> he_i_aeff_data=he_i_rc_data[0].Aeff
;     IDL> temperature=double(10000.0)
;     IDL> density=double(5000.0)
;     IDL> he_i_4471_flux= 2.104
;     IDL> linenum=10; 4471.50
;     IDL> Abund_he_i=calc_abund_he_i_rl(temperature=temperature, density=density, $
;                                       linenum=linenum, line_flux=he_i_4471_flux, $
;                                       he_i_aeff_data=he_i_aeff_data, h_i_aeff_data=h_i_aeff_data)
;     IDL> print, 'N(He^+)/N(H^+):', Abund_he_i
;        N(He^+)/N(H^+):     0.040848393
;
; :Categories:
;   Abundance Analysis, Recombination Lines
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
;   0.3.0
;
; :History:
;     Based on improved He I emissivities in the case B
;     from Porter et al. 2012MNRAS.425L..28P
;     
;     15/12/2013, A. Danehkar, IDL code written.
;     
;     20/03/2017, A. Danehkar, Integration with AtomNeb.
;     
;     10/07/2019, A. Danehkar, Made a new function calc_emiss_he_i_rl()
;                      for calculating line emissivities and separated it
;                      from calc_abund_he_i_rl().
;-
  
  if keyword_set(temperature) eq 0 then begin 
    print,'Temperature is not set'
    return, 0
  endif
  if keyword_set(density) eq 0 then begin 
    print,'Density is not set'
    return, 0
  endif
  if keyword_set(he_i_aeff_data) eq 0 then begin 
    print,'He I recombination coefficients (he_i_aeff_data) are not set'
    return, 0
  endif
  if keyword_set(h_i_aeff_data) eq 0 then begin 
    print,'H I recombination coefficients (h_i_aeff_data) are not set'
    return, 0
  endif
  if keyword_set(linenum) eq 0 then begin 
    print,'Line Number for Wavelength is not given'
    return, 0
  endif
  if keyword_set(line_flux) eq 0 then begin 
    print,'Line flux intensity (line_flux) is not given'
    return, 0
  endif  
  if (temperature le 0.D0) or (density le 0.D0) then begin
      print,'temperature = ', temperature, ', density = ', density
      return, 0
  endif
  emissivity_Hbeta=calc_emiss_h_beta(temperature=temperature,density=density,h_i_aeff_data=h_i_aeff_data)
  
  emissivity=calc_emiss_he_i_rl(temperature=temperature, density=density, linenum=linenum, $
                                he_i_aeff_data=he_i_aeff_data)
  abund = (emissivity_Hbeta/emissivity)*double(line_flux/100.0)
  
  return,abund
end
