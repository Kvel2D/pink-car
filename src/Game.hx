import haxegon.*;
import haxegon.MathUtils.Vector2;

enum GameState {
    GameState_Normal;
}

typedef Road = {
    x1:Float,
    y1:Float,
    x2:Float,
    y2:Float,
    length:Float,
    angle:Float,
    previous:Road,
    nexts:Array<Road>,
}

typedef Cloud = {
    x:Float,
    y:Float,
    tilenum:Int,
}

@:publicFields
class Game {
    static inline var key_delay = 5;
    static inline var player_speed = 5;

    // fake screen dimensions for road spacing 
    static var w = 640 * 0.7;
    static var h = 360 * 0.7;
    static var r = Math.sqrt(w * w + h * h);
    static var viewport_radius = Math.sqrt(Main.screen_width * Main.screen_width + Main.screen_height * Main.screen_height);

    var state = GameState_Normal;

    var player: Vector2 = {x: 0, y: -400};
    var bad: Vector2 = {x: 0, y: 0};
    var roads = new Array<Road>();
    var current_road:Road;

    var blips_done = [false, false, false];
    var left_to_right = true;
    var moving = false;

    var next_road = 0;
    var correct_next_road = 0;
    var correct_next_road_bin = bin(0);
    var current_progress = 0;
    var turn_counter = 0;
    var restart_next_turn = false;

    var clouds = new Array<Cloud>();
    var cloud_width = 0;
    var cloud_radius = 0.0;
    var cloud_dx = 0.0;
    var cloud_dy = 0.0;

    var fade = 1.0;
    var fade_color = Col.WHITE;
    var fade_started = false;
    var fade_start = 0.1;

    var cloud_w = Main.screen_width;
    var cloud_h = Main.screen_height;
    var cloud_timer = 0;
    var cloud_timer_max = 1;

    static inline var bad_timer_max = 900.0;
    static inline var bad_speed = 1.0;
    var bad_timer = 0.0;
    

    function new() {
        Gfx.load_image("bad");
        Gfx.load_tiles("clouds", 300, 300);
        Gfx.load_tiles("car_anim", 20, 40);
        Gfx.define_animation("car_move", "car_anim", 0, 2, 3);
        Gfx.line_thickness = 20;
        Music.load_sound("blip");
        Music.load_sound("whoosh");

        Gfx.change_tileset("clouds");
        cloud_width = Gfx.tile_width();
        cloud_radius = Math.sqrt(cloud_width * cloud_width * 2);


        restart();
    }

    function restart() {
        roads.splice(0, roads.length);
        first_fork();
        current_road = roads[0];
        current_progress = Std.int(current_road.length * 0.6);
        correct_next_road = 0;
        next_road = Random.int(0, 1);
        blips_done = [false, false, false];
        turn_counter = 0;
        fade_started = false;
        restart_next_turn = false;
        left_to_right = true;
        bad_timer = 0;

        clouds.splice(0, clouds.length);
        cloud_dx = Random.pick_int(-1, 1) * 1;
        cloud_dy = Random.pick_int(-1, 1) * 0.5;

        for (i in 0...5) {
            var cloud = {
                x: Random.pick_int(-1, 1) * Random.float(0, cloud_w / 2 + cloud_radius) + Gfx.screen_width / 2,
                y: Random.pick_int(-1, 1) * Random.float(0, cloud_h / 2 + cloud_radius) + Gfx.screen_height / 2,
                tilenum: Random.int(0, 8),
            }
            clouds.push(cloud);
        }
    }

    static function bin(x: Int): Array<Int> {
        switch (x) {
            case 0: return [0, 0, 0];
            case 1: return [1, 0, 0];
            case 2: return [0, 1, 0];
            case 3: return [1, 1, 0];
            case 4: return [0, 0, 1];
            case 5: return [1, 0, 1];
            case 6: return [0, 1, 1];
            case 7: return [1, 1, 1];
            default: return [0, 0, 0];
        }
    }

    function first_fork() {
        current_road = make_road(300, -900, null);
        two_road_fork(current_road);
    }

