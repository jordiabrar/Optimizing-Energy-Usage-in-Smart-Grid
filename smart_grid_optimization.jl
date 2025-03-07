############################################################
# Optimasi Penggunaan Energi dalam Smart Grid
#
# Proyek ini mengoptimalkan alokasi pembangkitan energi 
# selama 24 jam pada smart grid dengan sumber:
# - Solar (energi terbarukan, tersedia saat siang hari)
# - Wind (energi terbarukan, tersedia dengan variasi)
# - Gas (pembangkit dengan biaya, bersifat dispatchable)
# - Battery (penyimpanan energi)
#
# Tujuan: Meminimalkan biaya pembangkitan (hanya gas yang diberi biaya)
# dengan memenuhi permintaan energi setiap jam serta mengelola baterai.
############################################################

using JuMP
using GLPK
using DataFrames
using Plots

# Waktu: 24 jam
T = 24
time = 1:T

# Data permintaan energi (MW) untuk setiap jam (data sintetis)
demand = [50, 45, 40, 38, 35, 30, 28, 32, 40, 55, 65, 75, 80, 78, 70, 65, 60, 55, 50, 48, 45, 50, 55, 60]

# Kapasitas pembangkitan terbarukan (MW)
# Solar: hanya tersedia saat siang hari
solar_availability = [0, 0, 0, 0, 0, 5, 10, 20, 30, 40, 45, 50, 55, 50, 45, 30, 20, 10, 5, 0, 0, 0, 0, 0]
# Wind: ketersediaan sedikit bervariasi sepanjang hari
wind_availability = [10, 12, 15, 13, 12, 10, 8, 7, 10, 12, 15, 17, 16, 15, 14, 13, 12, 11, 10, 9, 10, 11, 12, 13]

# Parameter pembangkit gas
gas_capacity = 100      # Kapasitas maksimal (MW)
gas_cost = 50           # Biaya pembangkitan ($ per MWh)

# Parameter baterai
battery_capacity = 50         # Kapasitas baterai maksimum (MWh)
battery_initial_soc = 25      # State-of-charge awal (MWh)
battery_charge_rate = 20      # Batas maksimum pengisian (MW)
battery_discharge_rate = 20   # Batas maksimum pengosongan (MW)
battery_efficiency = 0.95     # Efisiensi baterai (asumsi round-trip sama)

# Buat model optimasi menggunakan GLPK sebagai solver
model = Model(GLPK.Optimizer)

# Variabel keputusan:
# Pembangkitan dari masing-masing sumber (MW) untuk setiap jam
@variable(model, 0 <= solar[t=1:T] <= solar_availability[t])
@variable(model, 0 <= wind[t=1:T] <= wind_availability[t])
@variable(model, 0 <= gas[t=1:T] <= gas_capacity)

# Variabel untuk baterai:
# charge[t]: daya pengisian (MW)
# discharge[t]: daya pengosongan (MW)
# soc[t]: state-of-charge (MWh)
@variable(model, 0 <= charge[t=1:T] <= battery_charge_rate)
@variable(model, 0 <= discharge[t=1:T] <= battery_discharge_rate)
@variable(model, 0 <= soc[t=1:T] <= battery_capacity)

# Constraint keseimbangan energi:
# Untuk setiap jam, total energi yang dihasilkan (plus discharge dan dikurangi pengisian) harus memenuhi permintaan.
for t in 1:T
    @constraint(model, solar[t] + wind[t] + gas[t] + discharge[t] - charge[t] == demand[t])
end

# Dynamika baterai (state-of-charge):
# Untuk t = 1: soc[1] = soc awal + (pengisian × efisiensi) - (pengosongan / efisiensi)
@constraint(model, soc[1] == battery_initial_soc + battery_efficiency * charge[1] - discharge[1] / battery_efficiency)
for t in 2:T
    @constraint(model, soc[t] == soc[t-1] + battery_efficiency * charge[t] - discharge[t] / battery_efficiency)
end

# Constraint siklus baterai: agar kondisi akhir sama dengan awal
@constraint(model, soc[T] == battery_initial_soc)

# Objective: Minimalkan total biaya pembangkitan energi
# Hanya pembangkitan gas yang dikenakan biaya.
@objective(model, Min, sum(gas_cost * gas[t] for t in 1:T))

# Solusi optimasi
optimize!(model)

# Cek status solver
termination_status = JuMP.termination_status(model)
if termination_status == MOI.OPTIMAL
    println("Solusi optimal ditemukan!")
else
    println("Solver selesai dengan status: ", termination_status)
end

# Ambil hasil solusi
solar_sol = value.(solar)
wind_sol = value.(wind)
gas_sol = value.(gas)
charge_sol = value.(charge)
discharge_sol = value.(discharge)
soc_sol = value.(soc)

# Tampilkan hasil ringkasan
println("\nJam\tDemand\tSolar\tWind\tGas\tCharge\tDischarge\tSOC")
for t in 1:T
    println("$(t)\t$(round(demand[t], digits=2))\t$(round(solar_sol[t], digits=2))\t$(round(wind_sol[t], digits=2))\t$(round(gas_sol[t], digits=2))\t$(round(charge_sol[t], digits=2))\t$(round(discharge_sol[t], digits=2))\t$(round(soc_sol[t], digits=2))")
end

# Visualisasi hasil optimasi
plot(time, demand, label="Demand", lw=2, marker=:o)
plot!(time, solar_sol, label="Solar Generation", lw=2, marker=:o)
plot!(time, wind_sol, label="Wind Generation", lw=2, marker=:o)
plot!(time, gas_sol, label="Gas Generation", lw=2, marker=:o)
plot!(time, charge_sol, label="Battery Charge", lw=2, marker=:o)
plot!(time, discharge_sol, label="Battery Discharge", lw=2, marker=:o)
plot!(time, soc_sol, label="Battery SOC", lw=2, marker=:o)
xlabel!("Time (Hour)")
ylabel!("Power / Energy (MW / MWh)")
title!("Smart Grid Energy Optimization")
savefig("smart_grid_optimization.png")
println("\nPlot telah disimpan sebagai 'smart_grid_optimization.png'.")
