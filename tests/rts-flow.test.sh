#!/bin/bash

# Prints the RTS starter flow test as one Rust file (test.sh writes it to
# tests/rts_flow.rs).
#
# One test plays the starter's whole flow, a frame at a time:
#   1. The HUD shows the starting gold and a "Build Main Hall" button in the
#      bottom-right.
#   2. Clicking the button shows a semi-transparent ghost hall that follows
#      the mouse; the next click places the hall, and the gold goes down.
#   3. Drag-selecting the hall changes the HUD, which now offers "Train Pawn".
#   4. Clicking "Train Pawn" puts a second unit next to the hall, and the gold
#      goes down again.
#   5. Drag-selecting both units changes the HUD again ("Train Pawn" is gone).
#   6. Right-clicking near the right edge walks both units there, the view
#      scrolls right to keep them on screen, and the minimap changes.
#
# How it's driven: frame() inlines every snippet once, like one pass of
# main.sh's loop, with the game state in a World (src/models.sh, shared with
# the game). Local fns shadow macroquad's glob import (as in the other
# tests): the input and screen stubs return a scripted state, and the draw
# stubs record each call, tagged with the phase (world, placement, minimap,
# hud) of the snippet that made it. The test finds HUD buttons and the gold
# amount from the recorded text, so it doesn't fix a layout.
#
# The input snippets only queue orders (Command) in world.outbox, and
# apply-commands.sh is the one place the sim changes. frame() applies the
# outbox straight away, as the game does offline; online, the game sends it
# through the lockstep server first (see tests/lockstep.test.sh).
#
#   hud-layout.sh        -> BuildButton TrainButton Minimap: the HUD buttons'
#                        rects, and the minimap's
#   update-hud.sh        Buildings Gold Placing Outbox Me BuildButton
#                        TrainButton: "Build Main Hall" sets Placing; "Train
#                        Pawn" (hall selected) queues TrainPawn. A click on a
#                        button doesn't change the selection.
#   update-placement.sh  Placing Outbox View: while placing, a left click on
#                        the map queues PlaceHall at the mouse (world space)
#                        and ends placing.
#   update-select.sh     DragStart Units Buildings View Me: left-drag
#                        selection of this player's units; units win over
#                        buildings; a drag can't start on the HUD.
#   update-orders.sh     Units View Outbox Me Minimap: right-click queues Move,
#                        on the map or on the minimap (to the world point it
#                        shows).
#   update-minimap-view.sh  Minimap View DragStart: holding the left button
#                        on the minimap centers the view there, unless a box
#                        drag is under way.
#   apply-commands.sh    Commands Player Units Buildings Gold NextId
#   update-units.sh      Units DeltaT: walks units toward their targets.
#   update-scroll.sh     Units View Me: scrolls the view (the world position
#                        of the screen's top-left) to follow walking units
#                        that are on screen.
#   find-path.sh, apply-path.sh: the paths for units given new orders, as
#                        main.sh finds them after the commands.
#   draw-world.sh        Units Buildings View HallTextures PawnTextures Tiles
#                        TreeTextures: trees drawn back to front with the
#                        rest.
#   draw-placement.sh    Placing HallTexture: the ghost, drawn with a color
#                        alpha below 1.
#   draw-minimap.sh      Units Buildings View Minimap Tiles: trees as tiles;
#                        changes when buildings, units
#                        or the view change. The view's outline is on whole
#                        pixels, at least 2.0 thick.
#   draw-drag-box.sh     DragStart: the drag box, outlined like the minimap's
#                        view.
#   draw-hud.sh          Units Buildings Gold Placing Me BuildButton
#                        TrainButton: "Gold: <n>", the buttons (clicking a
#                        label's text hits its button) and the selection.
#   draw-objectives.sh   Objectives MapName: the quest bubble in the
#                        top-right, one row per OBJECTIVES entry, checked when
#                        its bit is set, with the map's name above it.
#
# Keep the stubs below in step with the macroquad calls the snippets make.

: "${NSMAP:?set NSMAP (see test.sh)}"

cd "$(dirname "${BASH_SOURCE[0]}")/../src" || exit 1