    static var angle_between_min = 45;
    static var angle_between_max = 90;
    static var tilt_max = 15;
    static var length_max = r / Math.sin(MathUtils.deg_to_rad(angle_between_min) / 2);

    function two_road_fork(start:Road) {
        var previous_angle = MathUtils.sign(start.angle) * (180 - Math.abs(start.angle));
        var angle_between = Random.int(angle_between_min, angle_between_max);
        var length_min = r / Math.sin(MathUtils.deg_to_rad(angle_between) / 2);
        var length = Random.float(length_min, length_max);
        var dx = Math.sin(MathUtils.deg_to_rad(angle_between / 2)) * length;
        var dy = Math.cos(MathUtils.deg_to_rad(angle_between / 2)) * length;

        var angle = previous_angle + Random.float(-tilt_max, tilt_max);
        var d1 = MathUtils.rotate_point(dx, -dy, angle);
        var d2 = MathUtils.rotate_point(-dx, -dy, angle);
        var r1 = make_road(d1.x, d1.y, start);
        var r2 = make_road(d2.x, d2.y, start);
    }

    function three_road_fork(start:Road) {
        var previous_angle = MathUtils.sign(start.angle) * (180 - Math.abs(start.angle));
        var angle_between = Random.int(angle_between_min, angle_between_max);
        var length_min = r / Math.sin(MathUtils.deg_to_rad(angle_between) / 2);
        var length = Random.float(length_min, length_max);
        var dx = Math.sin(MathUtils.deg_to_rad(angle_between / 2)) * length;
        var dy = Math.cos(MathUtils.deg_to_rad(angle_between / 2)) * length;

        var angle = previous_angle + Random.float(-tilt_max, tilt_max);
        var angle3 = angle + Random.float(-angle_between / 4, angle_between / 4);
        var d1 = MathUtils.rotate_point(dx, -dy, angle);
        var d2 = MathUtils.rotate_point(-dx, -dy, angle);
        var d3 = MathUtils.rotate_point(0, -length, angle3);
        var r1 = make_road(d1.x, d1.y, start);
        var r2 = make_road(d2.x, d2.y, start);
        var r3 = make_road(d3.x, d3.y, start);
    }

    function four_road_fork(start:Road) {
        var previous_angle = MathUtils.sign(start.angle) * (180 - Math.abs(start.angle));
        var angle_between = Random.int(angle_between_min, angle_between_max);
        var length_min = r / Math.sin(MathUtils.deg_to_rad(angle_between) / 2);
        var length = Random.float(length_min, length_max);
        var dx = Math.sin(MathUtils.deg_to_rad(angle_between / 2)) * length;
        var dy = Math.cos(MathUtils.deg_to_rad(angle_between / 2)) * length;

        var angle = previous_angle + Random.float(-tilt_max, tilt_max);
        var angle34 = angle + Random.float(angle_between / 8, angle_between / 4);
        var d1 = MathUtils.rotate_point(dx, -dy, angle);
        var d2 = MathUtils.rotate_point(-dx, -dy, angle);
        var d3 = MathUtils.rotate_point(0, -length, -angle34);
        var d4 = MathUtils.rotate_point(0, -length, angle34);
        var r1 = make_road(d1.x, d1.y, start);
        var r2 = make_road(d2.x, d2.y, start);
        var r3 = make_road(d3.x, d3.y, start);
        var r4 = make_road(d4.x, d4.y, start);
    }

    function eight_road_fork(start:Road) {
        var angle_between = 120;
        var previous_angle = MathUtils.sign(start.angle) * (180 - Math.abs(start.angle));
        var length_min = r / Math.sin(MathUtils.deg_to_rad(angle_between) / 2);
        var length = Random.float(length_min, length_max);
        for (i in 0...8) {
            var d = MathUtils.rotate_point(0, -length, previous_angle - angle_between / 2 + i * angle_between / 8);
            make_road(d.x, d.y, start);
        }
    }

