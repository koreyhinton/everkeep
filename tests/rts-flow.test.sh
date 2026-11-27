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
#   hud-layout.sh        -> BuildButton TrainButton: the HUD buttons' rects
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
#   update-orders.sh     Units View Outbox Me: right-click queues Move.
#   apply-commands.sh    Commands Player Units Buildings Gold NextId
#   update-units.sh      Units DeltaT: walks units toward their targets.
#   update-scroll.sh     Units View Me: scrolls the view (the world position
#                        of the screen's top-left) to follow walking units.
#   draw-world.sh        Units Buildings View HallTextures PawnTextures
#   draw-placement.sh    Placing HallTexture: the ghost, drawn with a color
#                        alpha below 1.
#   draw-minimap.sh      Units Buildings View: changes when buildings, units
#                        or the view change.
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
export ${v}apply_Commands=world.outbox
export ${v}apply_Player=world.me
export ${v}apply_Units=world.units
export ${v}apply_Buildings=world.buildings
export ${v}apply_Gold=world.gold
export ${v}apply_NextId=world.next_id
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
export ${v}ghost_Placing=world.placing
export ${v}ghost_HallTexture=hall_texture
export ${v}minimap_Units=world.units
export ${v}minimap_Buildings=world.buildings
export ${v}minimap_View=world.view
export ${v}drawhud_Units=world.units
export ${v}drawhud_Buildings=world.buildings
export ${v}drawhud_Gold=world.gold[world.me]
export ${v}drawhud_Placing=world.placing
export ${v}drawhud_Me=world.me
export ${v}drawhud_BuildButton=build_button
export ${v}drawhud_TrainButton=train_button
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

# the game's constants and types (World, Unit, Building, Command, ...)
./models.sh

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

// ---- draw stubs: record instead of drawing ----

#[derive(Clone, Debug, PartialEq)]
struct Draw {
    phase: &'static str,
    kind: &'static str,
    text: String,    // draw_text
    texture: String, // draw_texture(_ex)
    rect: Rect,      // position (and size, where the call has one)
    color: Color,
}

fn record(kind: &'static str, text: &str, texture: &str, rect: Rect, color: Color) {
    let phase = PHASE.with(|phase| *phase.borrow());
    DRAWS.with(|draws| {
        draws.borrow_mut().push(Draw {
            phase,
            kind,
            text: text.to_string(),
            texture: texture.to_string(),
            rect,
            color,
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

fn draw_rectangle_lines(x: f32, y: f32, w: f32, h: f32, _thickness: f32, color: Color) {
    record("rect_lines", "", "", Rect::new(x, y, w, h), color);
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
    // offline, this frame's orders apply at once (the game's loopback)
    ` ./apply-commands.sh ${v}apply_ `
    world.outbox.clear();
    ` ./update-units.sh ${v}units_ `
    ` ./update-scroll.sh ${v}scroll_ `

    // Draw
    PHASE.with(|phase| *phase.borrow_mut() = "world");
    ` ./draw-world.sh ${v}world_ `
    PHASE.with(|phase| *phase.borrow_mut() = "placement");
    ` ./draw-placement.sh ${v}ghost_ `
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
    // world space
    let build = button(&draws, "Build Main Hall");
    play(&mut world, left_click(build));
    play(&mut world, left_click(mid));
    assert_eq!(world.buildings.len(), 2, "the second hall wasn't placed");
    let expected = vec2(mid.0, mid.1) + world.view;
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
EOF