v=mn_
# maps
export ${v}layout_BuildButton=build_button
export ${v}layout_TrainButton=train_button
export ${v}layout_Minimap=minimap
export ${v}hud_Buildings=world.buildings
export ${v}hud_Gold=world.gold[world.me]
export ${v}hud_Placing=world.placing
export ${v}hud_Outbox=world.outbox
export ${v}hud_Me=world.me
export ${v}hud_BuildButton=build_button
export ${v}hud_TrainButton=train_button
export ${v}place_Placing=world.placing
export ${v}place_Outbox=world.outbox
export ${v}place_View=world.view
export ${v}select_DragStart=world.drag_start
export ${v}select_Units=world.units
export ${v}select_Buildings=world.buildings
export ${v}select_View=world.view
export ${v}select_Me=world.me
export ${v}orders_Units=world.units
export ${v}orders_View=world.view
export ${v}orders_Outbox=world.outbox
export ${v}orders_Me=world.me
export ${v}orders_Minimap=minimap
export ${v}mmview_Minimap=minimap
export ${v}mmview_View=world.view
export ${v}mmview_DragStart=world.drag_start
export ${v}apply_Commands=world.outbox
export ${v}apply_Player=world.me
export ${v}apply_Units=world.units
export ${v}apply_Buildings=world.buildings
export ${v}apply_Gold=world.gold
export ${v}apply_NextId=world.next_id
export ${v}apply_Grid=world.grid
export ${v}path_Grid=world.grid
export ${v}path_Start=path_start
export ${v}path_Goal=path_goal
export ${v}path_Path=path_cells
export ${v}path_Found=path_found
export ${v}applypath_Unit=world.units[unit_i]
export ${v}applypath_Cells=path_cells
export ${v}applypath_Found=path_found
export ${v}applypath_Grid=world.grid
export ${v}units_Units=world.units
export ${v}units_DeltaT=t
export ${v}scroll_Units=world.units
export ${v}scroll_View=world.view
export ${v}scroll_Me=world.me
export ${v}world_Units=world.units
export ${v}world_Buildings=world.buildings
export ${v}world_View=world.view
export ${v}world_HallTextures=hall_textures
export ${v}world_PawnTextures=pawn_textures
export ${v}world_Tiles=tiles
export ${v}world_TreeTextures=tree_textures
export ${v}ghost_Placing=world.placing
export ${v}ghost_HallTexture=hall_texture
export ${v}minimap_Units=world.units
export ${v}minimap_Buildings=world.buildings
export ${v}minimap_View=world.view
export ${v}minimap_Minimap=minimap
export ${v}minimap_Tiles=tiles
export ${v}drawhud_Units=world.units
export ${v}drawhud_Buildings=world.buildings
export ${v}drawhud_Gold=world.gold[world.me]
export ${v}drawhud_Placing=world.placing
export ${v}drawhud_Me=world.me
export ${v}drawhud_BuildButton=build_button
export ${v}drawhud_TrainButton=train_button
export ${v}dragbox_DragStart=world.drag_start
export ${v}quests_Objectives=world.objectives[world.me]
export ${v}quests_MapName=DEFAULT_MAP.name

cat << EOF
// Code generated by tests/rts-flow.test.sh. DO NOT EDIT.
#![allow(non_snake_case)]
// the stubs cover macroquad calls the snippets may make, so some go unused
#![allow(dead_code, unused_variables, unused_mut)]

use macroquad::prelude::*;
use std::cell::RefCell;

const SCREEN_W: f32 = 800.0;
const SCREEN_H: f32 = 600.0;

EOF

# the game's constants and types (World, Unit, Building, Command, ...), and
# orc pathfinding's PathGrid
./models.sh
${ORC_PATHFINDING}/models.sh "${ORC_PATHFINDING_VERSION}" || exit 1

cat << EOF

impl World {
    fn new() -> World {
        let pos = vec2(150.0, 450.0);
        World {
            units: vec![Unit {
                id: 0,
                owner: 0,
                pos,
                target: pos,
                dir: Vec2::ZERO,
                speed: UNIT_SPEED,
                hitbox: UNIT_HITBOX,
                selected: false,
                flip: false,
                running: false,
                frame: Rect::new(0.0, 0.0, 0.0, 0.0),
                path: vec![],
                repath: false,
            }],
            buildings: vec![],
            gold: [START_GOLD; 2],
            me: 0,
            placing: None,
            drag_start: None,
            view: Vec2::ZERO,
            next_id: 1,
            outbox: vec![],
            objectives: [0; 2],
            // open ground: no trees (TILES draws a map's, for the tree tests)
            grid: PathGrid { w: GRID_W, h: GRID_H, blocked: vec![false; GRID_W * GRID_H] },
        }
    }
}

// ---- input and screen stubs ----

#[derive(Clone, Copy, Default)]
struct Mouse {
    pos: (f32, f32),
    left_pressed: bool,
    left_down: bool,
    left_released: bool,
    right_pressed: bool,
    right_down: bool,
    right_released: bool,
}

thread_local! {
    static MOUSE: RefCell<Mouse> = RefCell::new(Mouse::default());
    static PHASE: RefCell<&'static str> = RefCell::new("");
    static DRAWS: RefCell<Vec<Draw>> = RefCell::new(Vec::new());
    // the map tiles frame() draws (none, unless a test sets some)
    static TILES: RefCell<&'static [&'static str]> = const { RefCell::new(&[]) };
}

fn mouse() -> Mouse {
    MOUSE.with(|mouse| *mouse.borrow())
}

fn mouse_position() -> (f32, f32) {
    mouse().pos
}

fn is_mouse_button_pressed(button: MouseButton) -> bool {
    match button {
        MouseButton::Left => mouse().left_pressed,
        MouseButton::Right => mouse().right_pressed,
        _ => false,
    }
}

fn is_mouse_button_down(button: MouseButton) -> bool {
    match button {
        MouseButton::Left => mouse().left_down,
        MouseButton::Right => mouse().right_down,
        _ => false,
    }
}

fn is_mouse_button_released(button: MouseButton) -> bool {
    match button {
        MouseButton::Left => mouse().left_released,
        MouseButton::Right => mouse().right_released,
        _ => false,
    }
}

fn screen_width() -> f32 {
    SCREEN_W
}

fn screen_height() -> f32 {
    SCREEN_H
}

fn get_frame_time() -> f32 {
    1.0 / 60.0
}

// draw-world.sh sways trees by the clock
fn get_time() -> f64 {
    0.0
}

// ---- draw stubs: record instead of drawing ----

#[derive(Clone, Debug, PartialEq)]
struct Draw {
    phase: &'static str,
    kind: &'static str,
    text: String,    // draw_text
    texture: String, // draw_texture(_ex)
    rect: Rect,      // position (and size, where the call has one)
    color: Color,
    thickness: f32, // draw_rectangle_lines (0 for other calls)
}