    function make_road(dx:Float, dy:Float, previous:Road):Road {
        var x1 = 0.0;
        var y1 = 0.0;
        var x2 = dx;
        var y2 = dy;
        if (previous != null) {
            x1 += previous.x2;
            y1 += previous.y2;
            x2 += previous.x2;
            y2 += previous.y2;
        }

        var road:Road = {
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            length: MathUtils.dst(x1, y1, x2, y2),
            angle: MathUtils.rad_to_deg(Math.atan2(x2 - x1, y2 - y1)) % 360,
            previous: previous,
            nexts: new Array<Road>(),
        };

        if (previous != null) {
            previous.nexts.push(road);
            previous.nexts.sort(function(r1, r2) {
                // Sort nexts in a clockwise fanning direction
                var r1_angle = (180 - r1.angle + r1.previous.angle) % 360;
                var r2_angle = (180 - r2.angle + r2.previous.angle) % 360;
                if (r1_angle < 0) {
                    r1_angle += 360;
                }
                if (r2_angle < 0) {
                    r2_angle += 360;
                }
                if (r1_angle < r2_angle) {
                    return -1;
                } else if (r1_angle > r2_angle) {
                    return 1;
                } else {
                    return 0;
                }
            });
        }

        roads.push(road);

        return road;
    }

    function screenx(x:Float):Float {
        return x - player.x + Gfx.screen_width / 2;
    }

    function screeny(y:Float):Float {
        return y - player.y + Gfx.screen_height / 2;
    }

