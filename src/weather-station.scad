use <rcolyer-threads/threads.scad>

/* [Part Selection] */
selection = 0; // [0:Assembly, 1:Bottom, 2:Top, 3:Holder, 4:Screw, 5:Clamp, 6:Clamp-Screw ]

/* [Hidden] */
$fa = 2; $fs = 0.2;

eps = 0.01;
nozzle = 0.4;
wall = 6 * nozzle;

dia = 45;
height = 30;
cut_dia_top = 3;
cut_dia_bottom = 4;
cut_count = floor(PI * dia / cut_dia_bottom / 2 / 2);
tolerance = 0.3;

holder_dia = 12;
holder_length = 180;
holder_wall = 3 * wall;
holder_width = holder_dia + 2 * holder_wall;

clamp_length = 40;
clamp_spacing = clamp_length + 6 * holder_wall;

thread_pitch = 2.5;
thread_tooth_angle = 50;
thread_inset = sin(thread_tooth_angle) * thread_pitch / 2;
thread_height = 8;
thread_dia = dia + 2 * wall;

module screw_hole(d, height, position = [0, 0, 0]) {
    ScrewHole(d, height, position = position, pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance)
        children();
} 

module screw_thread(d, height) {
    ScrewThread(d, height, pitch = thread_pitch, tooth_angle = thread_tooth_angle, tolerance = tolerance);
}

module shape(r, o = 0) {
	offset(o) circle(r);
}

module cap() {
	hull() {
		linear_extrude(height)
			shape(dia / 2, wall);
		linear_extrude(wall)
			shape(dia / 2 + height, wall);
	}
}

module cut(size, o, d) {
	rotate([0, 90, 0]) {
		linear_extrude(size, center = true) {
			hull() {
				translate([o, 0]) circle(d = d);
				translate([-o, 0]) circle(d = d);
				translate([-o, 0]) rotate(135) square(d/2);
			}
		}
	}
}

module top() {
	difference() {
		cap();
		translate([0, 0, -2 * wall]) cap();
	}
	difference() {
		screw_hole(thread_dia, thread_height + eps) {
			difference() {
				union() {
					linear_extrude(height, convexity = 3) shape(dia / 2, wall);
					hull() {
						linear_extrude(thread_height + 2 * wall, convexity = 3) shape(dia / 2, wall);
						linear_extrude(thread_height + wall, convexity = 3) shape(dia / 2, 2 * wall);
					}
				}
			}
			linear_extrude(height, convexity = 3) shape(dia / 2);
		}
		ch = (height - 2 * thread_height) / 4;
		for (a = [0:cut_count - 1]) {
			rotate(a * 180 / cut_count)
				translate([0, 0, thread_height + 2 * wall + ch + cut_dia_top / 2])
					cut(dia + 3 * wall, ch, cut_dia_top);
		}
		translate([0, 0, thread_height - eps]) cylinder(h = dia / 2, d1 = dia + 2 * wall, d2 = 0);
	}
}

module bottom() {
	difference() {
		union() {
			difference() {
				cap();
				translate([0, 0, -2 * wall]) cap();
			}
			translate([0, 0, height - eps]) screw_thread(thread_dia, thread_height + eps);
			linear_extrude(height, convexity = 3) shape(dia / 2 + wall);
		}
		translate([0, 0, -eps])
			linear_extrude(height + thread_height + 2 * eps, convexity = 3)
				shape(dia / 2);
		for (a = [0:cut_count - 1]) {
			rotate(a * 180 / cut_count)
				translate([0, 0, height / 2])
					cut(dia + 3 * wall, height / 6, cut_dia_bottom);
		}
	}

	screw_hole(holder_dia, 3 * wall) {
		difference() {
			linear_extrude(3 * wall) shape(dia / 2);
			translate([0, 0, 2 * wall + eps]) cylinder(h = wall, d1 = 0, d2 = dia);
		}
	}
}