fn record(kind: &'static str, text: &str, texture: &str, rect: Rect, color: Color) {
    record_lines(kind, text, texture, rect, color, 0.0);
}

fn record_lines(kind: &'static str, text: &str, texture: &str, rect: Rect, color: Color, thickness: f32) {
    let phase = PHASE.with(|phase| *phase.borrow());
    DRAWS.with(|draws| {
        draws.borrow_mut().push(Draw {
            phase,
            kind,
            text: text.to_string(),
            texture: texture.to_string(),
            rect,
            color,
            thickness,
        })
    });
}

fn draw_texture(texture: &String, x: f32, y: f32, color: Color) {
    record("texture", "", texture, Rect::new(x, y, 0.0, 0.0), color);
}

fn draw_texture_ex(texture: &String, x: f32, y: f32, color: Color, params: DrawTextureParams) {
    let size = params.dest_size.unwrap_or(Vec2::ZERO);
    record("texture", "", texture, Rect::new(x, y, size.x, size.y), color);
}

fn draw_rectangle(x: f32, y: f32, w: f32, h: f32, color: Color) {
    record("rect", "", "", Rect::new(x, y, w, h), color);
}

fn draw_rectangle_lines(x: f32, y: f32, w: f32, h: f32, thickness: f32, color: Color) {
    record_lines("rect_lines", "", "", Rect::new(x, y, w, h), color, thickness);
}

fn draw_line(x1: f32, y1: f32, x2: f32, y2: f32, _thickness: f32, color: Color) {
    record("line", "", "", Rect::new(x1, y1, x2 - x1, y2 - y1), color);
}

fn draw_circle(x: f32, y: f32, r: f32, color: Color) {
    record("circle", "", "", Rect::new(x - r, y - r, 2.0 * r, 2.0 * r), color);
}

fn draw_circle_lines(x: f32, y: f32, r: f32, _thickness: f32, color: Color) {
    record("circle_lines", "", "", Rect::new(x - r, y - r, 2.0 * r, 2.0 * r), color);
}

// rough metrics for macroquad's default font: half the size per character
fn measure_text(text: &str, _font: Option<&Font>, font_size: u16, _font_scale: f32) -> TextDimensions {
    let size = font_size as f32;
    TextDimensions {
        width: text.chars().count() as f32 * size * 0.5,
        height: size,
        offset_y: size * 0.75,
    }
}

fn draw_text(text: &str, x: f32, y: f32, font_size: f32, color: Color) -> TextDimensions {
    let dims = measure_text(text, None, font_size as u16, 1.0);
    record("text", text, "", Rect::new(x, y - dims.offset_y, dims.width, dims.height), color);
    dims
}

fn set_camera(_camera: &dyn Camera) {}

fn set_default_camera() {}

// ---- one frame of the game ----

fn frame(world: &mut World, input: Mouse) -> Vec<Draw> {
    MOUSE.with(|mouse| *mouse.borrow_mut() = input);
    let t = get_frame_time();
    let hall_textures = ["hall".to_string(), "red_hall".to_string()];
    let hall_texture = hall_textures[world.me].clone();
    let tree_textures = ["tree1", "tree2", "tree3", "tree4"].map(String::from);
    let tiles: &[&str] = TILES.with(|tiles| *tiles.borrow());
    let pawn_textures = [
        ["pawn".to_string(), "pawn_run".to_string()],
        ["red_pawn".to_string(), "red_pawn_run".to_string()],
    ];

    // Update
    ` ./hud-layout.sh ${v}layout_ `
    ` ./update-hud.sh ${v}hud_ `
    // as main.sh: the click that places a hall doesn't select
    if world.placing.is_none() {
        ` ./update-select.sh ${v}select_ `
    }
    ` ./update-placement.sh ${v}place_ `
    ` ./update-orders.sh ${v}orders_ `
    ` ./update-minimap-view.sh ${v}mmview_ `
    // offline, this frame's orders apply at once (the game's loopback)
    ` ./apply-commands.sh ${v}apply_ `
    world.outbox.clear();
    for unit_i in 0..world.units.len() {
        if world.units[unit_i].repath {
            let unit_pos = world.units[unit_i].pos;
            let unit_target = world.units[unit_i].target;
            let path_start = ((unit_pos.x / CELL) as usize, (unit_pos.y / CELL) as usize);
            let path_goal = ((unit_target.x / CELL) as usize, (unit_target.y / CELL) as usize);
            ` ${ORC_PATHFINDING}/snippets/find-path.sh ${v}path_ `
            ` ./apply-path.sh ${v}applypath_ `
        }
    }
    ` ./update-units.sh ${v}units_ `
    ` ./update-scroll.sh ${v}scroll_ `

    // Draw
    PHASE.with(|phase| *phase.borrow_mut() = "world");
    ` ./draw-world.sh ${v}world_ `
    PHASE.with(|phase| *phase.borrow_mut() = "placement");
    ` ./draw-placement.sh ${v}ghost_ `
    PHASE.with(|phase| *phase.borrow_mut() = "dragbox");
    ` ./draw-drag-box.sh ${v}dragbox_ `
    PHASE.with(|phase| *phase.borrow_mut() = "minimap");
    ` ./draw-minimap.sh ${v}minimap_ `
    PHASE.with(|phase| *phase.borrow_mut() = "hud");
    ` ./draw-hud.sh ${v}drawhud_ `
    PHASE.with(|phase| *phase.borrow_mut() = "objectives");
    ` ./draw-objectives.sh ${v}quests_ `
    PHASE.with(|phase| *phase.borrow_mut() = "");

    DRAWS.with(|draws| draws.borrow_mut().drain(..).collect())
}

