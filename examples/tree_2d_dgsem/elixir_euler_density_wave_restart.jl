using OrdinaryDiffEq
using Trixi

###############################################################################
# define time integration algorithm
alg = RDPK3SpFSAL49()

# create a restart file
trixi_include(@__MODULE__, joinpath(@__DIR__, "elixir_euler_density_wave_extended.jl"),
              tspan = (0.0, 1.0), alg = alg)

###############################################################################
# adapt the parameters that have changed compared to "elixir_euler_density_wave_extended.jl"

# Note: If you get a restart file from somewhere else, you need to provide
# appropriate setups in the elixir loading a restart file

restart_filename = joinpath("out", "restart_000200.h5")
mesh = load_mesh(restart_filename)

semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver)

tspan = (load_time(restart_filename), 2.0)
dt = load_dt(restart_filename)

ode = semidiscretize(semi, tspan, restart_filename);

# Do not overwrite the initial snapshot written by elixir_euler_density_wave_extended.jl.
save_solution.condition.save_initial_solution = false

integrator = init(ode, alg,
                  dt = dt;
                  save_everystep = false, callback = callbacks,
                  ode_default_options()...)
load_adaptive_time_integrator!(integrator, restart_filename)

# Get the last time index and work with that.
integrator.iter = load_timestep(restart_filename)
integrator.stats.naccept = integrator.iter

###############################################################################
# run the simulation

sol = solve!(integrator)

summary_callback() # print the timer summary