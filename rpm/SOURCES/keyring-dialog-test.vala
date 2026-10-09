using Gtk;
using Singularity.Keyring;

void collect (Widget widget, Gee.ArrayList<PasswordEntry> entries, Gee.ArrayList<Button> buttons) {
    if (widget is PasswordEntry) entries.add ((PasswordEntry) widget);
    if (widget is Button) buttons.add ((Button) widget);
    for (var child = widget.get_first_child (); child != null; child = child.get_next_sibling ())
        collect (child, entries, buttons);
}

void submit (Gtk.Application app, UnlockDialog.Mode mode, int trigger) {
    int calls = 0;
    uint initial_windows = Gtk.Window.get_toplevels ().get_n_items ();
    var dialog = new UnlockDialog (app);
    dialog.run (mode, (accepted, passphrase) => {
        assert (accepted && passphrase == "rpm-dialog-fixture");
        calls++;
    });
    var windows = Gtk.Window.get_toplevels ();
    var win = (Gtk.Window) windows.get_item (windows.get_n_items () - 1);
    var entries = new Gee.ArrayList<PasswordEntry> ();
    var buttons = new Gee.ArrayList<Button> ();
    collect (win, entries, buttons);
    assert (entries.size == (mode == UnlockDialog.Mode.CREATE ? 2 : 1));
    Button? ok = null;
    foreach (var button in buttons)
        if (button.label == (mode == UnlockDialog.Mode.CREATE ? "Create" : "Unlock")) ok = button;
    assert (ok != null);
    ok.clicked ();
    assert (calls == 0);
    entries[0].text = "rpm-dialog-fixture";
    if (entries.size == 2) {
        entries[1].text = "different";
        ok.clicked ();
        assert (calls == 0 && entries[1].text == "");
        entries[1].text = "rpm-dialog-fixture";
    }
    if (trigger == 0) ok.clicked ();
    else entries[trigger - 1].activate ();
    assert (calls == 1);
    assert (Gtk.Window.get_toplevels ().get_n_items () == initial_windows);
}

int main (string[] args) {
    Gtk.init ();
    var app = new Gtk.Application ("dev.sinty.rpm.KeyringDialogTest", GLib.ApplicationFlags.NON_UNIQUE);
    try { app.register (null); } catch (Error e) { error ("%s", e.message); }
    for (int trigger = 0; trigger < 3; trigger++) submit (app, UnlockDialog.Mode.CREATE, trigger);
    for (int trigger = 0; trigger < 2; trigger++) submit (app, UnlockDialog.Mode.UNLOCK, trigger);
    print ("Five native dialog signal paths passed, including empty and mismatched passphrase rejection\n");
    return 0;
}
