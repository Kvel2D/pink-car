import haxegon.*;

enum State {
    State_Game;
}


@:publicFields
class Main {
    static inline var screen_width = 381;
    static inline var screen_height = 321;
    static var state = State_Game;
    static var game: Game;

    function new() {
        Text.setfont("pixelFJ8", 8);
        #if flash
        Gfx.resize_screen(screen_width, screen_height, 1);
        #else
        Gfx.resize_screen(screen_width, screen_height);
        #end

        game = new Game();
    }

    function update() {
        switch (state) {
            case State_Game: game.update();
        }
    }
}
