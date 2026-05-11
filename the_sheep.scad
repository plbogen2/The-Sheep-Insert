include <boardgame_insert_toolkit_lib.4.scad>;

// --- GLOBAL SETTINGS ---
g_font = "Alfa Slab One:style=Bold";
h_std = 42;    
chamf = 1.5;   

// Widths for 9 1/4" (234.95mm) Box Interior
c1_w = 74.5;      
c2_w = 84.5;      
c3_w = 74;         

poker_int = [71, 101];
tarot_int = [81, 140];

lid_ironwork = [
    [ LID_PATTERN_RADIUS, 18 ],      
    [ LID_PATTERN_ANGLE, 45 ],       
    [ LID_PATTERN_N1, 20 ],          
    [ LID_PATTERN_N2, 240 ],
    [ LID_PATTERN_THICKNESS, 1.2 ],  
    [ LID_PATTERN_ROW_OFFSET, 0 ],  
    [ LID_PATTERN_COL_OFFSET, 0 ]
]; 

// --- MODULAR BOX FUNCTIONS ---

function box_deck(name, box_w, box_d, pos_xy, lid_lbl, id_off, int_xy) = [
    OBJECT_BOX,
    [ NAME, name ], [ BOX_SIZE_XYZ, [box_w, box_d, h_std] ], [ POSITION_XY, pos_xy ],
    [ CHAMFER_N, chamf ], [ BOX_WALL_THICKNESS, 1.5 ],
    [ BOX_LID,  
        each lid_ironwork,  
        [ LABEL, [ LBL_TEXT, lid_lbl ], [ LBL_SIZE, 6 ], [ LBL_FONT, g_font ] ] 
    ],
    [ LABEL, [ LBL_TEXT, name ], [ LBL_PLACEMENT, LEFT ], [ LBL_SIZE, 4 ], [ POSITION_XY, id_off ], [ LBL_FONT, g_font ] ],
    [ BOX_FEATURE,  
        [ FTR_COMPARTMENT_SIZE_XYZ, [int_xy.x, int_xy.y, h_std-4.5] ], [ POSITION_XY, [CENTER, CENTER] ],
        [ FTR_CUTOUT_SIDES_4B, [true, true, false, false] ], 
        [ FTR_CUTOUT_WIDTH_PCT, 35 ], 
        [ FTR_CUTOUT_HEIGHT_PCT, 100 ], 
        [ LABEL, [ LBL_TEXT, lid_lbl ], [ LBL_PLACEMENT, CENTER ], [ LBL_SIZE, 6 ], [ LBL_DEPTH, 1.2 ], [ LBL_FONT, g_font ] ]
    ]
];

function box_traits(name, pos_xy) = [
    OBJECT_BOX, 
    [ NAME, name ], 
    [ BOX_SIZE_XYZ, [c2_w, 66.6, h_std] ], 
    [ POSITION_XY, pos_xy ], 
    [ CHAMFER_N, chamf ], 
    [ BOX_WALL_THICKNESS, 2 ],
    [ BOX_LID, 
        each lid_ironwork, 
        [ LABEL, [ LBL_TEXT, "SHEPHERD" ], [ LBL_SIZE, 5 ], [ POSITION_XY, [0, 3] ], [ LBL_FONT, g_font ] ],
        [ LABEL, [ LBL_TEXT, "TRAITS" ], [ LBL_SIZE, 5 ], [ POSITION_XY, [0, -3] ], [ LBL_FONT, g_font ] ]
    ],
    [ LABEL, [ LBL_TEXT, name ], [ LBL_PLACEMENT, LEFT ], [ LBL_SIZE, 4 ], [ POSITION_XY, [25, -12] ], [ LBL_FONT, g_font ] ],
    [ BOX_FEATURE, 
        [ FTR_NUM_COMPARTMENTS_XY, [1, 6] ], 
        [ FTR_COMPARTMENT_SIZE_XYZ, [c2_w - 6, 9.4, h_std-4] ], 
        [ FTR_PEDESTAL_BASE_B, true ], 
        [ FTR_CUTOUT_SIDES_4B, [true, true, false, false] ], 
        [ FTR_CUTOUT_WIDTH_PCT, 65 ], 
        [ FTR_CUTOUT_DEPTH_MAX, 3.1 ],
        [ LABEL, 
            [ LBL_TEXT, [ ["MERC"], ["DOC"], ["SURV"], ["SGT"], ["MECH"], ["SCOUT"] ] ], 
            [ LBL_PLACEMENT, CENTER ], [ LBL_SIZE, 3.5 ], [ LBL_FONT, g_font ] 
        ]
    ]
];

