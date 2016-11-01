import haxegon.*;

@:publicFields
class Button {
    var x: Float;
    var y: Float;
    var text: String;
    var width: Float;
    var height: Float;
    var text_width: Float;
    var text_height: Float;
    var function_pointer: Void->Void;
    var idle_color: Int;
    var selected_color: Int;

    public function new(x: Float, y: Float, text: String, function_pointer: Void->Void, idle_color: Int = null, selected_color: Int = null) {
        this.x = x;
        this.y = y;
        this.text = text;
        text_width = Text.width(text);
        text_height = Text.height();
        width = text_width * 1.1;
        height = text_height * 1.25;
        this.function_pointer = function_pointer;
        if (idle_color == null) {
            this.idle_color = Col.GRAY;
        } else {
            this.idle_color = idle_color;
        }
        if (selected_color == null) {
            this.selected_color = Col.PINK;
        } else {
            this.selected_color = idle_color;
        }
    }

    public function update_and_draw() {
        if (MathUtils.point_box_intersect(Mouse.x, Mouse.y, x, y, width, height)) {
            Gfx.fill_box(x, y, width, height, selected_color);
            if (Mouse.left_click()) {
                function_pointer();
            }
        } else {
            Gfx.fill_box(x, y, width, height, idle_color);
        }
        Text.display(x, y, text);
    }
}