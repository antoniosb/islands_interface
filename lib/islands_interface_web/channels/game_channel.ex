defmodule IslandsInterface.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.Game

  def join("game:" <> _player, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("hello", payload, socket) do
    #    {:reply, {:ok, payload}, socket}
    #
    #    payload = %{message: "We forced this error."}
    #    {:reply, {:error, payload}, socket}
    #
    #    push(socket, "said_hello", payload)
    #    {:noreply, socket}
    broadcast!(socket, "said_hello", payload)
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
      :error -> {:reply, :error, socket}
    end
  end

  def handle_in("set_islands", player, socket) do
    player = String.to_existing_atom(player)
    case Game.set_islands(via(socket.topic), player) do
      :ok ->
        broadcast!(socket, "player_set_islands", %{player: player})
        {:noreply, socket}
      {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket}
      :error -> {:reply, :error, socket}
    end
  end

  defp via("game:" <> player), do: Game.via_tuple(player)
end

# Client code examples:
#
# var phoenix = require("phoenix")
#
# var socket = new phoenix.Socket("/socket", {})
#
# socket.connect()
#
# function new_channel(player, screen_name) {
#     return socket.channel("game:" + player, {screen_name: screen_name});
# }
#
# function join(channel) {
#     channel.join()
#     .receive("ok", response => {
#         console.log("Joined Successfully!", response)
#     })
#     .receive("error", response => {
#         console.log("Unable to join", response)
#     })
# }
#
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