    function update_normal() {
        var progress = current_progress / current_road.length;
        player.x = current_road.x1 + (current_road.x2 - current_road.x1) * progress;
        player.y = current_road.y1 + (current_road.y2 - current_road.y1) * progress;

        if (left_to_right) {
            if (Input.delay_pressed(Key.LEFT, 10)) {
                next_road--;
                if (next_road < 0) {
                    next_road = 0;
                }
            } else if (Input.delay_pressed(Key.RIGHT, 10)) {
                next_road++;
                if (next_road > current_road.nexts.length - 1) {
                    next_road = current_road.nexts.length - 1;
                }
            }
        } else {
            if (Input.delay_pressed(Key.LEFT, 10)) {
                next_road++;
                if (next_road > current_road.nexts.length - 1) {
                    next_road = current_road.nexts.length - 1;
                }
            } else if (Input.delay_pressed(Key.RIGHT, 10)) {
                next_road--;
                if (next_road < 0) {
                    next_road = 0;
                }
            }
        }

        bad_timer += bad_speed;
        if (bad_timer > bad_timer_max) {
            // bad gameover
            bad_timer = bad_timer_max;
            if (!fade_started) {
                fade_started = true;
                Music.play_sound("whoosh");
                fade_color = Col.BLACK;
            }
            fade += 0.01;
            if (fade > 1) {
                fade = 1;
                restart();
                return;
            }
        }

        moving = false;
        if (Input.pressed(Key.UP)) {
            moving = true;
            current_progress += player_speed;

            bad_timer -= 3;
            if (bad_timer < 0) {
                bad_timer = 0;
            }
        }

        var bad_distance = bad_timer_max - bad_timer;
        var road_with_bad = current_road;
        var bad_progress: Float;
        // bad on the same road as player
        if (bad_distance > current_progress && road_with_bad.previous != null) {
            bad_distance -= current_progress;
            road_with_bad = road_with_bad.previous;
            bad_progress = 1 - bad_distance / road_with_bad.length;
        } else {
            bad_progress = (current_progress - bad_distance) / road_with_bad.length;
        }
        bad.x = road_with_bad.x1 + (road_with_bad.x2 - road_with_bad.x1) * bad_progress;
        bad.y = road_with_bad.y1 + (road_with_bad.y2 - road_with_bad.y1) * bad_progress;

        for (cloud in clouds) {
            if (moving) {
                cloud.x -= Math.abs(cloud_dx) * Math.cos(MathUtils.deg_to_rad(current_road.angle - 90));
                cloud.y += Math.abs(cloud_dy) * Math.sin(MathUtils.deg_to_rad(current_road.angle - 90));
            }
            cloud.x += cloud_dx;
            cloud.y += cloud_dy;

            if (Math.abs(cloud.x) > cloud_w / 2 + cloud_radius * 1.5 || Math.abs(cloud.y) > cloud_h / 2 + cloud_radius * 1.5) {
                cloud.x = -MathUtils.sign(cloud_dx) * Random.float(cloud_w / 2, cloud_w / 2 + cloud_radius) + Gfx.screen_width / 2;
                cloud.y = -MathUtils.sign(cloud_dy) * Random.float(cloud_h / 2, cloud_h / 2 + cloud_radius) + Gfx.screen_height / 2;
                cloud.tilenum = Random.int(0, 8);
            }
        }

        var progress = current_progress / current_road.length;
        if (turn_counter == 0) {
            if (progress > 0.4 && !blips_done[0]) {
                // Blip the first time to determine the rule
                blips_done[0] = true;
                Music.play_sound("blip");
            }
        } else if (!restart_next_turn) {
            // After that, blip based on the rule
            if (progress > 0.4 && !blips_done[0]) {
                blips_done[0] = true;
                if (left_to_right) {
                    if (correct_next_road_bin[0] == 1) {
                        Music.play_sound("blip");
                    }
                } else {
                    if (correct_next_road_bin[2] == 1) {
                        Music.play_sound("blip");
                    }
                }
            } else if (progress > 0.5 && !blips_done[1]) {
                blips_done[1] = true;
                if (correct_next_road_bin[1] == 1) {
                    Music.play_sound("blip");
                }
            } else if (progress > 0.6 && !blips_done[2]) {
                blips_done[2] = true;
                if (left_to_right) {
                    if (correct_next_road_bin[2] == 1) {
                        Music.play_sound("blip");
                    }
                } else {
                    if (correct_next_road_bin[0] == 1) {
                        Music.play_sound("blip");
                    }
                }
            }
        }

        if (turn_counter == 0) {
            fade -= 0.01;
            if (fade < 0) {
                fade = 0;
            }
        } else {
            if (restart_next_turn && progress > fade_start) {
                if (!fade_started) {
                    fade_started = true;
                    Music.play_sound("whoosh");
                    fade_color = Col.WHITE;
                }
                fade += 0.01;
                if (fade > 1) {
                    fade = 1;
                    restart();
                    return;
                }
            }
        }
        

        // End of road, turning
        if (current_progress > current_road.length) {
            current_progress = 0;
            blips_done = [false, false, false];

            if (turn_counter == 0) {
                // Determine orientation on first turn
                if (next_road == 1) {
                    left_to_right = true;
                } else if (next_road == 0) {
                    left_to_right = false;
                }
                current_road = current_road.nexts[next_road];
                two_road_fork(current_road);
                turn_counter++;

                correct_next_road = Random.int(0, 1);
                correct_next_road_bin = bin(correct_next_road);
            } else {
                var correct_next_is_correct = false;
                // some blips are ambigious
                switch (correct_next_road) {
                    case 0: correct_next_is_correct = (next_road == 0);
                    case 1: correct_next_is_correct = (next_road == 1 || next_road == 2 || next_road == 4);
                    case 2: correct_next_is_correct = (next_road == 1 || next_road == 2 || next_road == 4);
                    case 3: correct_next_is_correct = (next_road == 3 || next_road == 6);
                    case 4: correct_next_is_correct = (next_road == 1 || next_road == 2 || next_road == 4);
                    case 5: correct_next_is_correct = (next_road == 5);
                    case 6: correct_next_is_correct = (next_road == 3 || next_road == 6);
                    case 7: correct_next_is_correct = (next_road == 7);
                }

                if (!correct_next_is_correct) {
                    // restart on wrong turn
                    if (left_to_right) {
                        current_road = current_road.nexts[next_road];
                    } else {
                        current_road = current_road.nexts[current_road.nexts.length - 1 - next_road];
                    }
                    turn_counter++;
                    restart_next_turn = true;
                } else {
                    if (left_to_right) {
                        current_road = current_road.nexts[next_road];
                    } else {
                        current_road = current_road.nexts[current_road.nexts.length - 1 - next_road];
                    }
                    turn_counter++;
                    if (turn_counter < 2) {
                        two_road_fork(current_road);
                    } else if (turn_counter < 5) {
                        var fork_type = Random.float(0, 1);
                        if (fork_type > 0.9) {
                            eight_road_fork(current_road);
                        } else if (fork_type > 0.75) {
                            four_road_fork(current_road);
                        } else if (fork_type > 0.6) {
                            three_road_fork(current_road);
                        } else {
                            two_road_fork(current_road);
                        }
                    } else {
                        var fork_type = Random.float(0, 1);
                        if (fork_type > 0.8) {
                            eight_road_fork(current_road);
                        } else if (fork_type > 0.6) {
                            four_road_fork(current_road);
                        } else if (fork_type > 0.35) {
                            three_road_fork(current_road);
                        } else {
                            two_road_fork(current_road);
                        }
                    }

                    correct_next_road = Random.int(0, current_road.nexts.length - 1);

                    // reduce amount of ambigious choices to make it more interesting
                    if (current_road.nexts.length == 8) {
                        correct_next_road = Random.pick_int(0, 1, 3, 5, 7);
                    } else if (current_road.nexts.length == 4) {
                        correct_next_road = Random.pick_int(0, 1, 3);
                    }

                    correct_next_road_bin = bin(correct_next_road);
                }

                if (next_road > current_road.nexts.length - 1) {
                    next_road = Std.int(current_road.nexts.length - 1);
                }
            }
        }
    }

