using Random
using Dates
using REPL.TerminalMenus

function filter_parentheses(word)
        if '(' in word
                ind = findfirst('(', word)
                return strip(word[begin:ind-1])
        else
                return strip(word)
        end
end


function write_mistakes(mistakes)
        #=
        Writes the mistakes made in the test to a file
        in:
                the made mistakes in sequence
        out:
                a file with all the mistakes in a TSV-file
        =#
        date = (time() |> unix2datetime |> string)[1:10]
        infile = open("out/mistakes.tsv", "a")
        println(infile, "$(date)\t$(join(mistakes, ','))")
        close(infile)
end

function write_results(courses, xp, accuracy, learn_time, source, used_modifiers)
        #=
        Writes the results of the text file to out/progress
        in:
                the courses that were completed
                the xp that is granted to the user
                the accruracy of which the test was completed
                the learn calculated learn time for the user
                the file were the words came from
                the modifiers that were used e.g. reversed mode
        out:
                a tsv file containing in the information that is put in
                including the date on which the test was taken on
        =#
        date = (time() |> unix2datetime |> string)[1:10]
        infile = open("out/progress.tsv", "a")
        println(infile, "$(date)\t$(join(courses, ','))\t$(accuracy)\t$(xp)\t$(learn_time)\t$(source)\t$(used_modifiers)")
        close(infile)
end

function word_test(known, target, word_sequence)
        #=
        Test all the words in the course that the user does not know yet
        in:
                the known words
                the target language to learn
                the (random) sequence of the words to learn
        out:
                all the mistakes that were made in sequence
                the total length that the test took (begin + length(mistakes))
        =#
        current = 1
        mistakes::Vector{String} = []
        while current != length(word_sequence) + 1
                println("$(known[word_sequence[current]]) $(current)/$(length(word_sequence))")
                answer = strip(readline())
                if answer != target[word_sequence[current]]
                        push!(word_sequence, word_sequence[current])
                        push!(mistakes, target[word_sequence[current]])
                        printstyled("$(target[word_sequence[current]]) ❌\n", color=:red)
                else   
                        printstyled("$(target[word_sequence[current]]) ✔️\n", color=:green)
                end
                println("-" ^ 15)
                current += 1
        end
        printstyled("All mistakes:\n$(Set(mistakes))\n", color=:red)
        return mistakes, (current-1) 
end

function print_course(course_indices)
        #=
        Prints the courses that the user will be tested on with
                a nice purple color
        in:
                the indices of the courses
        out:
                nothing
        =#
        println("-" ^ 15)
        for i in course_indices
                printstyled("Course $(i): Words $(1+(i-1)*25)-$(i * 25)\n", color=:magenta)
        end
        println("-" ^ 15)
end

function choose_random_course(course::Vector{Vector{String}}, count)
        #=
        Chooses <count> random courses out of the courses 2D Vector
        in:
                a 2D Vector containing all the words in the courses
                the count of the random courses to be chosen
        out:
                all the courses with their words to be tested
        =#
        course_numbers = [i for i in eachindex(course)]
        testing_courses = sort(shuffle(course_numbers)[1:count])
        return testing_courses
end

function open_courses(filename::String)
        #=
        Opens the newline delimited data file
        in:
                a filename
        out:
                A 2D list containing all words per course delimited by newlines
        =#
        infile = open(filename)
        items = [[]]
        for i in eachline(infile)
                if i == ""
                        push!(items, [])
                else
                        push!(items[end], i)
                end
        end
        close(infile)
        return items
end

function return_used_modifiers(indices, names)
        used_modifiers = [names[i] for i in indices]
        if length(used_modifiers) == 0
                return "Normal"
        else
                return join(used_modifiers, ';')
        end
end

function multiple_options_menu(options)
        sources = MultiSelectMenu(options)
        ans = request("Choose out of the following options (Multiple are possible): ", sources)
        return sort([i for i in ans])
end


function option_menu(options)
        sources = RadioMenu(options)
        ans = request("Pick the source for the courses:, ", sources)
        return options[ans]
end

function create_test(REPETITION)
        source_options = readdir("words/")
        source::String = option_menu(source_options)
        known::Vector{Vector{String}} = open_courses("words/$(source)/known.txt")
        target::Vector{Vector{String}} = open_courses("words/$(source)/target.txt")

        println("Choose whether you want to perform a special mode:")
        special_modes = ["Reversed"]
        modifiers = multiple_options_menu(special_modes)
        if 1 in modifiers
                temp = copy(known)
                known = copy(target)
                target = copy(temp)
                empty!(temp)
        end
        target = [filter_parentheses.(i) for i in target]
        used_modifiers = return_used_modifiers(modifiers, special_modes)

        println("Choose a course")
        course_names = ["Course $(i)" for i in eachindex(known)]
        course_indices = multiple_options_menu(course_names)
        if !iszero(course_indices)
                course_count = length(course_indices)
                course_length = sum([length(known[i]) for i in course_indices])
        else
                course_count = 2
                course_indices = choose_random_course(known, course_count)
                course_length = sum([length(known[i]) for i in course_indices])
        end

        word_sequence = shuffle([i for i in 1:(course_length)
                                   for _ in 1:REPETITION])
        known_words = reduce(vcat, [known[i] for i in course_indices])
        target_words = reduce(vcat, [target[i] for i in course_indices]) 
        print_course(course_indices)
        return word_sequence, known_words, target_words, course_length, course_indices, source, used_modifiers
end

function main()
        course_length::Int = 0
        REPETITION::Int = 2
        word_sequence, known_words, target_words, course_length, course_indices, source, used_modifiers = create_test(REPETITION)
        mistakes, total_tests = word_test(known_words, target_words, word_sequence)
        xp = course_length * REPETITION
        accuracy = round(xp / total_tests, digits=3)
        learn_time = xp * 5
        write_results(course_indices, xp, accuracy, learn_time, source, used_modifiers)
        write_mistakes(mistakes)
end

main()