module rossby_haurwitz_wave_test_mod

  use mesh_mod
  use parallel_mod
  use params_mod
  use dycore_mod

  implicit none

  private

  public rossby_haurwitz_wave_test_set_initial_condition

  real, parameter :: R = 4.0
  real, parameter :: omg = 7.848e-6
  real, parameter :: gd0 = 8.0e3 * g

contains

  ! u = a ω (cosφ + R cosᴿ⁻¹φ sin²φ cosRλ - cosᴿ⁺¹φ cosRλ)
  !
  ! v = - a ω R cosᴿ⁻¹φ sinφ sinRλ
  !
  ! gd = gd0 + a² A(φ) + a² B(φ) cosRλ + a² C(φ) cos2Rλ
  !
  ! A(φ) = 1/2 ω (2 Ω + ω) cos²φ + 1/4 ω² cos²ᴿφ ((R + 1) cos²φ + (2 R² - R - 2) - 2 R² cos⁻²φ)
  ! B(φ) = 2 (Ω + ω) ω cosᴿφ ((R² + 2 R + 2) - (R + 1)² cos²φ) / (R + 1) / (R + 2)
  ! C(φ) = 1/4 ω² cos²ᴿφ ((R + 1) cos²φ - (R + 2))


  subroutine rossby_haurwitz_wave_test_set_initial_condition()

    real lon, cos_lat, sin_lat
    real a, b, c
    integer i, j

    write(6, *) '[Notice]: Use Rossby-Haurwitz wave initial condition.'

    static%ghs(:,:) = 0.0

    do j = parallel%full_lat_start_idx, parallel%full_lat_end_idx
      cos_lat = mesh%full_cos_lat(j)
      sin_lat = mesh%full_sin_lat(j)
      do i = parallel%half_lon_start_idx, parallel%half_lon_end_idx
        lon = mesh%half_lon(i)
        a = cos_lat
        b = R * cos_lat**(R - 1) * sin_lat**2 * cos(R * lon)
        c = cos_lat**(R + 1) * cos(R * lon)
        state(1)%u(i,j) = radius * omg * (a + b - c)
      end do
    end do

    call parallel_fill_halo(state(1)%u, all_halo=.true.)

    do j = parallel%half_lat_start_idx, parallel%half_lat_end_idx
      cos_lat = mesh%half_cos_lat(j)
      sin_lat = mesh%half_sin_lat(j)
      do i = parallel%full_lon_start_idx, parallel%full_lon_end_idx
        lon = mesh%full_lon(i)
        a = R * cos_lat**(R - 1) * sin_lat * sin(R * lon)
        state(1)%v(i,j) = - radius * omg * a
      end do
    end do

    call parallel_fill_halo(state(1)%v, all_halo=.true.)

    do j = parallel%full_lat_start_idx, parallel%full_lat_end_idx
      cos_lat = mesh%full_cos_lat(j)
      a = 0.5 * omg * (2 * omega + omg) * cos_lat**2 + &
        0.25 * omg**2 * ((R + 1) * cos_lat**(2 * R + 2) + (2 * R**2 - R - 2) * cos_lat**(2 * R) - 2 * R**2 * cos_lat**(2 * R - 2))
      b = 2 * (omega + omg) * omg * cos_lat**R * &
        (R**2 + 2 * R + 2 - (R + 1)**2 * cos_lat**2) / (R + 1) / (R + 2)
      c = 0.25 * omg**2 * cos_lat**(2 * R) * ((R + 1) * cos_lat**2 - R - 2)
      do i = parallel%full_lon_start_idx, parallel%full_lon_end_idx
        lon = mesh%full_lon(i)
        state(1)%gd(i,j) = gd0 + radius**2 * (a + b * cos(R * lon) + c * cos(2 * R * lon))
      end do
    end do

    call parallel_fill_halo(state(1)%gd, all_halo=.true.)

  end subroutine rossby_haurwitz_wave_test_set_initial_condition

end module rossby_haurwitz_wave_test_mod
