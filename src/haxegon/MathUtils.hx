package haxegon;

import haxe.ds.Vector;


typedef Vector2 = {
    x: Float,
    y: Float,
}

typedef IntVector2 = {
    x: Int,
    y: Int,
}

typedef Vector3 = {
    x: Float,
    y: Float,
    z: Float,
}


@:publicFields
class MathUtils {

    static function rotate_point(x: Float, y: Float, angle: Float, x_origin: Float = 0, y_origin: Float = 0): Vector2 {
        var cos = Math.cos(MathUtils.deg_to_rad(angle));
        var sin = Math.sin(MathUtils.deg_to_rad(angle));
        var temp = {x: x - x_origin, y: y - y_origin};
        x = temp.x * cos - temp.y * sin;
        y = temp.x * sin + temp.y * cos;

        return {x: x + x_origin, y: y + y_origin};
    }

    static function point_line_sign(px: Float, py: Float, lx1: Float, ly1: Float, lx2: Float, ly2: Float): Float {
        return (px - lx2) * (ly1 - ly2) - (lx1 - lx2) * (py - ly2);
    }

    static function poly_centroid(poly: Array<Float>): Vector2 {
        var off = {x: poly[0], y: poly[1]};
        var twicearea = 0.0;
        var x = 0.0;
        var y = 0.0;
        var p1: Vector2;
        var p2: Vector2;
        var f: Float;
        var i = 0;
        var j = Std.int(poly.length / 2 - 1);
        while (i < poly.length / 2) {
            p1 = {x: poly[i * 2], y: poly[i * 2 + 1]};
            p2 = {x: poly[j * 2], y: poly[j * 2 + 1]};
            f = (p1.x - off.x) * (p2.y - off.y) - (p2.x - off.x) * (p1.y - off.y);
            twicearea += f;
            x += (p1.x + p2.x - 2 * off.x) * f;
            y += (p1.y + p2.y - 2 * off.y) * f;
            j = i++;
        }

        f = twicearea * 3;

        return {x: x / f + off.x, y: y / f + off.y};
    }

    static function point_box_intersect(point_x: Float, point_y: Float, box_x: Float, box_y: Float, box_width: Float, box_height: Float): Bool {
        return point_x > box_x && point_x < box_x + box_width && point_y > box_y && point_y < box_y + box_height;
    }

    static function circle_polygon_intersect(circle_x: Float, circle_y: Float, circle_radius: Float, polygon: Array<Float>): Bool {
        for (i in 0...Std.int(polygon.length / 2 - 1)) {
            if (circle_line_intersect(circle_x, circle_y, circle_radius, polygon[i * 2], polygon[i * 2 + 1], polygon[i * 2 + 2], polygon[i * 2 + 3])) {
                return true;
            }
        }
        if (circle_line_intersect(circle_x, circle_y, circle_radius, polygon[polygon.length - 2], polygon[polygon.length - 1], polygon[0], polygon[1])) {
            return true;
        } else {
            return false;
        }
    }

    static function circle_tri_intersect(circle_x: Float, circle_y: Float, circle_radius: Float, tri: Array<Float>): Bool {
        return circle_line_intersect(circle_x, circle_y, circle_radius, tri[0], tri[1], tri[2], tri[3])
        || circle_line_intersect(circle_x, circle_y, circle_radius, tri[2], tri[3], tri[4], tri[5])
        || circle_line_intersect(circle_x, circle_y, circle_radius, tri[4], tri[5], tri[0], tri[1]);
    }

    static function circle_line_intersect(circle_x: Float, circle_y: Float, circle_radius: Float, line_x1: Float, line_y1: Float, line_x2: Float, line_y2: Float): Bool {
        return point_line_dst(circle_x, circle_y, line_x1, line_y1, line_x2, line_y2) < circle_radius;
    }

    static function point_line_dst(point_x: Float, point_y: Float, line_x1: Float, line_y1: Float, line_x2: Float, line_y2: Float): Float {
        var line_length2 = dst2(line_x1, line_y1, line_x2, line_y2);
        if (line_length2 == 0) {
            return dst(point_x, point_y, line_x1, line_y1);
        }

        var t = ((point_x - line_x1) * (line_x2 - line_x1) + (point_y - line_y1) * (line_y2 - line_y1)) / line_length2;
        t = Math.max(0, Math.min(1, t));
        return dst(point_x, point_y, line_x1 + t * (line_x2 - line_x1), line_y1 + t * (line_y2 - line_y1));
    }

