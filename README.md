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