// ---- input scripts ----

fn hover(pos: (f32, f32)) -> Mouse {
    Mouse { pos, ..Default::default() }
}

fn left_click(pos: (f32, f32)) -> Vec<Mouse> {
    vec![
        Mouse { pos, left_pressed: true, left_down: true, ..Default::default() },
        Mouse { pos, left_released: true, ..Default::default() },
    ]
}

fn right_click(pos: (f32, f32)) -> Vec<Mouse> {
    vec![
        Mouse { pos, right_pressed: true, right_down: true, ..Default::default() },
        Mouse { pos, right_released: true, ..Default::default() },
    ]
}

fn left_drag(from: (f32, f32), to: (f32, f32)) -> Vec<Mouse> {
    vec![
        Mouse { pos: from, left_pressed: true, left_down: true, ..Default::default() },
        Mouse { pos: to, left_down: true, ..Default::default() },
        Mouse { pos: to, left_released: true, ..Default::default() },
    ]
}

fn play(world: &mut World, inputs: Vec<Mouse>) -> Vec<Draw> {
    let mut last = vec![];
    for input in inputs {
        last = frame(world, input);
    }
    last
}

// ---- reading what was drawn ----

fn in_phase(draws: &[Draw], phase: &str) -> Vec<Draw> {
    draws.iter().filter(|draw| draw.phase == phase).cloned().collect()
}

fn hud_texts(draws: &[Draw]) -> Vec<String> {
    in_phase(draws, "hud")
        .into_iter()
        .filter(|draw| draw.kind == "text")
        .map(|draw| draw.text)
        .collect()
}

// the HUD's texts other than the gold and the button labels: what it says
// about the selection (gold changes on its own, so it can't show that)
fn hud_info(draws: &[Draw]) -> Vec<String> {
    hud_texts(draws)
        .into_iter()
        .filter(|text| !text.starts_with("Gold") && text != "Build Main Hall" && text != "Train Pawn")
        .collect()
}

// a point inside the HUD text with this label, to click its button
fn button(draws: &[Draw], label: &str) -> (f32, f32) {
    let found = in_phase(draws, "hud")
        .into_iter()
        .find(|draw| draw.kind == "text" && draw.text == label);
    match found {
        Some(draw) => draw.rect.center().into(),
        None => panic!("no HUD button labeled {label:?}; HUD texts: {:?}", hud_texts(draws)),
    }
}

// the number in the HUD's "Gold: <n>" text
fn gold(draws: &[Draw]) -> u32 {
    let texts = hud_texts(draws);
    let text = texts
        .iter()
        .find(|text| text.starts_with("Gold"))
        .unwrap_or_else(|| panic!("no Gold text in the HUD; HUD texts: {texts:?}"));
    let digits: String = text.chars().filter(|c| c.is_ascii_digit()).collect();
    digits.parse().unwrap_or_else(|_| panic!("no number in {text:?}"))
}

// the semi-transparent hall texture the placement snippet drew, if any
fn ghost(draws: &[Draw]) -> Option<Rect> {
    in_phase(draws, "placement")
        .into_iter()
        .find(|draw| draw.kind == "texture" && draw.texture == "hall" && draw.color.a < 1.0)
        .map(|draw| draw.rect)
}

fn screen_hitbox(world: &World, pos: Vec2, hitbox: Rect) -> Rect {
    Rect::new(
        pos.x + hitbox.x - world.view.x,
        pos.y + hitbox.y - world.view.y,
        hitbox.w,
        hitbox.h,
    )
}

// screen corners of a drag that encloses these rects, with a margin
fn drag_around(rects: &[Rect]) -> ((f32, f32), (f32, f32)) {
    let margin = 10.0;
    let left = rects.iter().map(|r| r.left()).fold(f32::MAX, f32::min) - margin;
    let top = rects.iter().map(|r| r.top()).fold(f32::MAX, f32::min) - margin;
    let right = rects.iter().map(|r| r.right()).fold(f32::MIN, f32::max) + margin;
    let bottom = rects.iter().map(|r| r.bottom()).fold(f32::MIN, f32::max) + margin;
    ((left, top), (right, bottom))
}

