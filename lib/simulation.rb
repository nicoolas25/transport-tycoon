class Simulation
  attr_reader :state

  def initialize(state:)
    @state = state
  end

  def step
    previous_state = nil
    next_state = @state

    if state.time == 0
      while previous_state != next_state
        previous_state = next_state
        next_state = previous_state.step
      end
    end

    previous_state = next_state
    next_state = next_state.tick

    while previous_state != next_state
      previous_state = next_state
      next_state = previous_state.step
    end

    Simulation.new(state: next_state)
  end

  def all_cargo_delivered?
    state.carrier_states.values.all? { |carrier_state| carrier_state.cargos.empty? } &&
      state.place_states.all? { |place, place_state| place_state.cargos.all? { |cargo| place == cargo.destination } }
  end
end
