PlaceState = Struct.new(:place, :cargos, keyword_init: true)

CarrierState = Struct.new(:carrier, :type, :from_time, :to_time, :place, :cargos, keyword_init: true) do
  def available_space
    carrier.capacity - cargos.size
  end

  def origin?
    place == carrier.origin
  end

  def cargo_destination?
    place == cargos.first&.destination
  end

  def destination
    cargos.first&.destination || carrier.origin
  end

  def stucked?(map:)
    return false unless (destination = cargos.first&.destination)

    !map.can_move?(carrier: carrier, from: place, to: destination)
  end
end

State = Struct.new(:time, :map, :place_states, :carrier_states, :events, keyword_init: true) do
  def tick
    State.new(
      time: time + 1,
      map: map,
      place_states: place_states.dup,
      carrier_states: carrier_states.dup,
      events: events.dup,
    )
  end

  def step
    next_state = State.new(
      time: time,
      map: map,
      place_states: place_states.dup,
      carrier_states: carrier_states.dup,
      events: events.dup,
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
      loadable_cargos = place_state.cargos.first(carrier_state.available_space)

      if carrier_state.origin? &&
          loadable_cargos.any? &&
          map.can_move?(carrier: carrier_state.carrier, from: carrier_state.place, to: loadable_cargos.first.destination)

        load!(carrier_state: carrier_state, place_state: place_state, cargos: loadable_cargos)

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

  def load!(carrier_state:, place_state:, cargos:)
    place_states[place_state.place] = PlaceState.new(
      place: place_state.place,
      cargos: place_state.cargos - cargos,
    )

    carrier_states[carrier_state.carrier] = new_carrier_state = CarrierState.new(
      type: :loading,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time + carrier_state.carrier.loading_time,
      place: carrier_state.place,
      cargos: cargos,
    )

    events << Event.new(name: "LOAD", carrier_state: new_carrier_state)
  end

  def travels!(carrier_state:)
    next_place, road = map.guidance(
      carrier: carrier_state.carrier,
      from: carrier_state.place,
      to: carrier_state.destination,
    )

    carrier_states[carrier_state.carrier] = new_carrier_state = CarrierState.new(
      type: :traveling,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time + road.distance,
      place: next_place,
      cargos: carrier_state.cargos,
    )

    events << Event.new(name: "DEPART", carrier_state: new_carrier_state, location: carrier_state.place)
  end

  def unload!(carrier_state:, place_state:)
    unloadable_cargos = carrier_state.cargos

    place_states[place_state.place] = PlaceState.new(
      place: place_state.place,
      cargos: place_state.cargos + unloadable_cargos,
    )

    carrier_states[carrier_state.carrier] = new_carrier_state = CarrierState.new(
      type: :unloading,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time + carrier_state.carrier.loading_time,
      place: carrier_state.place,
      cargos: [],
    )

    events << Event.new(name: "UNLOAD", carrier_state: new_carrier_state, cargos: unloadable_cargos)
  end

  def end_travel!(carrier_state:)
    carrier_states[carrier_state.carrier] = new_carrier_state = CarrierState.new(
      type: :idle,
      carrier: carrier_state.carrier,
      from_time: time,
      to_time: time,
      place: carrier_state.place,
      cargos: carrier_state.cargos,
    )

    events << Event.new(name: "ARRIVE", carrier_state: new_carrier_state)
  end
end
