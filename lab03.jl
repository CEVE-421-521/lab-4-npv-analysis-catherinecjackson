
using CSV
using DataFrames
using DataFramesMeta
using Distributions
using Interpolations
using Plots
using StatsPlots
using Unitful

Plots.default(; margin=6Plots.mm)
include("depthdamage.jl")
haz_fl_dept = CSV.read("data/haz_fl_dept.csv", DataFrame);
demo_row = @rsubset(
    haz_fl_dept, :Description == "two story, no basement, Structure", :Occupancy == "RES1", :Source == "USACE - Galveston", :DmgFnId == 140
)[
    1, :,
]
dd = DepthDamageData(demo_row);
fieldnames(typeof(dd));

scatter(
    dd.depths,
    dd.damages;
    xlabel="Flood Depth at House",
    ylabel="Damage (%)",
    label="$(dd.description) ($(dd.source))",
    legend=:bottomright,
    size=(700, 500),
)

function get_depth_damage_function(
    depth_train::Vector{<:T}, dmg_train::Vector{<:AbstractFloat}
) where {T<:Unitful.Length}

    # interpolate
    depth_ft = ustrip.(u"ft", depth_train)
    interp_fn = Interpolations.LinearInterpolation(
        depth_ft, # <1>
        dmg_train;
        extrapolation_bc=Interpolations.Flat(), # <2>
    )

    damage_fn = function (depth::T2) where {T2<:Unitful.Length}
        return interp_fn(ustrip.(u"ft", depth)) # <3>
    end
    return damage_fn # <4>
end

global damage_fn = get_depth_damage_function(dd.depths, dd.damages);

p = let
    depths = uconvert.(u"ft", (-7.0u"ft"):(1.0u"inch"):(30.0u"ft")) # <1>
    damages = damage_fn.(depths) # <2>
    scatter(
        depths,
        damages;
        xlabel="Flood Depth",
        ylabel="Damage (%)",
        label="$(dd.description) ($(dd.source))",
        legend=:bottomright,
        size=(800, 400),
        linewidth=2,
    )
end
p

gauge_dist = GeneralizedExtremeValue(5, 1.5, 0.1)
p1 = plot(
    gauge_dist;
    label="Gauge Distribution",
    xlabel="Water Level (ft)",
    ylabel="Probability Density",
    legend=:topright,
    linewidth=2,
)
offset = 4.3;
house_dist = GeneralizedExtremeValue(gauge_dist.μ - offset, gauge_dist.σ, gauge_dist.ξ);
plot!(p1, house_dist; label="House Distribution", linewidth=2) 

plot()
samplesrand = rand(house_dist, 100)
h1 = histogram!(samplesrand; label="House Distribution", alpha=0.5, normed=true, size=(800, 400), title="House Flood Distribution 100 Samples")
plot()
samplesrand10000 = rand(house_dist, 1000)
h2 = histogram(samplesrand10000; label="House Distribution", alpha=0.5, normed=true, size=(800, 400), title="House Flood Distribution 1000 Samples")
plot()
samplesrand100000 = rand(house_dist, 10000)
h3 = histogram(samplesrand100000; label="House Distribution", alpha=0.5, normed=true, size=(800, 400), title="House Flood Distribution 10000 Samples")

plot(h1, h2, h3, layout=(1, 3), size=(800, 400), titlefontsize=8)

n_samples = 1_000_000;
vecsamples = rand(house_dist, n_samples);
vecsamples = vecsamples .* u"ft"
damages = damage_fn.(vecsamples);
expecteddamages = mean(damages)

emp = scatter()
x_values = Int[]
y_values = Float64[]

for i = 1:100
    n_samples = 1_000_000
    vecsamples = rand(house_dist, n_samples)
    vecsamples = vecsamples .* u"ft"
    damages = damage_fn.(vecsamples)
    expecteddamages = mean(damages)
    push!(x_values, i)
    push!(y_values, expecteddamages)
end

emp = scatter!(emp, x_values, y_values; label="Expected Damage", markersize=2, ylims=(15, 25))
emp

emp = scatter()
x_values = Int[]
y_values = Float64[]

for i = 1:100
    n_samples = 100
    vecsamples = rand(house_dist, n_samples)
    vecsamples = vecsamples .* u"ft"
    damages = damage_fn.(vecsamples)
    expecteddamages = mean(damages)
    push!(x_values, i)
    push!(y_values, expecteddamages)
end

emp = scatter!(emp, x_values, y_values; label="Expected Damage", markersize=2, ylims=(10, 30))
emp

gauge_dist = GeneralizedExtremeValue(5, 1.5, 0.1)
p1 = plot(
    gauge_dist;
    label="Gauge Distribution",
    xlabel="Water Level (ft)",
    ylabel="Probability Density",
    legend=:topright,
    linewidth=2,
)
offset = 5.3;
house_dist = GeneralizedExtremeValue(gauge_dist.μ - offset, gauge_dist.σ, gauge_dist.ξ)
plot!(p1, house_dist; label="House Distribution", linewidth=2) 

n_samples = 1_000_000
vecsamples = rand(house_dist, n_samples);
vecsamples = vecsamples .* u"ft"
damages = damage_fn.(vecsamples);
fexpecteddamages = mean(damages)


display(house_dist)
display(fexpecteddamages)