#[test]
fn build_a_hall_train_a_pawn_and_move_both_to_a_scrolled_view() {
    let mut world = World::new();
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);

    // 1. starting HUD: gold, and a Build Main Hall button in the bottom-right
    let draws = frame(&mut world, hover(mid));
    let start_gold = gold(&draws);
    let hud_at_start = hud_texts(&draws);
    let hud_info_at_start = hud_info(&draws);
    let minimap_at_start = in_phase(&draws, "minimap");
    assert!(!minimap_at_start.is_empty(), "the minimap drew nothing");
    let build = button(&draws, "Build Main Hall");
    assert!(
        build.0 > SCREEN_W / 2.0 && build.1 > SCREEN_H / 2.0,
        "Build Main Hall at {build:?} is not in the bottom-right"
    );

    // 2. click it: a ghost hall follows the mouse
    play(&mut world, left_click(build));
    let first = ghost(&frame(&mut world, hover((400.0, 250.0))))
        .expect("no semi-transparent ghost hall while placing");
    let second = ghost(&frame(&mut world, hover((440.0, 270.0))))
        .expect("the ghost hall disappeared while placing");
    assert_eq!(
        (second.x - first.x, second.y - first.y),
        (40.0, 20.0),
        "the ghost hall didn't follow the mouse"
    );

    // 3. click to place it: one hall, no ghost, less gold, a changed minimap
    play(&mut world, left_click((440.0, 270.0)));
    assert_eq!(world.buildings.len(), 1, "clicking didn't place the hall");
    assert_eq!(world.buildings[0].kind, BuildingKind::MainHall);
    assert_eq!(world.placing, None, "still placing after the hall was placed");
    let draws = frame(&mut world, hover(mid));
    assert_eq!(ghost(&draws), None, "the ghost hall is still drawn after placing");
    let gold_after_hall = gold(&draws);
    assert!(gold_after_hall < start_gold, "building the hall didn't cost gold");
    assert_ne!(in_phase(&draws, "minimap"), minimap_at_start, "the minimap didn't show the new hall");

    // 4. drag-select the hall: the HUD changes and offers Train Pawn
    let hall = &world.buildings[0];
    let (from, to) = drag_around(&[screen_hitbox(&world, hall.pos, hall.hitbox)]);
    play(&mut world, left_drag(from, to));
    assert!(world.buildings[0].selected, "dragging around the hall didn't select it");
    let draws = frame(&mut world, hover(mid));
    let hud_with_hall = hud_texts(&draws);
    assert_ne!(hud_with_hall, hud_at_start, "the HUD didn't change when the hall was selected");
    assert_ne!(hud_info(&draws), hud_info_at_start, "the HUD doesn't say the hall is selected");
    let hud_info_with_hall = hud_info(&draws);
    let train = button(&draws, "Train Pawn");
    let minimap_before_pawn = in_phase(&draws, "minimap");

    // 5. train a pawn: a second unit next to the hall, and less gold
    play(&mut world, left_click(train));
    for _ in 0..600 {
        if world.units.len() == 2 {
            break;
        }
        frame(&mut world, hover(mid));
    }
    assert_eq!(world.units.len(), 2, "Train Pawn didn't add a unit within 10 seconds");
    let distance = world.units[1].pos.distance(world.buildings[0].pos);
    assert!(distance < 200.0, "the new pawn is {distance} px from the hall, not alongside it");
    let draws = frame(&mut world, hover(mid));
    assert!(gold(&draws) < gold_after_hall, "training the pawn didn't cost gold");
    assert_ne!(in_phase(&draws, "minimap"), minimap_before_pawn, "the minimap didn't show the new pawn");

    // 6. drag-select both units: the HUD changes again, without Train Pawn
    let boxes: Vec<Rect> = world
        .units
        .iter()
        .map(|unit| screen_hitbox(&world, unit.pos, unit.hitbox))
        .collect();
    let (from, to) = drag_around(&boxes);
    play(&mut world, left_drag(from, to));
    assert!(world.units.iter().all(|unit| unit.selected), "dragging around both units didn't select both");
    assert!(!world.buildings[0].selected, "the hall stayed selected along with the units");
    let draws = frame(&mut world, hover(mid));
    let hud_with_units = hud_texts(&draws);
    assert_ne!(hud_with_units, hud_with_hall, "the HUD didn't change when the units were selected");
    assert_ne!(hud_info(&draws), hud_info_with_hall, "the HUD doesn't say the units are selected");
    assert!(
        !hud_with_units.iter().any(|text| text == "Train Pawn"),
        "Train Pawn is still offered with only units selected"
    );
    let minimap_before_move = in_phase(&draws, "minimap");

    // 7. right-click near the right edge: both walk there and the view scrolls
    play(&mut world, right_click((SCREEN_W - 10.0, SCREEN_H / 2.0)));
    let mut draws = vec![];
    for _ in 0..900 {
        draws = frame(&mut world, hover(mid));
    }
    assert!(world.view.x > 0.0, "the view didn't scroll right (view {:?})", world.view);
    for unit in &world.units {
        let on_screen = unit.pos - world.view;
        assert!(
            on_screen.x >= 0.0 && on_screen.x <= SCREEN_W && on_screen.y >= 0.0 && on_screen.y <= SCREEN_H,
            "a unit ended off screen at {on_screen:?}"
        );
    }
    assert_ne!(in_phase(&draws, "minimap"), minimap_before_move, "the minimap didn't show the move");

    // 8. with the view scrolled, a second hall lands where it's clicked, in
    // world space (below the first, a cell clear of it: halls block every
    // pathfinding cell their footprint touches)
    let build = button(&draws, "Build Main Hall");
    let spot = (mid.0, mid.1 + 80.0);
    play(&mut world, left_click(build));
    play(&mut world, left_click(spot));
    assert_eq!(world.buildings.len(), 2, "the second hall wasn't placed");
    let expected = vec2(spot.0, spot.1) + world.view;
    assert!(
        world.buildings[1].pos.distance(expected) <= 1.0,
        "the hall is at {:?}, not under the mouse at {expected:?} (view {:?})",
        world.buildings[1].pos,
        world.view
    );
}

