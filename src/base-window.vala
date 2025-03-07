/*
  This file is part of GNOME Taquin

  GNOME Taquin is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  GNOME Taquin is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with GNOME Taquin.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

private interface BaseApplication : Gtk.Application
{
    internal abstract void copy (string text);

    // same as about dialog; skipped: wrap_license, license, license_type (forced at GPL v3+ == License.GPL_3_0), logo
    internal abstract void get_about_dialog_infos (out string [] artists,
                                                   out string [] authors,
                                                   out string    comments,
                                                   out string    copyright,
                                                   out string [] documenters,
                                                   out string    logo_icon_name,
                                                   out string    program_name,
                                                   out string    translator_credits,
                                                   out string    version,
                                                   out string    website,
                                                   out string    website_label);
}

[GtkTemplate (ui = "/org/gnome/Taquin/ui/base-window.ui")]
private class BaseWindow : AdaptativeWindow, AdaptativeWidget
{
    private BaseView main_view;
    [CCode (notify = false)] public BaseView base_view
    {
        protected get { return main_view; }
        protected construct
        {
            BaseView? _value = value;
            if (_value == null)
                assert_not_reached ();

            main_view = value;
            value.vexpand = true;
            value.visible = true;
            add_to_main_grid (value);
        }
    }

    private BaseHeaderBar headerbar;

    construct
    {
        headerbar = (BaseHeaderBar) nta_headerbar;

        init_keyboard ();

        install_action_entries ();

        add_adaptative_child (headerbar);
        add_adaptative_child (main_view);
        add_adaptative_child (this);
    }

    /*\
    * * main layout
    \*/

    [GtkChild] private Box main_box;
    [GtkChild] private Button unfullscreen_button;
    [GtkChild] private Overlay main_overlay;

    protected void add_to_main_overlay (Widget widget)
    {
        main_overlay.add_overlay (widget);
    }

    protected void add_to_main_grid (Widget widget)
    {
        main_box.append (widget);
    }

    protected override void on_fullscreen ()
    {
        unfullscreen_button.show ();
    }

    protected override void on_unfullscreen ()
    {
        unfullscreen_button.hide ();
    }

    /*\
    * * action entries
    \*/

    protected SimpleAction escape_action;

    private void install_action_entries ()
    {
        SimpleActionGroup action_group = new SimpleActionGroup ();
        action_group.add_action_entries (action_entries, this);
        insert_action_group ("base", action_group);

        GLib.Action? tmp_action = action_group.lookup_action ("escape");
        if (tmp_action == null)
            assert_not_reached ();
        escape_action = (SimpleAction) (!) tmp_action;
        escape_action.set_enabled (false);
    }

    private const GLib.ActionEntry [] action_entries =
    {
        { "copy",               copy                },  // <P>c
        { "copy-alt",           copy_alt            },  // <P>C

        { "paste",              paste               },  // <P>v
        { "paste-alt",          paste_alt           },  // <P>V

        { "escape",             _escape_pressed     },  // Escape
        { "toggle-hamburger",   toggle_hamburger    },  // F10
        { "menu",               menu_pressed        },  // Menu

        { "show-default-view",  show_default_view   },

        { "help",               help                },
        { "about",              about               },

        { "unfullscreen",       unfullscreen        }
    };

    /*\
    * * keyboard copy actions
    \*/

    protected virtual bool handle_copy_text (out string copy_text)
    {
        return main_view.handle_copy_text (out copy_text);
    }
    protected virtual bool get_alt_copy_text (out string copy_text)
    {
        return no_copy_text (out copy_text);
    }
    internal static bool no_copy_text (out string copy_text)
    {
        copy_text = "";
        return false;
    }
    internal static bool copy_clipboard_text (out string copy_text)
    {
//        string? nullable_selection = Clipboard.@get (Gdk.SELECTION_PRIMARY).wait_for_text ();
//        if (nullable_selection != null)
//        {
//             string selection = ((!) nullable_selection).dup ();
//             if (selection != "")
//             {
//                copy_text = selection;
//                return true;
//             }
//        }
        return no_copy_text (out copy_text);
    }
    internal static inline bool is_empty_text (string text)
    {
        return text == "";
    }

    private void copy (/* SimpleAction action, Variant? path_variant */)
    {
//        Widget? focus = get_focus ();
//        if (focus != null)
//        {
//            if ((!) focus is Editable)  // GtkEntry, GtkSearchEntry, GtkSpinButton
//            {
//                int garbage1, garbage2;
//                if (((Editable) (!) focus).get_selection_bounds (out garbage1, out garbage2))
//                {
//                    ((Editable) (!) focus).copy_clipboard ();
//                    return;
//                }
//            }
//            else if ((!) focus is TextView)
//            {
//                if (((TextView) (!) focus).get_buffer ().get_has_selection ())
//                {
//                    ((TextView) (!) focus).copy_clipboard ();
//                    return;
//                }
//            }
//            else if ((!) focus is Label)
//            {
//                int garbage1, garbage2;
//                if (((Label) (!) focus).get_selection_bounds (out garbage1, out garbage2))
//                {
//                    ((Label) (!) focus).copy_clipboard ();
//                    return;
//                }
//            }
//        }

//        main_view.close_popovers ();

//        string text;
//        if (handle_copy_text (out text))
//            copy_text (text);
    }

    private void copy_alt (/* SimpleAction action, Variant? path_variant */)
    {
        if (main_view.is_in_in_window_mode ())        // TODO better
            return;

        main_view.close_popovers ();

        string text;
        if (get_alt_copy_text (out text))
            copy_text (text);
    }

    private inline void copy_text (string text)
        requires (!is_empty_text (text))
    {
        ((BaseApplication) get_application ()).copy ((!) text);
    }

    /*\
    * * keyboard paste actions
    \*/

    protected virtual void paste_text (string? text) {}

    private void paste (/* SimpleAction action, Variant? variant */)
    {
        if (main_view.is_in_in_window_mode ())
            return;

        Widget? focus = get_focus ();
        if (focus != null)
        {
//            if ((!) focus is Entry)
//            {
//                ((Entry) (!) focus).paste_clipboard ();
//                return;
//            }
            if ((!) focus is TextView)
            {
                ((TextView) (!) focus).paste_clipboard ();
                return;
            }
        }

        paste_clipboard_content ();
    }

    private void paste_alt (/* SimpleAction action, Variant? variant */)
    {
        close_in_window_panels ();

        paste_clipboard_content ();
    }

    private void paste_clipboard_content ()
    {
        Gdk.Display? display = Gdk.Display.get_default ();
        if (display == null)    // ?
            return;

        string? clipboard_content;
        if (get_clipboard_content (out clipboard_content))
            paste_text (clipboard_content);
    }

    private static inline bool get_clipboard_content (out string? clipboard_content)
    {
//        Gdk.Display? display = Gdk.Display.get_default ();
//        if (display == null)            // ?
//        {
//            clipboard_content = null;   // garbage
//            return false;
//        }

//        clipboard_content = Clipboard.get_default ((!) display).wait_for_text ();
        return true;
    }

    /*\
    * * keyboard open menus actions
    \*/

    private void toggle_hamburger (/* SimpleAction action, Variant? variant */)
    {
        headerbar.toggle_hamburger_menu ();
        main_view.close_popovers ();
    }

    protected virtual void menu_pressed (/* SimpleAction action, Variant? variant */)
    {
        headerbar.toggle_hamburger_menu ();
        main_view.close_popovers ();
    }

    /*\
    * * keyboard user actions
    \*/

    private Gtk.EventControllerKey key_controller;    // for keeping in memory

    private void init_keyboard ()  // called on construct
    {
        key_controller = new Gtk.EventControllerKey ();
        key_controller.key_pressed.connect (on_key_pressed);
        ((Widget) this).add_controller (key_controller);
    }

    protected inline bool on_key_pressed (Gtk.EventControllerKey _key_controller, uint keyval, uint keycode, Gdk.ModifierType state)
    {
        return _on_key_press_event (keyval, state);
    }
    private bool _on_key_press_event (uint keyval, Gdk.ModifierType state)
    {
        string name = (!) (Gdk.keyval_name (keyval) ?? "");

        if (name == "F1") // TODO fix dance done with the F1 & <Control>F1 shortcuts that show help overlay
        {
            headerbar.close_popovers ();
            main_view.close_popovers ();
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0)
                return false;                           // help overlay
            if ((state & Gdk.ModifierType.SHIFT_MASK) == 0)
                return show_application_help (this, help_string_or_empty);   // fallback on help overlay (TODO test)
            about ();
            return true;
        }

        return false;
    }

    /*\
    * * help
    \*/

    [CCode (notify = false)] public string help_string_or_empty { private get; protected construct; default = ""; }

    private void help (/* SimpleAction action, Variant? variant */)
    {
        show_application_help (this, help_string_or_empty);
    }

    private static inline bool show_application_help (BaseWindow _this, string help_string_or_empty)
    {
        if (help_string_or_empty == "")
            return false;

        bool success;
        try
        {
//            show_uri_on_window (_this, help_string_or_empty, get_current_event_time ());
            success = true;
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
            success = false;
        }
        return success;
    }

    /*\
    * * adaptative stuff
    \*/

    private bool disable_popovers = false;
    protected virtual void set_window_size (AdaptativeWidget.WindowSize new_size)
    {
        bool _disable_popovers = AdaptativeWidget.WindowSize.is_phone_size (new_size)
                              || AdaptativeWidget.WindowSize.is_extra_thin (new_size);
        if (disable_popovers != _disable_popovers)
        {
            disable_popovers = _disable_popovers;
            if (in_window_about)
                show_default_view ();
        }
    }

    /*\
    * * in-window panels
    \*/

    protected virtual void close_in_window_panels ()
    {
        hide_notification ();
        headerbar.close_popovers ();
        if (in_window_about)
            show_default_view ();
    }

    private void _escape_pressed (/* SimpleAction action, Variant? path_variant */)
    {
        escape_pressed ();  // returns true if something is done
    }
    protected virtual bool escape_pressed ()
    {
        if (in_window_about)
        {
            show_default_view ();
            return true;
        }
        return false;
    }

    protected virtual void show_default_view (/* SimpleAction action, Variant? path_variant */)
    {
        if (in_window_about)
        {
            in_window_about = false;
            escape_action.set_enabled (escape_action_enabled);
            headerbar.show_default_view ();
            main_view.show_default_view ();
        }
        else
            assert_not_reached ();
    }

    /*\
    * * about dialog
    \*/

    private AboutDialog about_dialog;
    private Gtk.EventControllerKey about_dialog_key_controller;    // for keeping in memory

    private void show_about_dialog ()
    {
        if (should_init_about_dialog)
        {
            create_about_dialog ();
            about_dialog.response.connect ((_about_dialog, response) => _about_dialog.hide ());
            about_dialog_key_controller = new Gtk.EventControllerKey ();
            about_dialog_key_controller.key_pressed.connect (on_about_dialog_key_pressed);
            ((Widget) about_dialog).add_controller (about_dialog_key_controller);
            about_dialog.set_transient_for (this);
            should_init_about_dialog = false;
        }
        about_dialog.present ();
    }
    private inline bool on_about_dialog_key_pressed (Gtk.EventControllerKey _about_dialog_key_controller, uint keyval, uint keycode, Gdk.ModifierType state)
    {
        if (((!) (Gdk.keyval_name (keyval) ?? "") == "F1")
         && ((state & Gdk.ModifierType.SHIFT_MASK) != 0))
        {
            about_dialog.response (ResponseType.CANCEL);
            return true;
        }
        return false;
    }

    private bool should_init_about_dialog = true;
    private void create_about_dialog ()
    {
        string [] artists, authors, documenters;
        string comments, copyright, logo_icon_name, program_name, translator_credits, version, website, website_label;

        ((BaseApplication) get_application ()).get_about_dialog_infos (out artists, out authors, out comments, out copyright, out documenters, out logo_icon_name, out program_name, out translator_credits, out version, out website, out website_label);

        about_dialog = new AboutDialog ();
        about_dialog.set_title (headerbar.about_action_label);
        about_dialog.set_wrap_license (true);
        about_dialog.set_license_type (License.GPL_3_0);    // forced, 1/3
        if (artists.length > 0)         about_dialog.set_artists            (artists);
        if (authors.length > 0)         about_dialog.set_authors            (authors);
        if (comments != "")             about_dialog.set_comments           (comments);
        if (copyright != "")            about_dialog.set_copyright          (copyright);
        if (documenters.length > 0)     about_dialog.set_documenters        (documenters);
        if (logo_icon_name != "")       about_dialog.set_logo_icon_name     (logo_icon_name);
        if (program_name != "")         about_dialog.set_program_name       (program_name);         else assert_not_reached ();
        if (translator_credits != "")   about_dialog.set_translator_credits (translator_credits);
        if (version != "")              about_dialog.set_version            (version);
        if (website != "")              about_dialog.set_website            (website);
        if (website_label != "")        about_dialog.set_website_label      (website_label);
    }

    /*\
    * * in-window about
    \*/

    private void about (/* SimpleAction action, Variant? path_variant */)
    {
        if (disable_popovers)
            toggle_in_window_about ();
        else
            show_about_dialog ();
    }

    [CCode (notify = false)] protected bool in_window_about { protected get; private set; default = false; }

    private void toggle_in_window_about ()
    {
        if (should_init_in_window_about)
        {
            init_in_window_about ();
            should_init_in_window_about = false;
            show_about_view ();
        }
        else if (in_window_about)
            show_default_view ();
        else
            show_about_view ();
    }

    private bool should_init_in_window_about = true;
    private void init_in_window_about ()
    {
        string [] artists, authors, documenters;
        string comments, copyright, logo_icon_name, program_name, translator_credits, version, website, website_label;

        ((BaseApplication) get_application ()).get_about_dialog_infos (out artists, out authors, out comments, out copyright, out documenters, out logo_icon_name, out program_name, out translator_credits, out version, out website, out website_label);

        main_view.create_about_list                                   (ref artists, ref authors, ref comments, ref copyright, ref documenters, ref logo_icon_name, ref program_name, ref translator_credits, ref version, ref website, ref website_label);
    }

    private bool escape_action_enabled = false;
    private inline void show_about_view ()
        requires (in_window_about == false)
    {
        close_in_window_panels ();

        escape_action_enabled = escape_action.enabled;
        escape_action.set_enabled (true);
        in_window_about = true;
        headerbar.show_about_view ();
        main_view.show_about_view ();
        set_focus_visible (false);  // about-list grabs focus
    }

    /*\
    * * notifications
    \*/

    internal void show_notification (string notification)
    {
        main_view.show_notification (notification);
    }

    protected void hide_notification ()
    {
        main_view.hide_notification ();
    }
}
