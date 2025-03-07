/* -*- Mode: vala; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-

   This file is part of a GNOME game.

   Copyright 2019 Arnaud Bonatti

   This game is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This game is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this game.  If not, see <https://www.gnu.org/licenses/>.
*/

using Gtk;

private class GameView : BaseView, AdaptativeWidget
{
    private Stack           game_stack;
    private Box             game_box_1;
    private Widget          game_content;
    private ScrolledWindow  scrolled;
    private Box             new_game_box;
    private Button?         start_game_button = null;

    construct
    {
        game_stack = new Stack ();
        game_stack.hexpand = true;
        game_stack.vexpand = true;
        main_box.append (game_stack);

        scrolled = new ScrolledWindow ();
        scrolled.visible = true;
        game_stack.add_child (scrolled);

        new_game_box = new Box (Orientation.VERTICAL, /* spacing */ 0);
        new_game_box.halign = Align.CENTER;
        new_game_box.valign = Align.CENTER;
        scrolled.set_child (new_game_box);
    }

    internal GameView (GameWindowFlags flags, Box new_game_screen, Widget content, GameActionBarPlaceHolder actionbar_placeholder)
    {
        new_game_box.append (new_game_screen);

        if (GameWindowFlags.SHOW_START_BUTTON in flags)
        {
            /* Translators: when configuring a new game, label of the blue Start button (with a mnemonic that appears pressing Alt) */
            Button _start_game_button = new Button.with_mnemonic (_("_Start Game"));
            _start_game_button.halign = Align.CENTER;
            _start_game_button.set_action_name ("ui.start-or-restart");

            StyleContext context = _start_game_button.get_style_context ();
            context.add_class ("start-game-button");
            context.add_class ("suggested-action");
            /* Translators: when configuring a new game, tooltip text of the blue Start button */
            // _start_game_button.set_tooltip_text (_("Start a new game as configured"));
            new_game_box.append (_start_game_button);
            start_game_button = _start_game_button;
        }

        game_content = content;

        game_box_1 = new Box (Orientation.VERTICAL, 0);
        game_content.hexpand = true;
        game_content.vexpand = true;

        // during a transition, Stack doesn’t apply correctly its child CSS padding or margin; so add padding/margin to a box inside a box
        Box game_box_2 = new Box (Orientation.HORIZONTAL, 0);
        game_box_2.get_style_context ().add_class ("game-box");
        game_box_2.append (game_content);

        game_box_1.append (game_box_2);
        game_box_1.append (actionbar_placeholder);

        // for the new-game-screen-to-game animation, it is probably better to have the game under ("uncovered")
//        game_box.insert_before (game_stack, game_stack.get_first_child ());
        game_stack.add_child (game_box_1);
        content.can_focus = true;
    }

    internal void show_new_game_box (bool grab_focus)
    {
        game_stack.set_visible_child (scrolled);
        if (grab_focus && start_game_button != null)
            ((!) start_game_button).grab_focus ();
        // TODO else if (grab_focus && start_game_button == null)
    }

    internal void show_game_content (bool grab_focus)
    {
        game_stack.set_visible_child (game_box_1);
        if (grab_focus)
            game_content.grab_focus ();
    }

    internal bool game_content_visible_if_true ()
    {
        Widget? visible_child = game_stack.get_visible_child ();
        if (visible_child == null)
            assert_not_reached ();
        return (!) visible_child == game_box_1;
    }

    internal void configure_transition (StackTransitionType transition_type,
                                        uint                transition_duration)
    {
        game_stack.set_transition_type (transition_type);
        game_stack.set_transition_duration (transition_duration);
    }
}
