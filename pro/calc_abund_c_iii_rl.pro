; docformat = 'rst'

function calc_abund_c_iii_rl, temperature=temperature, density=density, $
                      wavelength=wavelength, line_flux=line_flux, $
                      c_iii_rc_data=c_iii_rc_data, h_i_aeff_data=h_i_aeff_data
;+
;     This function determines the ionic abundance from the observed 
;     flux intensity for the given wavelength of C III recombination line 
;     by using the recombination coefficients from
;     Pequignot et al. 1991A&A...251..680P.
;
; :Returns:
;    type=double. This function returns the ionic abundanc.
;
; :Keywords:
;     temperature   :     in, required, type=float
;                         electron temperature
;     density       :     in, required, type=float
;                         electron density
;     wavelength    :     in, required, type=float
;                         Line Wavelength in Angstrom
;     line_flux     :     in, required, type=float
;                         line flux intensity
;     c_iii_rc_data :     in, required, type=array/object
;                         C III recombination coefficients
;     h_i_aeff_data :     in, required, type=array/object
;                         H I recombination coefficients
;
; :Examples:
;    For example::
;
;     IDL> base_dir = file_dirname(file_dirname((routine_info('$MAIN$', /source)).path))
;     IDL> data_rc_dir = ['atomic-data-rc']
;     IDL> Atom_RC_PPB91_file='/media/linux/proEQUIB/AtomNeb-idl/atomic-data-rc/rc_PPB91.fits'
;     IDL> Atom_RC_SH95_file= filepath('rc_SH95.fits', root_dir=base_dir, subdir=data_rc_dir )
;     IDL> atom='h'
;     IDL> ion='ii' ; H I
;     IDL> h_i_rc_data=atomneb_read_aeff_sh95(Atom_RC_SH95_file, atom, ion)
;     IDL> h_i_aeff_data=h_i_rc_data[0].Aeff
;     IDL> atom='c'
;     IDL> ion='iv' ; C III
;     IDL> c_iii_rc_data=atomneb_read_aeff_ppb91(Atom_RC_PPB91_file, atom, ion)
;     IDL> temperature=double(10000.0)
;     IDL> density=double(5000.0)
;     IDL> c_iii_4647_flux = 0.107
;     IDL> wavelength=4647.42
;     IDL> Abund_c_iii=calc_abund_c_iii_rl(temperature=temperature, density=density, $
;     IDL>                                 wavelength=wavelength, line_flux=c_iii_4647_flux, $
;     IDL>                                 c_iii_rc_data=c_iii_rc_data, h_i_aeff_data=h_i_aeff_data) 
;     IDL> print, 'N(C^3+)/N(H+):', Abund_c_iii
;        N(C^3+)/N(H+):    0.00017502840
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
;     Based on effective radiative recombination coefficients for C III lines from
;     Pequignot, Petitjean, Boisson, C. 1991A&A...251..680P.
;     
;     18/05/2013, A. Danehkar, Translated to IDL code.
;     
;     06/04/2017, A. Danehkar, Integration with AtomNeb.
;     
;     10/07/2019, A. Danehkar, Made a new function calc_emiss_c_iii_rl()
;                      for calculating line emissivities and separated it
;                      from calc_abund_c_iii_rl().
;-

  ; ciiiRLstructure ={Wave:double(0.0), Int:double(0.0), Obs:double(0.0), Abundance:double(0.0)}
  
  if keyword_set(temperature) eq 0 then begin 
    print,'Temperature is not set'
    return, 0
  endif
  if keyword_set(density) eq 0 then begin 
    print,'Density is not set'
    return, 0
  endif
  if keyword_set(c_iii_rc_data) eq 0 then begin 
    print,'C III recombination coefficients (c_iii_rc_data) are not set'
    return, 0
  endif
  if keyword_set(h_i_aeff_data) eq 0 then begin 
    print,'H I recombination coefficients (h_i_aeff_data) are not set'
    return, 0
  endif
  if keyword_set(wavelength) eq 0 then begin 
    print,'Wavelength is not given'
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
  emissivity=calc_emiss_c_iii_rl(temperature=temperature, density=density, wavelength=wavelength, $
                                c_iii_rc_data=c_iii_rc_data)
  abund = (emissivity_Hbeta/emissivity)*double(line_flux/100.0)
  
  return,abund
end