    static function dst(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    }

    static function dst2(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
    }

    static function rad_to_deg(angle: Float): Float {
        return angle * 57.2958;
    }

    static function deg_to_rad(angle: Float): Float {
        return angle / 57.2958;
    }

    static function sign(x: Float): Int {
        if (x > 0) {
            return 1;
        } else if (x < 0) {
            return -1;
        } else {
            return 0;
        }
    }

    static function lerp(x1: Float, x2: Float, a: Float): Float {
        return x1 + (x2 - x1) * a;
    }

    static function mean(v: Vector<Float>): Float {
        var mean = 0.0;
        for (i in 0...v.length) {
            mean += v[i];
        }
        mean /= v.length;
        return mean;
    }

    static function std_dev(v: Vector<Float>): Float {
        var mean = mean(v);
        var std_dev = 0.0;
        for (i in 0...v.length) {
            std_dev += (v[i] - mean) * (v[i] - mean);
        }
        std_dev = Math.sqrt(std_dev / v.length);
        return std_dev;
    }

    static function inner_product(m1: Vector<Float>, m2: Vector<Float>): Float {
        var out = 0.0;
        for (i in 0...m1.length) {
            out += m1[i] * m2[i];
        }
        return out;
    }
    
    static function outer_product(v1: Vector<Float>, v2: Vector<Float>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(v1.length, v2.length);
        }
        for (i in 0...out.length) {
            for (j in 0...out[i].length) {
                out[i][j] = v1[i] * v2[j];
            }
        }
        return out;
    }

    static function mat_transpose(m: Vector<Vector<Float>>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(m[0].length, m.length);
        }
        for (i in 0...out.length) {
            for (j in 0...out[i].length) {
                out[i][j] = m[j][i];
            }
        }
        return out;
    }

    static function mat_add(m1: Vector<Vector<Float>>, m2: Vector<Vector<Float>>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(m1.length, m1[0].length);
        }
        for (i in 0...out.length) {
            for (j in 0...out[i].length) {
                out[i][j] = m1[i][j] + m2[i][j];
            }
        }
        return out;
    }

    static function mat_dot(m1: Vector<Vector<Float>>, m2: Vector<Vector<Float>>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(m1.length, m2[0].length);
        }
        var sum: Float;
        for (i in 0...m1.length) {
            for (j in 0...m2[0].length) {
                sum = 0;
                for (k in 0...m1[0].length) {
                    sum += m1[i][k] * m2[k][j];
                }
                out[i][j] = sum;
            }
        }
        return out;
    }

    static function mat_scalar_mult(m: Vector<Vector<Float>>, s: Float, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(m.length, m[0].length);
        }
        for (i in 0...m.length) {
            for (j in 0...m[i].length) {
                out[i][j] = m[i][j] * s;
            }
        }
        return out;
    }

    static function hadamard_product(m1: Vector<Vector<Float>>, m2: Vector<Vector<Float>>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(m1.length, m2[0].length);
        }
        for (i in 0...m1.length) {
            for (j in 0...m2[0].length) {
                out[i][j] = m1[i][j] * m2[i][j];
            }
        }
        return out;
    }

    static function kronecker_product(v1: Vector<Float>, v2: Vector<Float>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(v1.length * v2.length, v1.length * v2.length);
        }
        for (i in 0...v1.length) {
            for (j in 0...v1.length) {
                out[i][j] = v1[i] * v2[j];
            }
        }
        return out;
    }

    static function mat_concat_horizontal(m1: Vector<Vector<Float>>, m2: Vector<Vector<Float>>, out: Vector<Vector<Float>> = null): Vector<Vector<Float>> {
        if (out == null) {
            out = Data.float_2dvector(m1.length, m1[0].length + m2[0].length);
        }
        var m1Width = m1[0].length;
        for (i in 0...out.length) {
            for (j in 0...out[0].length) {
                if (j < m1Width) {
                    out[i][j] = m1[i][j];
                } else {
                    out[i][j] = m2[i][j - m1Width];
                }
            }
        }
        return out;
    }
}
