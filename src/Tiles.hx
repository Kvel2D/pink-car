class Tiles {
    static inline var tileset_width = 10;
    static function tilenum(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    public static inline var Empty = 9999;
    public static inline var Ground = tilenum(0, 0);
    public static inline var Player = tilenum(1, 0);
    public static inline var Box = tilenum(2, 0);
    public static inline var TimeMachine = tilenum(0, 1);
    public static inline var Objective = tilenum(1, 1);
    public static inline var Teleport = tilenum(0, 6);

    public static inline var ArrowLeft = tilenum(3, 0);
    public static inline var ArrowRight = tilenum(4, 0);
    public static inline var ArrowUp = tilenum(5, 0);
    public static inline var ArrowDown = tilenum(6, 0);

    public static inline var RedArrowLeft = tilenum(3, 1);
    public static inline var RedArrowRight = tilenum(4, 1);
    public static inline var RedArrowUp = tilenum(5, 1);
    public static inline var RedArrowDown = tilenum(6, 1);

    public static inline var DoorClosedWhite = tilenum(0, 2);
    public static inline var DoorOpenWhite = tilenum(1, 2);
    public static inline var ButtonWhite = tilenum(0, 3);
    public static inline var DoorClosedBlack = tilenum(0, 4);
    public static inline var DoorOpenBlack = tilenum(1, 4);
    public static inline var ButtonBlack = tilenum(0, 5);

    public static inline var Reticle = tilenum(2, 1);
    public static inline var TimeTravelReticle = tilenum(2, 2);
}