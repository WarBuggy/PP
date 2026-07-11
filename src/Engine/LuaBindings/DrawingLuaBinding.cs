using System;
using MoonSharp.Interpreter;
using Microsoft.Xna.Framework;
using AxiomPlayground.Scripting.LuaBindings;
using AxiomPlayground.Scripting;

namespace PP.Engine.LuaBindings
{
    public sealed class DrawLuaBinding : LuaBindingBase
    {
        public override void Register(Script luaScript)
        {
            ArgumentNullException.ThrowIfNull(luaScript);

            // Draw namespace table
            Table drawTable = new(luaScript);

            // AddRequest(textureId, position, rotation=0, scale={1,1}, color=nil, layerDepth=0, width=0, height=0, spriteOffsetX=0, spriteOffsetY=0)
            drawTable["AddRequest"] = (Action<DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue>)((
                textureIdDyn, positionDyn, rotationDyn, scaleDyn, colorDyn, layerDepthDyn, widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn, flipXDyn, flipYDyn) =>
            {
                string modId = ScriptManager.Instance.CurrentExecutingModId; // default to current mod
                AddRequestInternal(modId, textureIdDyn, positionDyn,
                    rotationDyn, scaleDyn, colorDyn, layerDepthDyn,
                    widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn, flipXDyn, flipYDyn);
            });

            // AddRectangle(position, width, height, r, g, b, layerDepth=0)
            drawTable["AddRectangle"] =
                (Action<DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue>)(
                (positionDyn, widthDyn, heightDyn, rDyn, gDyn, bDyn, layerDepthDyn) =>
            {
                AddRectangleInternal(
                    positionDyn,
                    widthDyn,
                    heightDyn,
                    rDyn,
                    gDyn,
                    bDyn,
                    layerDepthDyn
                );
            });

            // AddRequestFrom(modId, textureId, ...)
            // drawTable["AddRequestFrom"] = (Action<string, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue, DynValue>)((
            //     modId, textureIdDyn, positionDyn, rotationDyn, scaleDyn, colorDyn, layerDepthDyn, widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn) =>
            // {
            //     AddRequestInternal(modId, textureIdDyn, positionDyn,
            //         rotationDyn, scaleDyn, colorDyn, layerDepthDyn,
            //         widthDyn, heightDyn, spriteOffXDyn, spriteOffYDyn);
            // });

            // Register globally
            luaScript.Globals["Drawing"] = drawTable;
        }

        private static void AddRequestInternal
        (
            string modId, DynValue textureIdDyn, DynValue positionDyn, DynValue rotationDyn,
            DynValue scaleDyn, DynValue colorDyn, DynValue layerDepthDyn,
            DynValue widthDyn, DynValue heightDyn, DynValue spriteOffXDyn, DynValue spriteOffYDyn,
            DynValue flipXDyn, DynValue flipYDyn
        )
        {
            if (textureIdDyn.IsNilOrNan())
                throw new ScriptRuntimeException("[DrawLuaBinding] AddRequest expects textureId (number) as first argument.");
            int textureId = (int)textureIdDyn.Number;
            var texture = TextureManager.Instance.GetTexture(modId, textureId);

            Vector2 position = positionDyn.Type == DataType.Table
                ? new Vector2((float)positionDyn.Table.Get(1).Number, (float)positionDyn.Table.Get(2).Number)
                : Vector2.Zero;
            float rotation = (float)(rotationDyn.IsNil() ? 0f : rotationDyn.Number);
            Vector2 scale = scaleDyn.Type == DataType.Table
                ? new Vector2((float)scaleDyn.Table.Get(1).Number, (float)scaleDyn.Table.Get(2).Number)
                : Vector2.One;
            Color? color = colorDyn.IsNil() ? null : (Color?)colorDyn.ToObject();
            float layerDepth = (float)(layerDepthDyn.IsNil() ? 0f : layerDepthDyn.Number);
            int width = (int)(widthDyn.IsNil() ? 0 : widthDyn.Number);
            int height = (int)(heightDyn.IsNil() ? 0 : heightDyn.Number);
            int spriteOffsetX = (int)(spriteOffXDyn.IsNil() ? 0 : spriteOffXDyn.Number);
            int spriteOffsetY = (int)(spriteOffYDyn.IsNil() ? 0 : spriteOffYDyn.Number);

            bool flipX = !flipXDyn.IsNil() && flipXDyn.Boolean;
            bool flipY = !flipYDyn.IsNil() && flipYDyn.Boolean;

            // Call engine
            DrawManager.Instance.AddRequest(
                texture,
                position,
                rotation,
                scale,
                color,
                layerDepth,
                width,
                height,
                spriteOffsetX,
                spriteOffsetY,
                flipX,
                flipY
            );
        }

        private static void AddRectangleInternal(
            DynValue positionDyn,
            DynValue widthDyn,
            DynValue heightDyn,
            DynValue rDyn,
            DynValue gDyn,
            DynValue bDyn,
            DynValue layerDepthDyn)
        {
            Vector2 position = positionDyn.Type == DataType.Table
                ? new Vector2(
                    (float)positionDyn.Table.Get(1).Number,
                    (float)positionDyn.Table.Get(2).Number)
                : Vector2.Zero;

            float width = widthDyn.IsNil()
                ? 0f
                : (float)widthDyn.Number;

            float height = heightDyn.IsNil()
                ? 0f
                : (float)heightDyn.Number;

            float r = rDyn.IsNil() ? 255f : (float)rDyn.Number;
            float g = gDyn.IsNil() ? 255f : (float)gDyn.Number;
            float b = bDyn.IsNil() ? 255f : (float)bDyn.Number;

            float layerDepth = layerDepthDyn.IsNil()
                ? 0f
                : (float)layerDepthDyn.Number;

            DrawManager.Instance.AddRectangle(
                position,
                width,
                height,
                r, g, b,
                layerDepth
            );
        }
    }
}
