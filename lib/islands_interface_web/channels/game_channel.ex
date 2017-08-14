defmodule IslandsInterface.GameChannel do
  use IslandsInterfaceWeb, :channel

  alias IslandsEngine.Game

  def join("game:" <> _player, _payload, socket) do
    {:ok, socket}
  end
end
