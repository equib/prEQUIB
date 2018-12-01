function calc_density_ut::test_basic
  compile_opt strictarr
  
  base_dir = file_dirname(file_dirname((routine_info('calc_temperature_ut__define', /source)).path))
  data_dir = ['externals', 'atomneb', 'atomic-data', 'chianti70']
  Atom_Elj_file = filepath('AtomElj.fits', root_dir=base_dir, subdir=data_dir )
  Atom_Omij_file = filepath('AtomOmij.fits', root_dir=base_dir, subdir=data_dir )
  Atom_Aij_file = filepath('AtomAij.fits', root_dir=base_dir, subdir=data_dir )

  atom='s'
  ion='ii'
  s_ii_elj=atomneb_read_elj(Atom_Elj_file, atom, ion, level_num=5) ; read Energy Levels (Ej)
  s_ii_omij=atomneb_read_omij(Atom_Omij_file, atom, ion) ; read Collision Strengths (Omegaij)
  s_ii_aij=atomneb_read_aij(Atom_Aij_file, atom, ion) ; read Transition Probabilities (Aij)

  upper_levels='1,2/'   
  lower_levels='1,3/'
  diagtype='D'
  temperature=double(7000.0);
  line_flux_ratio=double(1.506);
  density=calc_density(line_flux_ratio=line_flux_ratio, temperature=temperature, $
                       upper_levels=upper_levels, lower_levels=lower_levels, $
                       elj_data=s_ii_elj, omij_data=s_ii_omij, $
                       aij_data=s_ii_aij)
      
  result= long(density*1e2)
  assert, result eq 260222, 'incorrect result: %d', result
  
  return, 1
end

pro calc_density_ut__define
  compile_opt strictarr

  define = { calc_density_ut, inherits MGutLibTestCase }
end

