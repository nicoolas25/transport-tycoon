PlaceState = Struct.new(:place, :cargos, keyword_init: true)

CarrierState = Struct.new(:carrier, :type, :from_time, :to_time, :place, :cargo, keyword_init: true) do
  def available_space?
    cargo.nil?
  end

  def origin?
    place == carrier.origin
  end

  def cargo_destination?
    place == cargo&.destination
  end

  def destination
    cargo&.destination || carrier.origin
  end

  def stucked?(map:)
    return false unless (destination = cargo&.destination)

    !map.can_move?(carrier: carrier, from: place, to: destination)
  end
end

State = Struct.new(:time, :map, :place_states, :carrier_states, keyword_init: true) do
  def tick
    State.new(
      time: time + 1,
      map: map,
      place_states: place_states.dup,
      carrier_states: carrier_states.dup,
    )
  end

  def step
    next_state = State.new(
      time: time,
      map: map,
      place_states: place_states.dup,
      carrier_states: carrier_states.dup,
    )

    carrier_states.each do |carrier, carrier_state|
      next_state.move!(carrier_state: carrier_state, carrier: carrier)
    end

    next_state
  end

  protected

  def move!(carrier_state:, carrier:)
    return if time < carrier_state.to_time

    place_state = place_states.fetch(carrier_state.place)

    case carrier_state.type
    when :idle
      loadable_cargo = place_state.cargos.first

      if carrier_state.origin? &&
          carrier_state.available_space? &&
          loadable_cargo &&
          map.can_move?(carrier: carrier_state.carrier, from: carrier_state.place, to: loadable_cargo.destination)

        load!(carrier_state: carrier_state, place_state: place_state, cargo: loadable_cargo)

      elsif carrier_state.cargo_destination? || carrier_state.stucked?(map: map)
        unload!(carrier_state: carrier_state, place_state: place_state)

      elsif !carrier_state.origin?
        travels!(carrier_state: carrier_state)
      end

    when :loading, :unloading
      travels!(carrier_state: carrier_state)

    when :traveling
      end_travel!(carrier_state: carrier_state)

    else
      raise "Unsupported carrier state #{carrier_state.type}"
    end
  end

  def load!(carrier_state:, place_state:, cargo:)
    place_states[place_state.place] = PlaceState.new(
      place: place_state.place,
      cargos: place_state.cargos - [cargo],
    )

    carrier_states[carrier_state.carrier] = CarrierState.new(
      type: :loading,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time + carrier_state.carrier.loading_time,
      place: carrier_state.place,
      cargo: cargo,
    )
  end

  def travels!(carrier_state:)
    next_place, road = map.guidance(
      carrier: carrier_state.carrier,
      from: carrier_state.place,
      to: carrier_state.destination,
    )

    carrier_states[carrier_state.carrier] = CarrierState.new(
      type: :traveling,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time + road.distance,
      place: next_place,
      cargo: carrier_state.cargo,
    )
  end

  def unload!(carrier_state:, place_state:)
    unloadable_cargo = carrier_state.cargo

    place_states[place_state.place] = PlaceState.new(
      place: place_state.place,
      cargos: place_state.cargos + [unloadable_cargo],
    )

    carrier_states[carrier_state.carrier] = CarrierState.new(
      type: :unloading,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time + carrier_state.carrier.loading_time,
      place: carrier_state.place,
      cargo: nil,
    )
  end

  def end_travel!(carrier_state:)
    carrier_states[carrier_state.carrier] = CarrierState.new(
      type: :idle,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time,
      place: carrier_state.place,
      cargo: carrier_state.cargo,
    )
  end
end
