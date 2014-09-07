
function initialize_population{T <: FloatingPoint}(spec::GenocopSpec{T})
    if spec.starting_population_type == single_point_start_pop
        return initialize_population_single_point(spec)
    else
        return initialize_population_multipoint(spec)
    end
end

function initialize_population_single_point{T <: FloatingPoint}(spec::GenocopSpec{T})
    @debug "beginning to initialize single point population"

    individual = get_feasible_individual(spec)
    if individual == nothing
        @error "No feasible individual was found in $_population_initialization_tries tries. \
                You can try again with starting point specified in the GenocopSpec"
        error("no feasible individual found")
    end

    return Individual{T}[individual for i=1:spec.population_size]
end

function initialize_population_multipoint{T <: FloatingPoint}(spec::GenocopSpec{T})
    @debug "beginning to initialize multi point population"

    population = Array(Individual{T}, spec.population_size)
    for i=1:spec.population_size
        individual = get_feasible_individual(spec)
        if individual == nothing
            @error "No feasible individual was found in $_population_initialization_tries tries. \
                    Before this failure we generated successfully $i individuals. \
                    You can try again with starting point specified in the GenocopSpec"
            error("no feasible individual found")
        end

        population[i] = individual
    end
    return population
end

function get_feasible_individual{T <: FloatingPoint}(spec::GenocopSpec{T})

    for i = 1:_population_initialization_tries

        random_individual = get_random_individual_within_bounds(spec)

        if is_feasible(random_individual, spec)
            return random_individual
        end
    end

    return nothing
end

function get_random_individual_within_bounds{T <: FloatingPoint}(spec::GenocopSpec{T})
    chromosome = Array(T, spec.no_of_variables)
    for i in 1:spec.no_of_variables
        low = spec.lower_bounds[i]
        upp = spec.upper_bounds[i]
        chromosome[i] = get_random_float(low, upp)
    end

    @debug "generated a random individual: $chromosome"
    return Individual(chromosome)
end

function is_feasible{T <: FloatingPoint}(individual::Individual{T}, spec::GenocopSpec{T})
    ineq = spec.inequalities
    ineq_right = spec.inequalities_right
    chromosome = individual.chromosome
    for i in 1:size(ineq, 1)
        value = evaluate_row(ineq, chromosome, i)

        if value > ineq_right[i]
            return false
        end
    end
    return true
end