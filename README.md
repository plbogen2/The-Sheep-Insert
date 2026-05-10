# The Sheep Insert

A custom, 3D-printable modular board game insert designed using OpenSCAD and the [Boardgame Insert Toolkit (BIT)](https://github.com/IdoMagal/The-Boardgame-Insert-Toolkit).

This insert is designed specifically to fit a 9 1/4" (234.95mm) box interior and provides organized storage for cards, tokens, and character traits.

## Features & Compartments

The insert includes several modular boxes with custom lids and labels, optimized for quick setup and teardown:

*   **Deck Boxes (Poker Size):** 
    *   `EQUIPMENT`
    *   `EVENTS`
    *   `CURSES`
    *   `RESOURCES`
*   **Deck Boxes (Tarot Size):**
    *   `MUTATIONS`
*   **Trait Trays:** Dedicated 6-slot tray for character traits (`MERC`, `DOC`, `SURV`, `SGT`, `MECH`, `SCOUT`).
*   **Token Banks:** Filleted compartments for easy token retrieval:
    *   `ESSENCE` & `LANTERNS`
    *   `CORRUPTION`, `EXPERIENCE`, & `POLLUTION`
*   **Bag Storage:** A large, open compartment specifically for the `SHEEP` bag.

## Design

The project uses a custom font (`Alfa Slab One`) and features decorative lid ironwork patterns for a premium look and feel. 

## Automated Exports

This repository includes a GitHub Actions workflow (`.github/workflows/export.yml`) that automatically renders the OpenSCAD `.scad` files into `.stl` models and `.png` previews whenever changes are pushed to the main branch. The output files are saved in the `STLs/` and `PNGs/` directories respectively.
