defmodule IslandsInterface.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.Game
  alias IslandsInterfaceWeb.Presence

  def join("game:" <> _player, %{"screen_name" => screen_name}, socket) do
    if authorized?(socket, screen_name) do
      send(self(), {:after_join, screen_name})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:after_join, screen_name}, socket) do
    {:ok, _} = Presence.track(socket, screen_name, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  def handle_in("show_subscribers", _payload, socket) do
    broadcast!(socket, "subscribers", Presence.list(socket))
    {:noreply, socket}
  end

  def handle_in("new_game", _payload, socket) do
    "game:" <> player = socket.topic
    case Game.start_link(player) do
      {:ok, _pid} -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("add_player", player, socket) do
    case Game.add_player(via(socket.topic), player) do
      :ok ->
        broadcast!(socket, "player_added", %{message: "New player just joined: " <> player})
        {:noreply, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("position_island", payload, socket) do
    %{"player" => player, "island" => island, "row" => row, "col" => col} = payload
    player = String.to_existing_atom(player)
    island = String.to_existing_atom(island)
    case Game.position_island(via(socket.topic), player, island, row, col) do
      :ok -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("set_islands", player, socket) do
    player = String.to_existing_atom(player)
    case Game.set_islands(via(socket.topic), player) do
      :ok ->
        broadcast!(socket, "player_set_islands", %{player: player})
        {:noreply, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  def handle_in("guess_coordinate", params, socket) do
    %{"player" => player, "row" => row, "col" => col} = params
    player = String.to_existing_atom(player)
    case Game.guess_coordinate(via(socket.topic), player, row, col) do
      {:hit, island, win} ->
        result = %{hit: true, island: island, win: win}
        broadcast!(socket, "player_guessed_coordinate", %{player: player, result: result})
        {:noreply, socket}
      {:miss, island, win} ->
        result = %{hit: false, island: island, win: win}
        broadcast!(socket, "player_guessed_coordinate", %{player: player, result: result})
        {:noreply, socket}
      {:error, reason} ->
        {:reply, {:error, %{player: player, reason: inspect(reason)}}, socket}
    end
  end

  defp via("game:" <> player), do: Game.via_tuple(player)

  defp number_of_players(socket) do
    socket
    |> Presence.list()
    |> Map.keys()
    |> length()
  end

  defp existing_player?(socket, screen_name) do
    socket
    |> Presence.list()
    |> Map.has_key?(screen_name)
  end

  defp authorized?(socket, screen_name) do
    number_of_players(socket) < 2 && !existing_player?(socket, screen_name)
  end
end

# Client code examples:

# var phoenix = require("phoenix")

# var socket = new phoenix.Socket("/socket", {})

# socket.connect()

# function new_channel(player, screen_name) {
#     return socket.channel("game:" + player, {screen_name: screen_name});
# }

# function join(channel) {
#     channel.join()
#     .receive("ok", response => {
#         console.log("Joined Successfully!", response)
#     })
#     .receive("error", response => {
#         console.log("Unable to join", response)
#     })
# }

# game_channel.on("subscribers", response => {
#   console.log("These players have joined: ", response)
# })

# function leave(channel) {
#     channel.leave()
#     .receive("ok", response => { console.log("Left Successfully!", response)})
#     .receive("error", response => { console.log("Unable to Leave", response)})
# }
#
# function say_hello(channel, greeting) {
#     channel.push("hello", {"message": greeting})
#     .receive("ok", response => { console.log("Hello", response.message)})
#     .receive("error", response => { console.log("Unable to say hello to the channel.", response.message)})
# }
#
# var game_channel = new_channel("moon", "diva")
#
# join(game_channel)
#
# game_channel.on("said_hello", response => {
#     console.log("Returned Greeting", response.message)
# })
#
# function new_game(channel) {
#     channel.push("new_game")
#     .receive("ok", response => {
#         console.log("New Game!", response)
#     })
#     .receive("error", response => {
#         console.log("Unable to start a new game.", response)
#     })
# }
#
# function add_player(channel, player) {
#       channel.push("add_player", player)
#   .receive("error", response => {
#             console.log("Unable to add new player: " + player, response)
#
#   })
#
# }
#
# function position_island(channel, player, island, row, col) {
#     var params = {"player": player, "island": island, "row": row, "col": col}
#     channel.push("position_island", params)
#     .receive("ok", response => { console.log("Island positioned!", response)})
#     .receive("error", response => { console.log("Unable to position island.")})
# }
#
# function set_islands(channel, player) {
#   channel.push("set_islands", player)
#   .receive("error", response => {
#     console.log("Unable to set islands for: " + player, response)
#   })
# }
#
# game_channel.on("player_set_islands", response => {
#   console.log("Player Set Islands", response)
# })
#
# function guess_coordinate(channel, player, row, col) {
#   var params = {"player": player, "row": row, "col": col}
#   channel.push("guess_coordinate", params)
#   .receive("error", response => {
#     console.log("Unable to guess a coordinate: " + player, response)
#   })
# }
#
# game_channel.on("player_guessed_coordinate", response => {
#   console.log("Player Guessed Coordinate: ", response.result)
# })

