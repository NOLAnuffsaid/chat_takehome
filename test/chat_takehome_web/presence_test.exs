defmodule ChatTakehomeWeb.PresenceTest do
  use ChatTakehomeWeb.ConnCase, async: true

  alias ChatTakehomeWeb.Presence

  test "tracks a process on a topic" do
    topic = "test:#{System.unique_integer([:positive])}"
    token = "session-token"

    assert {:ok, _ref} = Presence.track(self(), topic, token, %{})
    assert %{^token => %{metas: [%{}]}} = Presence.list(topic)

    assert :ok = Presence.untrack(self(), topic, token)
  end
end