// the minimap shows units and the view on their own (in the flow above, the
// view scrolls while units move, so either alone could hide the other)
#[test]
fn the_minimap_shows_where_units_are_and_where_the_view_is() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    let start = in_phase(&frame(&mut world, hover(mid)), "minimap");

    world.units[0].pos += vec2(300.0, 0.0);
    world.units[0].target = world.units[0].pos;
    let moved = in_phase(&frame(&mut world, hover(mid)), "minimap");
    assert_ne!(moved, start, "the minimap didn't show the unit's new position");

    world.view = vec2(600.0, 400.0);
    let scrolled = in_phase(&frame(&mut world, hover(mid)), "minimap");
    assert_ne!(scrolled, moved, "the minimap didn't show the view's new position");
}

// the quest bubble: in the top-right, above the HUD, listing the first
// objective; finding the rival's hall checks it off, for this player only
#[test]
fn the_objectives_bubble_checks_off_finding_the_rival_hall() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    let open = in_phase(&frame(&mut world, hover(mid)), "objectives");
    let label = open
        .iter()
        .find(|draw| draw.kind == "text" && draw.text == "Find the rival's main hall")
        .unwrap_or_else(|| panic!("no objective text; objectives drew {open:?}"));
    assert!(
        label.rect.x > SCREEN_W / 2.0 && label.rect.bottom() < SCREEN_H / 2.0,
        "the objective at {:?} is not in the top-right",
        label.rect
    );
    assert!(label.rect.right() <= SCREEN_W, "the objective runs off the screen");
    let open_color = label.color;
    let label_rect = label.rect;

    // the map's name sits above the bubble, in the same top-right corner
    let name = open
        .iter()
        .find(|draw| draw.kind == "text" && draw.text == "Winter's Edge")
        .unwrap_or_else(|| panic!("no map name; objectives drew {open:?}"));
    let panel = open
        .iter()
        .find(|draw| draw.kind == "rect" && draw.rect.contains(label_rect.center()))
        .expect("no panel behind the objectives");
    assert!(name.rect.bottom() <= panel.rect.y, "the map name {:?} isn't above the bubble {:?}", name.rect, panel.rect);
    assert!(name.rect.x >= panel.rect.x && name.rect.right() <= SCREEN_W, "the map name isn't over the bubble");

    // the other player's progress doesn't show here
    world.objectives[1] = OBJ_FIND_RIVAL_HALL;
    let theirs = in_phase(&frame(&mut world, hover(mid)), "objectives");
    assert_eq!(theirs, open, "the bubble shows the other player's objectives");

    world.objectives[world.me] = OBJ_FIND_RIVAL_HALL;
    let done = in_phase(&frame(&mut world, hover(mid)), "objectives");
    let lines = |draws: &[Draw]| draws.iter().filter(|draw| draw.kind == "line").count();
    assert!(lines(&done) > lines(&open), "no check mark once the objective is done");
    let label = done
        .iter()
        .find(|draw| draw.kind == "text" && draw.text == "Find the rival's main hall")
        .expect("the objective disappeared once it was done");
    assert_ne!(label.color, open_color, "a done objective looks the same as an open one");
}

// the click that places a hall doesn't also click-select what's under it
#[test]
fn placing_a_hall_on_a_pawn_doesnt_select_the_pawn() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    let build = button(&frame(&mut world, hover(mid)), "Build Main Hall");
    play(&mut world, left_click(build));
    // on the pawn's body (its feet are at (150, 450))
    play(&mut world, left_click((150.0, 430.0)));
    assert_eq!(world.buildings.len(), 1, "the hall wasn't placed");
    assert!(!world.units[0].selected, "the click that placed the hall selected the pawn");
}

// macroquad draws each side of draw_rectangle_lines thickness / 2 inside the
// rect, and a side only shows if it covers pixel centers. On whole pixels
// and at least 2.0 thick, every side is a full pixel row or column.
fn assert_crisp_outline(draw: &Draw, what: &str) {
    let r = draw.rect;
    for value in [r.x, r.y, r.w, r.h] {
        assert_eq!(value, value.round(), "the {what} outline {r:?} isn't on whole pixels");
    }
    assert!(draw.thickness >= 2.0, "the {what} outline is {} thick, so a side can vanish", draw.thickness);
}

#[test]
fn the_minimap_view_outline_draws_every_side() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    // views whose minimap edges land on fractions of a pixel
    for view in [vec2(0.0, 0.0), vec2(123.0, 77.0), vec2(601.0, 333.0), vec2(1999.0, 1650.0)] {
        world.view = view;
        let draws = frame(&mut world, hover(mid));
        let outline = in_phase(&draws, "minimap")
            .into_iter()
            .find(|draw| draw.kind == "rect_lines")
            .expect("the minimap drew no view outline");
        assert_crisp_outline(&outline, "minimap view");
        // still the view, to within the rounding
        let scale = (HUD_H - 16.0) / WORLD_H;
        let map_top = SCREEN_H - HUD_H + 8.0;
        let bottom = map_top + (view.y + SCREEN_H - HUD_H) * scale;
        assert!((outline.rect.bottom() - bottom).abs() <= 0.5, "the outline's bottom {} isn't the view's {bottom}", outline.rect.bottom());
    }
}

#[test]
fn the_drag_box_outline_draws_every_side() {
    let mut world = World::new();
    // fractional mouse positions, as on a scaled display
    frame(&mut world, Mouse { pos: (300.4, 100.6), left_pressed: true, left_down: true, ..Default::default() });
    let draws = frame(&mut world, Mouse { pos: (420.7, 211.2), left_down: true, ..Default::default() });
    let outline = in_phase(&draws, "dragbox")
        .into_iter()
        .find(|draw| draw.kind == "rect_lines")
        .expect("no drag box while dragging");
    assert_crisp_outline(&outline, "drag box");
}

