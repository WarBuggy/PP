# PP
Project Paragon

# Unified Function Input/Output (UFIO)

The **Unified Function Input/Output (UFIO)** convention defines a consistent API pattern for all Lua functions in the project. Its goal is to improve readability, extensibility, and ease of use for both engine developers and modders.

## Rules

1. **Every function accepts exactly one input table.**
2. **Every function returns exactly one output table.**
3. **Use nested tables only when there are multiple logical groups of inputs and/or outputs.**

## Examples

### Single Input Group

```lua
local result = World.WorldToScreen({
    worldX = player.x,
    worldY = player.y
})

local screenX = result.screenX
local screenY = result.screenY
```

### Multiple Input Groups

```lua
local result = applyCommonRequestProperties({
    params = params,
    request = request
})

request = result.request
```

### Single Output Group

```lua
return {
    screenX = screenX,
    screenY = screenY
}
```

### Multiple Output Groups

```lua
return {
    request = request,
    metadata = metadata
}
```

## Benefits

- Consistent API across the entire project.
- Easy to extend without breaking existing code.
- Eliminates positional parameters and multiple return values.
- Makes functions easier to understand and modify.
- Reduces the learning curve for modders.
```

## Coordinate Systems

### Screen Coordinates

Screen coordinates represent a position on the display in **pixels**. The origin `(0, 0)` is located at the top-left corner of the screen. The x-axis increases to the right, and the y-axis increases downward.

### World Position

A world position represents a location within the game world in **meters**. World positions are independent of the screen resolution, camera, and zoom level. They define where objects exist in the game world rather than where they are drawn on the screen.

## Coordinate Naming Convention

To clearly distinguish between screen space and world space, the project uses the following naming convention:

- **`x` / `y`** represent screen coordinates measured in **pixels**.
- **`posX` / `posY`** represent world positions measured in **meters**.

These names may be prefixed or suffixed to provide additional context while preserving their meaning. For example:

- `mouseX`, `mouseY`
- `screenX`, `screenY`
- `playerPosX`, `playerPosY`
- `spawnPosX`, `spawnPosY`
- `targetPosX`, `targetPosY`

As long as the variable ends with **`X`/`Y`** or **`PosX`/`PosY`**, its coordinate space is immediately clear.

### Examples

```lua
-- Screen coordinates (pixels)
local mouseX = 320
local mouseY = 180

-- World position (meters)
local playerPosX = 12.5
local playerPosY = -8.0
```

Using this convention makes the coordinate space immediately clear from the variable name, reducing ambiguity and helping prevent accidental mixing of screen-space and world-space values.