    function render() {
        Gfx.clear_screen(Col.RED);

        for (road in roads) {
            if (MathUtils.point_line_dst(player.x, player.y, road.x1, road.y1, road.x2, road.y2) < viewport_radius) {
                Gfx.draw_line(screenx(road.x1), screeny(road.y1), screenx(road.x2), screeny(road.y2), Col.WHITE);
            }
        }
        if (current_road.nexts.length != 0) {
            var next = current_road.nexts[next_road];
            if (!left_to_right) {
                next = current_road.nexts[current_road.nexts.length - 1 - next_road];
            }
            Gfx.draw_line(screenx(next.x1), screeny(next.y1), screenx(next.x2), screeny(next.y2), Col.YELLOW);
        }

        var progress = current_progress / current_road.length;
        var x_mid = current_road.x1 + (current_road.x2 - current_road.x1) * progress;
        var y_mid = current_road.y1 + (current_road.y2 - current_road.y1) * progress;
        Gfx.rotation(180 - current_road.angle); // road angles are upside down, because y-axis is upside down
        Gfx.change_tileset("car_anim");
        if (moving) {
            Gfx.draw_animation(screenx(x_mid) - Gfx.tile_width() / 2, screeny(y_mid) - Gfx.tile_height() / 2, "car_move");
        } else {
            Gfx.draw_tile(screenx(x_mid) - Gfx.tile_width() / 2, screeny(y_mid) - Gfx.tile_height() / 2, 0);
        }
        Gfx.rotation(0);

        Gfx.draw_image(screenx(bad.x) - Gfx.image_width("bad") / 2, screeny(bad.y) - Gfx.image_width("bad") / 2, "bad");

        Gfx.fill_box(0, 0, Gfx.screen_width, Gfx.screen_height, Col.PINK, 0.5);



        Gfx.change_tileset("clouds");
        for (cloud in clouds) {
            if (MathUtils.dst(Gfx.screen_width / 2, Gfx.screen_height / 2, cloud.x, cloud.y) < viewport_radius + cloud_radius) {
                Gfx.draw_tile(cloud.x - cloud_width / 2, cloud.y - cloud_width / 2, cloud.tilenum);
            }
        }


        // Fades
        if (turn_counter == 0) {
            if (fade != 0) {
                Gfx.fill_box(0, 0, Gfx.screen_width, Gfx.screen_height, fade_color, fade);
            }
        } else {
            if (fade != 0) {
                Gfx.fill_box(0, 0, Gfx.screen_width, Gfx.screen_height, fade_color, fade);
            }
        }
    }

    function update() {
        switch (state) {
            case GameState_Normal: update_normal();
        }

        render();
    }
}