// ---- the minimap: right-click to order, left-click or drag to look ----

// the minimap's rect, from its background (the first rectangle it draws)
fn minimap_rect(world: &mut World) -> Rect {
    let draws = frame(world, hover((SCREEN_W / 2.0, SCREEN_H / 2.0)));
    in_phase(&draws, "minimap")
        .into_iter()
        .find(|draw| draw.kind == "rect")
        .expect("the minimap drew no background")
        .rect
}

// the screen point on the minimap that shows this world point
fn on_minimap(minimap: Rect, world_pos: Vec2) -> (f32, f32) {
    (minimap.point() + world_pos * (minimap.w / WORLD_W)).into()
}

// the view that centers this world point in the map area, kept in the world
fn view_centered_on(world_pos: Vec2) -> Vec2 {
    let area = vec2(SCREEN_W, SCREEN_H - HUD_H);
    (world_pos - area / 2.0).clamp(Vec2::ZERO, vec2(WORLD_W, WORLD_H) - area)
}

// one minimap pixel covers this many world pixels, give or take rounding
fn minimap_pixel(minimap: Rect) -> f32 {
    WORLD_W / minimap.w + 1.0
}

#[test]
fn right_click_on_the_minimap_walks_units_across_the_world() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    world.units[0].selected = true;
    let minimap = minimap_rect(&mut world);
    let goal = vec2(2600.0, 1900.0);

    play(&mut world, right_click(on_minimap(minimap, goal)));
    // a lone unit stops MOVE_SPACING left of the point (its group grid)
    let expected = goal - vec2(MOVE_SPACING, 0.0);
    let target = world.units[0].target;
    assert!(
        target.distance(expected) <= minimap_pixel(minimap),
        "the unit is headed to {target:?}, not near {expected:?}"
    );

    // it walks all the way there, and the view follows it
    for _ in 0..1200 {
        frame(&mut world, hover(mid));
    }
    let unit = &world.units[0];
    assert_eq!(unit.pos, unit.target, "the unit didn't arrive");
    let on_screen = unit.pos - world.view;
    assert!(
        on_screen.x >= 0.0 && on_screen.x <= SCREEN_W && on_screen.y >= 0.0 && on_screen.y <= SCREEN_H - HUD_H,
        "the view didn't follow the unit (at {on_screen:?} on screen)"
    );
}

#[test]
fn right_click_on_the_minimap_doesnt_depend_on_the_view() {
    let goal = vec2(2000.0, 600.0);
    let mut targets = vec![];
    for view in [Vec2::ZERO, vec2(1000.0, 600.0)] {
        let mut world = World::new();
        world.units[0].selected = true;
        world.view = view;
        let minimap = minimap_rect(&mut world);
        play(&mut world, right_click(on_minimap(minimap, goal)));
        targets.push(world.units[0].target);
    }
    assert_eq!(targets[0], targets[1], "the minimap's order moved with the view");
}

#[test]
fn right_click_on_the_hud_off_the_minimap_orders_nothing() {
    let mut world = World::new();
    world.units[0].selected = true;
    let minimap = minimap_rect(&mut world);
    let before = world.units[0].target;
    let off = (minimap.right() + 40.0, SCREEN_H - 10.0);
    assert!(!minimap.contains(off.into()));
    play(&mut world, right_click(off));
    assert_eq!(world.units[0].target, before, "a right-click on the HUD ordered a move");
}

#[test]
fn left_click_on_the_minimap_centers_the_view_there() {
    let mut world = World::new();
    world.units[0].selected = true;
    let minimap = minimap_rect(&mut world);
    for goal in [vec2(1600.0, 1200.0), vec2(3100.0, 2300.0)] {
        play(&mut world, left_click(on_minimap(minimap, goal)));
        let expected = view_centered_on(goal);
        assert!(
            world.view.distance(expected) <= minimap_pixel(minimap),
            "clicking the minimap at {goal:?} put the view at {:?}, not {expected:?}",
            world.view
        );
    }
    assert!(world.units[0].selected, "clicking the minimap changed the selection");
    assert_eq!(world.units[0].target, world.units[0].pos, "clicking the minimap ordered a move");
}

#[test]
fn dragging_on_the_minimap_pans_the_view() {
    let mut world = World::new();
    let minimap = minimap_rect(&mut world);
    let from = on_minimap(minimap, vec2(1000.0, 800.0));
    let to = on_minimap(minimap, vec2(2200.0, 1500.0));
    frame(&mut world, Mouse { pos: from, left_pressed: true, left_down: true, ..Default::default() });
    let first = world.view;
    frame(&mut world, Mouse { pos: to, left_down: true, ..Default::default() });
    assert!(
        world.view.distance(view_centered_on(vec2(2200.0, 1500.0))) <= minimap_pixel(minimap),
        "dragging on the minimap didn't follow the mouse (view {:?}, was {first:?})",
        world.view
    );
}

#[test]
fn a_box_drag_that_crosses_the_minimap_doesnt_move_the_view() {
    let mut world = World::new();
    let minimap = minimap_rect(&mut world);
    let view = world.view;
    play(&mut world, left_drag((300.0, 200.0), minimap.center().into()));
    assert_eq!(world.view, view, "a box drag over the minimap moved the view");
}

