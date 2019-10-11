# Wit Fighter

My Ludum Dare 45 entry on the theme "Start with nothing".

It is an adaptation of Monkey Island's "Insult swordfighting", a discipline two opponents would throw insults and comebacks at each other. Despite the use of swords, the result of the fight would ultimately decided by how fitting the comebacks were during the verbal joust.

In this game there are no swords, just the insults, and it takes place in an office staircase full of hateful employees. You play a hackathon organizer seeking financial support from his sister, the CEO of the company, who works at the highest floor.

The link with the theme is that initially, the player character knows no insults at all, and must learn them on the go from his opponents.

## Development log

v0.1: The current game has almost no interactions as you can only select an empty dialogue line. It consists mostly of a static screen, but was uploaded as such to have something to show for the Ludum Dare.

## Terminology

Insults are named "attacks" and comebacks are named "replies". They are both referred to as "quotes" (despite not being actual movie quotes).

## How to play

### Run the game

This game was made with [PICO-8](https://www.lexaloffle.com/pico-8.php), so there are different ways to play:
- Download the HTML5 version, or go to the [itch.io page](https://hsandt.itch.io/wit-fighter) (WIP) to play in your browser
- Download one of the release binaries to play directly on Windows, OSX, Linux
- If you own PICO-8, download the .p8 cartridge and run it inside PICO-8

### Controls

The game is played with the keyboard.

- Arrows: quote selection
- Z/C/N (O button in PICO-8): confirm selection, continue dialogue
- X/V/M (X button ins PICO-8): cancel?
- Enter: pause

## USP

I intend to add the following innovations:
- Multiple replies can work against a given attack (in Monkey Island, only the opposite is true, and only when including the boss)
- Attacks and replies have a level, which decides how much (mental) damage is dealt to the opponent
- NPCs learn your quotes

## Development notes

This game has been developed with my own framework for PICO-8, [pico-boots](https://github.com/hsandt/pico-boots).
