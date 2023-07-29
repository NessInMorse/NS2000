try
        using PlotlyJS
        using DataFrames
        using CSV
catch
        using Pkg
        Pkg.add("PlotlyJS")
        Pkg.add("DataFrames")
        Pkg.add("CSV")
        using PlotlyJS
        using DataFrames
        using CSV
end

function plot_xp(df)
        xp_bar_trace = PlotlyJS.bar(
                x = rownumber.(eachrow(df)),
                y = df[:, :cum_sum_xp],
                name = "Cumulative XP per day",
                marker_color = "#531eae"
        )
        xp_trace = PlotlyJS.scatter(
                x = rownumber.(eachrow(df)),
                y = df[:, :XP_sum],
                name = "Total XP per day",
                line_shape = "spline",
                line_color = "#ff9749"
        )
        combined_data = [xp_bar_trace, xp_trace]
        combined_layout = Layout(
                title = "XP per day learning Swedish words",
                barmode = "overlay",
                yaxis_title = "XP",
                xaxis_title = "Days training",
                yaxis_rangemode = "tozero"
        )
        p = plot(combined_data, combined_layout)
        savefig(p, "insight/xp.png")
        savefig(p, "insight/xp.html")
end

function plot_growth(compound_progress)
        bar_trace = PlotlyJS.bar(
                x = rownumber.(eachrow(compound_progress)),
                y = compound_progress.courses_sum_cum_maximum,
                name = "Total words learned in total"
        )
        maximum_x = [i ÷ 25 for i in 0:25:2000]
        line_trace = PlotlyJS.scatter(
                x = maximum_x,
                y = maximum_x .* 25,
                name = "Course per day trend")
        a1_trace = PlotlyJS.scatter(
                x = maximum_x,
                y = fill(300, length(maximum_x)),
                name = "A1 level active vocabulary")
        a2_trace = PlotlyJS.scatter(
                x = maximum_x,
                y = fill(600, length(maximum_x)),
                name = "A2 level active vocabulary")
        b1_trace = PlotlyJS.scatter(
                x = maximum_x,
                y = fill(1200, length(maximum_x)),
                name = "B1 level active vocabulary")
        
        combined_data = [bar_trace, line_trace, a1_trace, a2_trace, b1_trace]
        combined_layout = Layout(
                title = "Time to learn 2000 Swedish words using 80/20 Method",
                barmode = "overlay"
        )
        p = plot(combined_data, combined_layout)
        savefig(p, "insight/progress.png")
        savefig(p, "insight/progress.html")
        #=
        plot(compound_progress, 
             x = :date, 
             y = :courses_sum_cum_maximum, 
             kind = "bar")
        =# 
end

function plot_distribution(courses_count)
        x_bar = [i for i in eachindex(courses_count)]
        p = plot(bar(
                x = x_bar,
                y=courses_count, 
                name = "Distribution of learned courses"
        ))
        savefig(p, "insight/distribution.png")
        savefig(p, "insight/distribtion.html")
end

function openfile(filename)
        infile = open("$(filename)", "r")
        raw = [split(i, '\t') for i in readlines(infile)][2:end]
        close(infile)
        return raw
end

function main()
        progress = openfile("out/progress.tsv")
        raw_courses = [split(i[2], ',') .|> x -> parse(Int, x) for i in progress]
        courses_sum_cum::Vector{Int} = []
        all_unique_courses = Set([])
        for i in raw_courses
                for j in i
                        if !(j in all_unique_courses)
                                push!(all_unique_courses, j)
                        end
                end
                push!(courses_sum_cum, length(all_unique_courses))

        end


        progress_df = DataFrame(CSV.File("out/progress.tsv"))
        progress_df[!, :courses_sum_cum] = courses_sum_cum
        grouped_xp_df = combine(groupby(progress_df, :date), :XP => sum)
        grouped_xp_df.cum_sum_xp = cumsum(grouped_xp_df[!, :XP_sum])
        compound_progress = combine(groupby(progress_df, :date), :courses_sum_cum => maximum)
        compound_progress[!, :courses_sum_cum_maximum] = compound_progress[!, :courses_sum_cum_maximum] .* 25
        courses = reduce(vcat, [split(i[2], ',') .|> x -> parse(Int, x) for i in progress])
        courses_count::Vector{Int} = zeros(maximum(courses))
        for i in courses
                courses_count[i] += 1
        end
        plot_distribution(courses_count)
        plot_growth(compound_progress)
        plot_xp(grouped_xp_df)
end

main()