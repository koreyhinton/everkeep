#!/bin/bash

# The game's constants and types, printed by main.sh and by the tests, so
# both compile the snippets against the same definitions. Prints Rust items
# only (no imports); it uses macroquad's Vec2 and Rect, and serde paths.

cat << 'EOF'

    // the world's size, in pixels; the view scrolls over it
    const WORLD_W: f32 = 3200.0;
    const WORLD_H: f32 = 2400.0;

    // A map: where players' bases can start. world-reset.sh shuffles the
    // spawn spots with the game's seed and gives player n the n-th one.
    struct Map {
        name: &'static str, // shown above the objectives
        spawns: &'static [Vec2],
    }

    // the default map: one spawn spot near each corner of the world, inset
    // so a hall and its spread fit inside
    const DEFAULT_MAP: Map = Map {
        name: "Winter's Edge",
        spawns: &[
            Vec2::new(500.0, 400.0),                     // top-left
            Vec2::new(WORLD_W - 500.0, 400.0),           // top-right
            Vec2::new(500.0, WORLD_H - 300.0),           // bottom-left
            Vec2::new(WORLD_W - 500.0, WORLD_H - 300.0), // bottom-right
        ],
    };

    // the unit's body, relative to its feet
    const UNIT_HITBOX: Rect = Rect::new(-24.0, -64.0, 48.0, 64.0);
    const UNIT_SPEED: f32 = 200.0;
    // spacing between units in a group move
    const MOVE_SPACING: f32 = 48.0;

    // a main hall's footprint, relative to its bottom-center position, and
    // its 320x256 texture's offset from that position
    const HALL_HITBOX: Rect = Rect::new(-128.0, -112.0, 256.0, 112.0);
    const HALL_TEXTURE_OFFSET: Vec2 = Vec2::new(-160.0, -256.0);

    // economy
    const START_GOLD: u32 = 500;
    const HALL_COST: u32 = 200;
    const PAWN_COST: u32 = 50;

    // the HUD is a strip along the bottom of the screen; the minimap sits in
    // its bottom-left
    const HUD_H: f32 = 120.0;
    // the view scrolls to keep a walking unit this far inside its edges
    const SCROLL_MARGIN: f32 = 120.0;

    // a unit sees this far from its feet
    const SIGHT_RANGE: f32 = 300.0;

    // objectives: each one is a bit in World::objectives
    const OBJ_FIND_RIVAL_HALL: u32 = 1 << 0;
    // every objective, in the order the quest bubble lists them
    const OBJECTIVES: [(u32, &str); 1] = [(OBJ_FIND_RIVAL_HALL, "Find the rival's main hall")];

    // lockstep: 60 sim ticks a second, 6 ticks (100 ms) a turn, and orders run
    // INPUT_DELAY turns after they're given
    const TICK_SECS: f32 = 1.0 / 60.0;
    const TICKS_PER_TURN: u32 = 6;
    const INPUT_DELAY: u32 = 2;

    #[derive(Clone, Copy, Debug, PartialEq)]
    enum BuildingKind {
        MainHall,
    }

    struct Unit {
        id: u32,
        owner: usize, // player 0 (blue) or 1 (red)
        pos: Vec2,    // feet, world space
        target: Vec2,
        dir: Vec2,
        speed: f32,
        hitbox: Rect,
        selected: bool, // local to this player, not part of the sim
        flip: bool,
        running: bool,
        frame: Rect, // source rect in the sprite sheet; zero-sized until animated
    }

    struct Building {
        id: u32,
        owner: usize,
        kind: BuildingKind,
        pos: Vec2, // bottom-center, world space
        hitbox: Rect,
        selected: bool,
    }

    // Everything the sim changes (units, buildings, gold, next_id, objectives) changes
    // only through apply-commands.sh, the same way on every player's machine.
    // The rest is this player's own: selection, placing, the drag and the view.
    struct World {
        units: Vec<Unit>,
        buildings: Vec<Building>,
        gold: [u32; 2], // per player
        me: usize,      // this player's index
        placing: Option<BuildingKind>,
        drag_start: Option<Vec2>, // screen space
        view: Vec2,               // world position of the screen's top-left
        next_id: u32,             // the id of the next unit or building
        outbox: Vec<Command>,     // this player's orders, not yet applied
        objectives: [u32; 2],     // per player: the OBJ_ bits they've completed
    }

    // An order. On the wire: {"op":"move","units":[0,1],"x":740,"y":300}.
    // Positions are whole world pixels, so both players apply the same values.
    #[derive(Clone, Debug, PartialEq, serde::Serialize, serde::Deserialize)]
    #[serde(tag = "op", rename_all = "snake_case")]
    enum Command {
        PlaceHall { x: i32, y: i32 },
        TrainPawn { hall: u32 },
        Move { units: Vec<u32>, x: i32, y: i32 },
    }

    // sharecmd's lockstep server: the reply to POST /match
    #[derive(serde::Deserialize)]
    struct MatchResp {
        match_id: String,
        player: usize,
    }

    // sharecmd's lockstep server: "start", "turn" or "end"
    #[derive(serde::Deserialize)]
    struct ServerMsg {
        #[serde(rename = "type")]
        kind: String,
        #[serde(default)]
        turn: u32,
        // "turn": each player's commands, kept as raw JSON so one unknown
        // command can't break the whole turn (null when a player sent none)
        #[serde(default)]
        all: [Option<Vec<serde_json::Value>>; 2],
        #[serde(default)]
        player: usize,
        #[serde(default)]
        seed: i64,
        #[serde(default)]
        reason: String,
    }

    // this player's commands for one turn
    #[derive(serde::Serialize)]
    struct CmdsMsg<'a> {
        #[serde(rename = "type")]
        kind: &'static str,
        turn: u32,
        cmds: &'a [Command],
    }

EOF
