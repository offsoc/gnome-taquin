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

[GtkTemplate (ui = "/org/gnome/Taquin/ui/base-headerbar.ui")]
private class BaseHeaderBar : NightTimeAwareHeaderBar, AdaptativeWidget
{
    [GtkChild (internal = true)] protected HeaderBar headerbar;
    [GtkChild] protected Box center_box;

    construct
    {
        BinLayout layout = new BinLayout ();
        set_layout_manager (layout);

        center_box.valign = Align.FILL;

        register_modes ();
    }

    /*\
    * * properties
    \*/

    private bool has_a_phone_size = false;
    protected bool disable_popovers = false;
    protected bool disable_action_bar = false;
    protected virtual void set_window_size (AdaptativeWidget.WindowSize new_size)
    {
        has_a_phone_size = AdaptativeWidget.WindowSize.is_phone_size (new_size);
        disable_popovers = has_a_phone_size
                        || AdaptativeWidget.WindowSize.is_extra_thin (new_size);

        bool _disable_action_bar = disable_popovers
                                || AdaptativeWidget.WindowSize.is_extra_flat (new_size);
        if (disable_action_bar != _disable_action_bar)
        {
            disable_action_bar = _disable_action_bar;
            if (disable_action_bar)
            {
                headerbar.set_show_title_buttons (false);
                quit_button_stack.show ();
                ltr_right_separator.visible = current_mode_id == default_mode_id;
            }
            else
            {
                ltr_right_separator.hide ();
                quit_button_stack.hide ();
                headerbar.set_show_title_buttons (true);
            }
        }

        update_hamburger_menu ();
    }

    /*\
    * * hamburger menu
    \*/

    [CCode (notify = false)] public string about_action_label     { internal get; protected construct; } // TODO add default = _("About");
    [CCode (notify = false)] public bool   has_help               { private  get; protected construct; default = false; }
    [CCode (notify = false)] public bool   has_keyboard_shortcuts { private  get; protected construct; default = false; }

    protected override void update_hamburger_menu ()
    {
        GLib.Menu menu = new GLib.Menu ();

/*        if (current_type == ViewType.OBJECT && !ModelUtils.is_folder_path (current_path))   // TODO a better way to copy various representations of a key name/value/path
        {
            Variant variant = new Variant.string (model.get_suggested_key_copy_text (current_path, browser_view.last_context_id));
            menu.append (_("Copy descriptor"), "app.copy(" + variant.print (false) + ")");
        }
        else if (current_type != ViewType.SEARCH) */

        populate_menu (ref menu);

        append_app_actions_section (ref menu);

        menu.freeze ();
        info_button.set_menu_model ((MenuModel) menu);
    }

    protected virtual void populate_menu (ref GLib.Menu menu) {}

    private void append_app_actions_section (ref GLib.Menu menu)    // FIXME mnemonics?
    {
        GLib.Menu section = new GLib.Menu ();
        append_or_not_night_mode_entry (ref section);
        append_or_not_keyboard_shortcuts_entry (has_keyboard_shortcuts, !has_a_phone_size, ref section);
        append_or_not_help_entry (has_help, ref section);
        append_about_entry (about_action_label, ref section);
        section.freeze ();
        menu.append_section (null, section);
    }

    private static inline void append_or_not_keyboard_shortcuts_entry (bool      has_keyboard_shortcuts,
                                                                       bool      show_keyboard_shortcuts,
                                                                   ref GLib.Menu section)
    {
        // TODO something in small windows
        if (!has_keyboard_shortcuts || !show_keyboard_shortcuts)
            return;

        /* Translators: usual menu entry of the hamburger menu (with a mnemonic that appears pressing Alt) */
        section.append (_("_Keyboard Shortcuts"), "win.show-help-overlay");
    }

    private static inline void append_or_not_help_entry (bool has_help, ref GLib.Menu section)
    {
        if (!has_help)
            return;

        /* Translators: usual menu entry of the hamburger menu (with a mnemonic that appears pressing Alt) */
        section.append (_("_Help"), "base.help");
    }

    private static inline void append_about_entry (string about_action_label, ref GLib.Menu section)
    {
        section.append (about_action_label, "base.about");
    }

    protected inline void hide_hamburger_menu ()
    {
        info_button.popdown ();
    }

    internal void toggle_hamburger_menu ()
    {
        if (!info_button.visible)
            toggle_view_menu ();
        else if (info_button.popover.visible)   // TODO hackish 1/2
            info_button.popdown ();
        else
            info_button.popup ();
    }
    protected virtual void toggle_view_menu () {}