function box_tokens(name, pos_xy) = [
    OBJECT_BOX,
    [ NAME, name ], [ BOX_SIZE_XYZ, [c3_w, 160, h_std] ], [ POSITION_XY, pos_xy ],
    [ CHAMFER_N, chamf ],
    [ BOX_LID, 
        each lid_ironwork, 
        [ LABEL, [ LBL_TEXT, "TOKENS" ], [ LBL_SIZE, 5 ], [ POSITION_XY, [0, 5.5] ], [ LBL_FONT, g_font ] ],
        [ LABEL, [ LBL_TEXT, "&" ], [ LBL_SIZE, 5 ], [ POSITION_XY, [0, 0] ], [ LBL_FONT, g_font ] ],
        [ LABEL, [ LBL_TEXT, "TRACKERS" ], [ LBL_SIZE, 5 ], [ POSITION_XY, [0, -5.5] ], [ LBL_FONT, g_font ] ]
    ],
    [ LABEL, [ LBL_TEXT, name ], [ LBL_PLACEMENT, LEFT ], [ LBL_SIZE, 4 ], [ POSITION_XY, [65, -12] ], [ LBL_FONT, g_font ] ],
    [ BOX_FEATURE, 
        [ FTR_NUM_COMPARTMENTS_XY, [2, 1] ], [ FTR_COMPARTMENT_SIZE_XYZ, [(c3_w-6)/2, 90, h_std-4] ], [ POSITION_XY, [CENTER, 0] ],
        [ FTR_SHAPE, FILLET ], [ FTR_FILLET_RADIUS, 10 ],
        [ LABEL, [ LBL_TEXT, [["ESSENCE", "LANTERNS"]] ], [ LBL_PLACEMENT, CENTER ], [ ROTATION, 90 ], [ LBL_SIZE, 4 ], [ LBL_FONT, g_font ] ] 
    ],
    [ BOX_FEATURE, 
        [ FTR_NUM_COMPARTMENTS_XY, [3, 1] ], [ FTR_COMPARTMENT_SIZE_XYZ, [(c3_w-8)/3, 60, h_std-4] ], [ POSITION_XY, [CENTER, 94] ],
        [ FTR_SHAPE, FILLET ], [ FTR_FILLET_RADIUS, 5 ],
        [ LABEL, [ LBL_TEXT, [["CORRUPTION", "EXPERIENCE", "POLLUTION"]] ], [ LBL_PLACEMENT, CENTER ], [ ROTATION, 90 ], [ LBL_SIZE, 3 ], [ LBL_FONT, g_font ] ] 
    ]
];

function box_bags(name, label, pos_xy) = [
    OBJECT_BOX,
    [ NAME, name ], [ BOX_SIZE_XYZ, [c3_w, 158, h_std] ], [ POSITION_XY, pos_xy ],
    [ CHAMFER_N, chamf ], [ BOX_NO_LID_B, true ],
    [ LABEL, [ LBL_TEXT, name ], [ LBL_PLACEMENT, LEFT ], [ LBL_SIZE, 4 ], [ POSITION_XY, [60, -12] ], [ LBL_FONT, g_font ] ],
    [ BOX_FEATURE, 
        [ FTR_COMPARTMENT_SIZE_XYZ, [c3_w-4, 154, h_std-4] ],
        [ LABEL, [ LBL_TEXT, label ], [ LBL_PLACEMENT, CENTER ], [ ROTATION, 90 ], [ LBL_SIZE, 6 ], [ LBL_FONT, g_font ] ] 
    ]
];

print_lid = is_undef(print_lid) ? true : print_lid;
print_box = is_undef(print_box) ? true : print_box;
box_id = is_undef(box_id) ? "" : box_id;

// --- FINAL ASSEMBLY ---
data = [
    [G_PRINT_LID_B, print_lid],
    [G_PRINT_BOX_B, print_box],
    [G_ISOLATED_PRINT_BOX, box_id],
    
    box_deck("LB", c1_w, 106, [0, 0],   "EQUIPMENT", [40, -12], poker_int),
    box_deck("LC", c1_w, 106, [0, 106], "EVENTS",    [40, -12], poker_int),
    box_deck("LF", c1_w, 106, [0, 212], "CURSES",    [40, -12], poker_int), 
    
    box_deck("MB", c2_w, 106, [c1_w, 0],      "RESOURCES", [40, -12], poker_int),
    box_deck("MC", c2_w, 145.4, [c1_w, 106], "MUTATIONS",    [55, -12], tarot_int), 
    box_traits("MF", [c1_w, 251.4]),
    
    box_tokens("RB", [c1_w + c2_w, 0]),
    box_bags("RF", "SHEEP", [c1_w + c2_w, 160])
];

Make(data);