# Smart Grid Energy Optimization

## Overview
This project optimizes energy usage in a smart grid by balancing renewable energy sources, gas power, and battery storage. The goal is to minimize costs while meeting hourly energy demand.

## Technologies Used
- **Julia**: Main programming language
- **JuMP.jl**: Optimization framework
- **GLPK.jl**: Solver for linear programming
- **DataFrames.jl**: Data handling
- **Plots.jl**: Visualization

## Installation
Ensure you have Julia installed, then add the required packages:
```julia
using Pkg
Pkg.add(["JuMP", "GLPK", "DataFrames", "Plots"])
```

## Running the Project
Save the script as `smart_grid_optimization.jl` and run it in Julia:
```julia
include("smart_grid_optimization.jl")
```

## Project Breakdown
### 1. Data Preparation
- Defines 24-hour energy demand.
- Simulates renewable energy availability (solar and wind).
- Sets constraints for gas power and battery storage.

### 2. Optimization Model
- Uses linear programming to minimize costs.
- Ensures energy supply meets demand.
- Manages battery charge and discharge cycles.

### 3. Visualization
- Generates a plot comparing energy sources, demand, and battery status.
- Saves the visualization as `smart_grid_optimization.png`.

## Output
- Optimized energy allocation displayed in the console.
- Visual representation saved as `smart_grid_optimization.png`.