    /*\
    * * modes
    \*/

    protected signal void change_mode (uint8 mode_id);

    private uint8 last_mode_id = 0; // 0 is default mode
    protected uint8 register_new_mode ()
    {
        return ++last_mode_id;
    }

    protected static bool is_not_requested_mode (uint8 mode_id, uint8 requested_mode_id, ref bool mode_is_active)
    {
        if (mode_id == requested_mode_id)
        {
            if (mode_is_active)
                assert_not_reached ();
            mode_is_active = true;
            return false;
        }
        else
        {
            mode_is_active = false;
            return true;
        }
    }

    private uint8 current_mode_id = default_mode_id;
    private void register_modes ()
    {
        register_default_mode ();
        register_about_mode ();

        this.change_mode.connect (update_current_mode_id);
    }
    private static void update_current_mode_id (BaseHeaderBar _this, uint8 requested_mode_id)
    {
        _this.current_mode_id = requested_mode_id;
    }

    /*\
    * * default widgets
    \*/

    [GtkChild] private   Button     go_back_button;
    [GtkChild] private   Separator  ltr_left_separator;
    [GtkChild] private   Label      title_label;
    [GtkChild] private   MenuButton info_button;
    [GtkChild] private   Separator  ltr_right_separator;

    [GtkChild] protected Stack      quit_button_stack;

    protected void set_default_widgets_states (string?  title_label_text_or_null,
                                               bool     show_go_back_button,
                                               bool     show_ltr_left_separator,
                                               bool     show_info_button,
                                               bool     show_ltr_right_separator,
                                               bool     show_quit_button_stack)
    {
        go_back_button.visible = show_go_back_button;
        ltr_left_separator.visible = show_ltr_left_separator;
        if (title_label_text_or_null == null)
        {
            title_label.set_label ("");
            title_label.hide ();
        }
        else
        {
            title_label.set_label ((!) title_label_text_or_null);
            title_label.show ();
        }
        info_button.visible = show_info_button;
        ltr_right_separator.visible = show_ltr_right_separator;
        quit_button_stack.visible = show_quit_button_stack;
    }

    /*\
    * * default mode
    \*/

    protected const uint8 default_mode_id = 0;
    private bool default_mode_on = true;
    protected bool no_in_window_mode { get { return default_mode_on; }}

    internal void show_default_view ()
    {
        change_mode (default_mode_id);
    }

    private void register_default_mode ()
    {
        this.change_mode.connect (mode_changed_default);
    }

    private static void mode_changed_default (BaseHeaderBar _this, uint8 requested_mode_id)
    {
        if (is_not_requested_mode (default_mode_id, requested_mode_id, ref _this.default_mode_on))
            return;

        _this.set_default_widgets_default_states (_this);
    }

    protected virtual void set_default_widgets_default_states (BaseHeaderBar _this)
    {
        _this.set_default_widgets_states (/* title_label text or null */ null,
                                          /* show go_back_button      */ false,
                                          /* show ltr_left_separator  */ false,
                                          /* show info_button         */ true,
                                          /* show ltr_right_separator */ _this.disable_action_bar,
                                          /* show quit_button_stack   */ _this.disable_action_bar);
    }

    /*\
    * * about mode
    \*/

    private uint8 about_mode_id = 0;
    private bool about_mode_on = false;

    internal void show_about_view ()
        requires (about_mode_id > 0)
    {
        change_mode (about_mode_id);
    }

    private void register_about_mode ()
    {
        about_mode_id = register_new_mode ();

        this.change_mode.connect (mode_changed_about);
    }

    private static void mode_changed_about (BaseHeaderBar _this, uint8 requested_mode_id)
        requires (_this.about_mode_id > 0)
    {
        if (is_not_requested_mode (_this.about_mode_id, requested_mode_id, ref _this.about_mode_on))
            return;

        /* Translators: on really small windows, the about dialog is replaced by an in-window view; here is the name of the view, displayed in the headerbar */
        _this.set_default_widgets_states (_("About"),   /* title_label text or null */
                                          true,         /* show go_back_button      */
                                          false,        /* show ltr_left_separator  */
                                          false,        /* show info_button         */
                                          false,        /* show ltr_right_separator */
                                          true);        /* show quit_button_stack   */
    }

    /*\
    * * popovers methods
    \*/

    internal virtual void close_popovers ()
    {
        hide_hamburger_menu ();
    }

    internal virtual bool has_popover ()
    {
        return info_button.popover.visible;     // TODO hackish 2/2
    }
}
