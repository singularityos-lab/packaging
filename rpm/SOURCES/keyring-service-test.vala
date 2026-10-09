using GLib;
using Gtk;
using Singularity.Keyring;

PasswordEntry? find_entry (Widget widget) {
    if (widget is PasswordEntry) return (PasswordEntry) widget;
    for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ()) {
        var entry = find_entry (child);
        if (entry != null) return entry;
    }
    return null;
}

void answer (DBusConnection conn, string path, string passphrase) {
    var loop = new MainLoop ();
    uint timeout = Timeout.add_seconds (10, () => { error ("Prompt did not finish"); });
    conn.call.begin (conn.unique_name, path, "org.freedesktop.Secret.Prompt", "Prompt",
        new Variant ("(s)", ""), null, DBusCallFlags.NONE, 5000, null, (obj, res) => {
        try { conn.call.end (res); } catch (Error e) { error ("%s", e.message); }
        var windows = Gtk.Window.get_toplevels ();
        PasswordEntry? entry = null;
        for (uint i = 0; i < windows.get_n_items (); i++) {
            var window = (Gtk.Window) windows.get_item (i);
            if (window.title == "Unlock keyring") entry = find_entry (window);
        }
        assert (entry != null);
        entry.text = passphrase;
        entry.activate ();
        loop.quit ();
    });
    loop.run ();
    Source.remove (timeout);
}

string client (string[] command, string? input = null, bool expected_success = true) {
    var loop = new MainLoop ();
    string output = "";
    uint timeout = Timeout.add_seconds (15, () => { error ("Secret client did not finish"); });
    try {
        var process = new Subprocess.newv (command, SubprocessFlags.STDIN_PIPE | SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE);
        process.communicate_utf8_async.begin (input, null, (obj, res) => {
            string errors;
            try { process.communicate_utf8_async.end (res, out output, out errors); }
            catch (Error e) { error ("%s", e.message); }
            if (process.get_successful () != expected_success) error ("Secret client failed: %s", errors);
            loop.quit ();
        });
    } catch (Error e) { error ("%s", e.message); }
    loop.run ();
    Source.remove (timeout);
    return output.strip ();
}

int main (string[] args) {
    Gtk.init ();
    sk_crypto_init ();
    var app = new Gtk.Application ("dev.sinty.rpm.KeyringServiceTest", ApplicationFlags.NON_UNIQUE);
    try {
        app.register (null);
        var store = new Store ();
        assert (store.master.create ("valid-rpm-fixture"));
        var data = new CollectionData ();
        data.label = "RPM fixture";
        store.save ("login", data);
        store.master.purge ();
        assert (!store.master.try_unlock ("invalid-rpm-fixture"));
        assert (store.master.try_unlock ("valid-rpm-fixture"));
        store.master.purge ();
        var conn = Bus.get_sync (BusType.SESSION);
        var service = new SecretService (conn, app);
        conn.register_object ("/org/freedesktop/secrets", service);
        service.init ();
        ObjectPath[] objects = { (ObjectPath) "/org/freedesktop/secrets/collection/login" };
        ObjectPath[] unlocked;
        ObjectPath prompt;
        service.unlock (objects, out unlocked, out prompt);
        assert (unlocked.length == 0 && prompt != "/");
        answer (conn, prompt, "invalid-rpm-fixture");
        service.unlock (objects, out unlocked, out prompt);
        assert (unlocked.length == 0 && prompt != "/");
        answer (conn, prompt, "valid-rpm-fixture");
        service.unlock (objects, out unlocked, out prompt);
        print ("After correct prompt: unlocked=%d prompt=%s\n", unlocked.length, (string) prompt);
        assert (unlocked.length == 1 && unlocked[0] == objects[0] && prompt == "/");
        uint owned;
        var name = conn.call_sync ("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "RequestName",
            new Variant ("(su)", "org.freedesktop.secrets", 0u), new VariantType ("(u)"), DBusCallFlags.NONE, 5000, null);
        name.get ("(u)", out owned);
        assert (owned == 1);
        ObjectPath[] locked;
        service.lock (objects, out locked, out prompt);
        assert (locked.length == 1);
        bool answered = false;
        Timeout.add (50, () => {
            var windows = Gtk.Window.get_toplevels ();
            for (uint i = 0; i < windows.get_n_items (); i++) {
                var window = (Gtk.Window) windows.get_item (i);
                if (window.title != "Unlock keyring" || !window.visible) continue;
                var entry = find_entry (window);
                if (entry == null) continue;
                entry.text = "valid-rpm-fixture";
                entry.activate ();
                answered = true;
                return Source.REMOVE;
            }
            return Source.CONTINUE;
        });
        client ({ "secret-tool", "store", "--label", "RPM fixture", "singularity_rpm_test", "fixture" }, "rpm-client-fixture");
        assert (answered);
        assert (client ({ "secret-tool", "lookup", "singularity_rpm_test", "fixture" }) == "rpm-client-fixture");
        client ({ "secret-tool", "clear", "singularity_rpm_test", "fixture" });
        var properties = new HashTable<string, Variant> (str_hash, str_equal);
        properties["org.freedesktop.Secret.Collection.Label"] = new Variant.string ("secondary fixture");
        ObjectPath second;
        service.create_collection (properties, "verification", out second, out prompt);
        assert (prompt == "/" && service.read_alias ("verification") == second);
        assert (client ({ "gdbus", "call", "--session", "--dest", "org.freedesktop.secrets",
            "--object-path", "/org/freedesktop/secrets/aliases/verification", "--method",
            "org.freedesktop.DBus.Properties.Get", "org.freedesktop.Secret.Collection", "Locked" }).contains ("false"));
        client ({ "gdbus", "call", "--session", "--dest", "org.freedesktop.secrets",
            "--object-path", "/org/freedesktop/secrets/aliases/verification", "--method",
            "org.freedesktop.Secret.Collection.Delete" });
        assert (service.read_alias ("verification") == "/");
        client ({ "gdbus", "call", "--session", "--dest", "org.freedesktop.secrets",
            "--object-path", "/org/freedesktop/secrets/aliases/verification", "--method",
            "org.freedesktop.DBus.Properties.Get", "org.freedesktop.Secret.Collection", "Locked" }, null, false);
        service.set_alias ("verification", objects[0]);
        service.set_alias ("verification", (ObjectPath) "/");
        assert (service.read_alias ("verification") == "/");
        print ("Collection alias creation, removal and deletion passed\n");
        print ("Native libsecret client stored, read and deleted its isolated fixture\n");
        print ("Real D-Bus prompt rejected the wrong passphrase and accepted the correct passphrase\n");
    } catch (Error e) { error ("%s", e.message); }
    return 0;
}
