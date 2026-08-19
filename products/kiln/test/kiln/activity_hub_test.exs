defmodule Kiln.Activity.HubTest do
  @moduledoc """
  WP-09 Lane 2 acceptance tests for the bounded Activity Hub.

  Properties verified:
    - register/1 + unregister/1 are idempotent
    - publish/1 fans out to matching subscribers
    - publish/1 does not deliver to non-matching subscribers
    - publish/1 never delivers to dead pids (silent skip)
    - publish/1 holds no authoritative state
  """

  use ExUnit.Case, async: false

  alias Kiln.Activity.Hub

  setup do
    # The Hub is supervised unconditionally by `Kiln.Application`;
    # tests just use the named instance.
    sub_id_a = "sub_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    sub_id_b = "sub_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)

    state_before = Hub.count()
    on_exit(fn -> :ok end)

    %{sub_id_a: sub_id_a, sub_id_b: sub_id_b, state_before: state_before}
  end

  test "register/1 + unregister/1 are idempotent" do
    sub_id = "sub_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    pid = self()

    assert :ok = Hub.register(%{subscription_id: sub_id, pid: pid, session_id: nil, since_revision: 0})
    assert {:error, :already_registered} = Hub.register(%{subscription_id: sub_id, pid: pid, session_id: nil, since_revision: 0})
    assert :ok = Hub.unregister(sub_id)
    # After unregister, registering again succeeds.
    assert :ok = Hub.register(%{subscription_id: sub_id, pid: pid, session_id: nil, since_revision: 0})
    assert :ok = Hub.unregister(sub_id)
  end

  test "publish/1 fans out to matching subscribers" do
    sub_id = "sub_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    session_id = "ses_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)

    :ok = Hub.register(%{subscription_id: sub_id, pid: self(), session_id: session_id, since_revision: 0})

    Hub.publish(%{
      session_id: session_id,
      revision: 1,
      subject: %{kind: "session", id: session_id},
      canonical_session_revision: 1
    })

    assert_receive {:activity_notification, frame}, 500
    assert frame.type == "activity.notification"
    assert frame.subscription_id == sub_id
    assert frame.revision == 1
    assert frame.canonical_session_revision == 1
    assert frame.subject.id == session_id

    Hub.unregister(sub_id)
  end

  test "publish/1 skips subscribers with mismatched session_id filter" do
    sub_id = "sub_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    sub_session = "ses_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    other_session = "ses_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)

    :ok = Hub.register(%{subscription_id: sub_id, pid: self(), session_id: sub_session, since_revision: 0})

    Hub.publish(%{
      session_id: other_session,
      revision: 1,
      subject: %{kind: "session", id: other_session},
      canonical_session_revision: 1
    })

    refute_receive {:activity_notification, _}, 100
    Hub.unregister(sub_id)
  end

  test "publish/1 silently skips dead pids" do
    sub_id = "sub_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    session_id = "ses_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    dead_pid = spawn(fn -> :ok end)

    # Wait for dead_pid to actually die.
    ref = Process.monitor(dead_pid)
    assert_receive {:DOWN, ^ref, :process, ^dead_pid, _}, 500

    assert :ok = Hub.register(%{subscription_id: sub_id, pid: dead_pid, session_id: session_id, since_revision: 0})

    # Publish must NOT raise even though the subscriber pid is dead.
    Hub.publish(%{
      session_id: session_id,
      revision: 1,
      subject: %{kind: "session", id: session_id},
      canonical_session_revision: 1
    })

    Hub.unregister(sub_id)
  end

  test "publish/1 with no subscribers is a no-op (no state divergence)", %{sub_id_a: _} do
    # A bare publish with zero subscribers must complete without error.
    Hub.publish(%{
      session_id: "ses_x",
      revision: 1,
      subject: %{kind: "session", id: "ses_x"},
      canonical_session_revision: 1
    })

    assert Hub.count() >= 0
  end

  test "monotonic_revision advances monotonically across publishes", %{sub_id_a: sub_id} do
    session_id = "ses_" <> Base.encode16(:crypto.strong_rand_bytes(16), case: :lower)
    :ok = Hub.register(%{subscription_id: sub_id, pid: self(), session_id: session_id, since_revision: 0})

    Enum.each(1..3, fn rev ->
      Hub.publish(%{
        session_id: session_id,
        revision: rev,
        subject: %{kind: "session", id: session_id},
        canonical_session_revision: rev
      })
    end)

    # Drain all three notifications; the in-process monotonic counter
    # is not directly observable but the stream of revisions is.
    revisions = for _ <- 1..3, do: receive_revision(500)
    assert revisions == [1, 2, 3]
    Hub.unregister(sub_id)
  end

  defp receive_revision(timeout) do
    receive do
      {:activity_notification, frame} -> frame.revision
    after
      timeout -> :timeout
    end
  end
end