module screw(th, hole = true) {
	kh = 4 * wall;
	th = is_undef(th) ? 4 * wall : th;
	d = holder_dia + 4 * wall;
	cnt = floor(PI * d / 2);
	difference() {
		union() {
			cylinder(d = d, h = kh);
			translate([0, 0, kh - eps])
				render(convexity = 3)
					screw_thread(holder_dia, th);
		}
		for (a = [0:cnt - 1])
			rotate(a * 360 / cnt)
				translate([d / 2, 0, -eps])
					cylinder(d = 1, h = kh - wall);
		c = 1;
		rotate_extrude()
			translate([d / 2 - c, 0])
				polygon([[0, -eps], [2 * c, 2 * c + eps], [2 * c, -eps]]);
		if (hole) {
			cylinder(d = 4, h = 10 * th, center = true);
			ch = holder_dia / 8;
			translate([0, 0, kh + th - ch + eps])
				cylinder(h = ch, d1 = 0, d2 = holder_dia);
		}
	}
}

module holder() {
	x = holder_length - 2 * holder_wall - holder_dia;
	screw_hole(holder_dia, 3 * wall, position = [x, 0, 0])
	screw_hole(holder_dia, 3 * wall, position = [x - clamp_spacing, 0, 0]) {
		difference() {
			translate([-holder_wall - holder_dia / 2, -holder_width / 2, 0])
				linear_extrude(2.5 * wall)
					offset(2 * wall) offset(-2 * wall)
						square([holder_length, holder_width]);
			cylinder(h = 10 * wall, d = holder_dia + 2 * tolerance, center = true);
		}
	}
}

module clamp1(h) {
	difference() {
		linear_extrude(h)
			offset(2 * wall) offset(-2 * wall)
				square([holder_width, holder_width], center = true);
		cylinder(h = 10 * wall, d = holder_dia + 2 * tolerance, center = true);
	}
}

module clamp() {
	h = 2.5 * wall;
	translate([0, 0, 0]) {
		difference() {
			union() {
				clamp1(h);
				translate([clamp_spacing, 0, 0])
					clamp1(h);
			}
		}
	}

	w = (holder_width - (holder_dia + 4 * tolerance)) / 2;

	translate([holder_width / 2, -holder_width / 2, clamp_length - 4 * tolerance])
		linear_extrude(h)
			square([clamp_spacing - holder_width, holder_width]);
	translate([holder_width / 2, -holder_width / 2, 0])
		cube([h, holder_width, clamp_length]);
	translate([clamp_spacing - holder_width / 2 - h, -holder_width / 2, 0])
		cube([h, holder_width, clamp_length]);
	translate([holder_width / 2 - h, -holder_width / 2, 0])
		cube([w, holder_width, h]);
	translate([-holder_width / 2 + clamp_spacing - w + h, -holder_width / 2, 0])
		cube([w, holder_width, h]);
}

module part_select() {
    for (idx = [0:1:$children-1]) {
        if (selection == 0) {
            col = parts[idx][3];
            translate(parts[idx][1])
                rotate(parts[idx][2])
                    if (is_undef(col))
                        children(idx);
                    else
                        color(col[0], col[1])
                            children(idx);
        } else {
            if (selection == idx)
                children(idx);
        }
    }
}

o1 = holder_length - 2 * holder_wall - holder_dia;
o2 = o1 - clamp_spacing;
parts = [
    [ "assembly",    [  0, 0,   0 ], [   0, 0, 0], undef],
    [ "bottom",      [  0, 0,   0 ], [   0, 0, 0], undef],
    [ "top",         [  0, 0,  60 ], [   0, 0, 0], undef],
    [ "holder",      [  0, 0, -20 ], [   0, 0, 0], undef],
    [ "screw",       [  0, 0, -50 ], [   0, 0, 0], undef],
    [ "clamp",       [ o2, 0, -30 ], [ 180, 0, 0], undef],
    [ "screw-2",     [ o2, 0, -80 ], [   0, 0, 0], undef],
    [ "screw-3",     [ o1, 0, -80 ], [   0, 0, 0], undef],
];

part_select() {
    union() { }
	bottom();
	top();
	holder();
	screw();
	clamp();
	screw(10 * wall, false);
	screw(10 * wall, false);
}