#[test]
fn looking_away_doesnt_snap_back_to_walking_units() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    world.units[0].selected = true;
    let minimap = minimap_rect(&mut world);
    // the pawn walks right, then the player looks at the far corner
    play(&mut world, right_click((SCREEN_W - 10.0, 300.0)));
    play(&mut world, left_click(on_minimap(minimap, vec2(3000.0, 2200.0))));
    let looking = world.view;
    for _ in 0..60 {
        frame(&mut world, hover(mid));
    }
    assert!(world.units[0].running, "the pawn should still be walking");
    assert_eq!(world.view, looking, "the view snapped back to the walking pawn");
}

// ---- trees ----

// a 3 x 3 tile map with one tree in the middle tile, (64, 64)-(128, 128)
const ONE_TREE: &[&str] = &["...", ".T.", "..."];

#[test]
fn trees_are_drawn_back_to_front_with_units() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    // one pawn behind the tree (feet above its tile's bottom), one in front
    world.units[0].pos = vec2(96.0, 100.0);
    world.units[0].target = world.units[0].pos;
    let mut front = World::new().units.remove(0);
    front.id = 1;
    front.pos = vec2(96.0, 160.0);
    front.target = front.pos;
    world.units.push(front);
    // units only draw once their sprite has a frame
    for unit in world.units.iter_mut() {
        unit.frame = Rect::new(0.0, 0.0, 192.0, 192.0);
    }
    world.view = Vec2::ZERO;
    TILES.with(|tiles| *tiles.borrow_mut() = ONE_TREE);
    let draws = frame(&mut world, hover(mid));
    TILES.with(|tiles| *tiles.borrow_mut() = &[]);

    let textures: Vec<Draw> = in_phase(&draws, "world").into_iter().filter(|draw| draw.kind == "texture").collect();
    let trees: Vec<&Draw> = textures.iter().filter(|draw| draw.texture.starts_with("tree")).collect();
    assert_eq!(trees.len(), 1, "expected one tree, drew {textures:?}");
    // centered on its tile
    let tree = trees[0];
    assert_eq!(tree.rect.x + 96.0, 96.0, "the tree isn't centered on its tile");
    let order: Vec<f32> = textures
        .iter()
        .map(|draw| if draw.texture.starts_with("tree") { 128.0 } else { draw.rect.y + 128.0 })
        .collect();
    assert_eq!(order, vec![100.0, 128.0, 160.0], "not drawn back to front: {textures:?}");
}

#[test]
fn trees_move_with_the_view() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    world.view = vec2(40.0, 20.0);
    TILES.with(|tiles| *tiles.borrow_mut() = ONE_TREE);
    let draws = frame(&mut world, hover(mid));
    TILES.with(|tiles| *tiles.borrow_mut() = &[]);
    let tree = in_phase(&draws, "world")
        .into_iter()
        .find(|draw| draw.texture.starts_with("tree"))
        .expect("the tree wasn't drawn");
    // its tile's center is at world x 96, so its 192-wide picture starts at
    // 0, less the view
    assert_eq!(tree.rect.x, -40.0, "the tree didn't move with the view");
}

#[test]
fn trees_off_screen_arent_drawn() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    world.view = vec2(1500.0, 1200.0);
    TILES.with(|tiles| *tiles.borrow_mut() = ONE_TREE);
    let draws = frame(&mut world, hover(mid));
    TILES.with(|tiles| *tiles.borrow_mut() = &[]);
    assert!(
        !in_phase(&draws, "world").iter().any(|draw| draw.texture.starts_with("tree")),
        "a tree far off screen was drawn"
    );
}

#[test]
fn the_minimap_shows_trees() {
    let mid = (SCREEN_W / 2.0, SCREEN_H / 2.0);
    let mut world = World::new();
    let bare = in_phase(&frame(&mut world, hover(mid)), "minimap");
    TILES.with(|tiles| *tiles.borrow_mut() = ONE_TREE);
    let draws = frame(&mut world, hover(mid));
    TILES.with(|tiles| *tiles.borrow_mut() = &[]);
    let minimap = minimap_rect(&mut world);
    let scale = minimap.w / WORLD_W;
    let with_tree = in_phase(&draws, "minimap");
    assert_eq!(with_tree.len(), bare.len() + 1, "the minimap didn't draw the tree");
    assert!(
        with_tree.iter().any(|draw| draw.kind == "rect"
            && draw.rect.x == minimap.x + TILE * scale
            && draw.rect.y == minimap.y + TILE * scale),
        "the tree isn't at its tile on the minimap"
    );
}

// a Move walks around a hall in the way, never under it
#[test]
fn a_pawn_walks_around_a_hall_in_its_way() {
    let mut world = World::new();
    world.units[0].pos = vec2(200.0, 300.0);
    world.units[0].target = world.units[0].pos;
    world.units[0].selected = true;
    // a hall between the pawn and where it's sent
    world.outbox.push(Command::PlaceHall { x: 400, y: 340 });
    frame(&mut world, hover((0.0, 0.0)));
    assert_eq!(world.buildings.len(), 1);
    let hall = &world.buildings[0];
    let footprint = Rect::new(hall.pos.x + hall.hitbox.x, hall.pos.y + hall.hitbox.y, hall.hitbox.w, hall.hitbox.h);
    play(&mut world, right_click((620.0, 300.0)));
    for _ in 0..300 {
        frame(&mut world, hover((0.0, 0.0)));
        assert!(!footprint.contains(world.units[0].pos), "the pawn walked under the hall at {:?}", world.units[0].pos);
    }
    assert_eq!(world.units[0].pos, world.units[0].target, "the pawn didn't get around the hall");
}
EOF

