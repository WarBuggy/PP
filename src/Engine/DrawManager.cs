using System;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using PP.Core;

namespace PP.Engine;

public sealed class DrawManager : LoggerBaseCore
{
    private static readonly DrawManager _instance = new();
    public static DrawManager Instance => _instance;

    private readonly List<DrawRequest> _drawQueue = [];

    private Texture2D _primitiveTexture;

    private DrawManager() { }

    public void Initialize(GraphicsDeviceManager graphicsDeviceManager)
    {
        _primitiveTexture = new Texture2D(graphicsDeviceManager.GraphicsDevice, 1, 1);
        _primitiveTexture.SetData([Color.White]);
    }

    /// <summary>
    /// Adds a render request to the queue.
    /// </summary>
    public void AddRequest(DrawRequest request)
    {
        if (request == null)
            throw new LocalizedErrorCore<ArgumentNullException>("system.drawManager.requestNull");

        _drawQueue.Add(request);
    }

    /// <summary>
    /// Render all draw requests in the queue and clear it.
    /// Call this from EngineManager.Draw().
    /// </summary>
    public void RenderQueue(SpriteBatch spriteBatch)
    {
        foreach (var req in _drawQueue)
        {
            switch (req.Type)
            {
                case DrawRequestType.Sprite:
                    DrawSprite(spriteBatch, req);
                    break;

                case DrawRequestType.Rectangle:
                    DrawRectangle(spriteBatch, req);
                    break;

                default:
                    LogWarning("system.drawManager.unknownRequestType", req.Type);
                    break;
            }
        }

        _drawQueue.Clear();
    }

    private void DrawRectangle(SpriteBatch spriteBatch, DrawRequest req)
    {
        float width = GetFloatData(req, "width");
        float height = GetFloatData(req, "height");

        if (width <= 0 || height <= 0)
            return;

        spriteBatch.Draw(
            _primitiveTexture,
            new Vector2(req.X, req.Y),
            null,
            req.GetColor(),
            req.Rotation,
            new Vector2(req.PivotX, req.PivotY),
            new Vector2(width * req.ScaleX,
                        height * req.ScaleY),
            SpriteEffects.None,
            req.LayerDepth);
    }

    private static void DrawSprite(SpriteBatch spriteBatch, DrawRequest req)
    {
        int textureId = GetIntData(req, "textureId");

        if (textureId < 0)
            return;


        if (!TextureManager.Instance.TryGetTexture(textureId, out Texture2D texture))
        {
            return;
        }

        int width = GetIntData(req, "width");
        int height = GetIntData(req, "height");

        if (width <= 0 || height <= 0)
            return;

        int offsetX = GetIntData(req, "offsetX");
        int offsetY = GetIntData(req, "offsetY");

        bool flipX = GetBoolData(req, "flipX");
        bool flipY = GetBoolData(req, "flipY");

        Rectangle sourceRectangle = new(
            offsetX,
            offsetY,
            width,
            height);

        SpriteEffects effects = SpriteEffects.None;

        if (flipX)
            effects |= SpriteEffects.FlipHorizontally;

        if (flipY)
            effects |= SpriteEffects.FlipVertically;

        spriteBatch.Draw(
            texture,
            new Vector2(req.X, req.Y),
            sourceRectangle,
            req.GetColor(),
            req.Rotation,
            new Vector2(req.PivotX, req.PivotY),
            new Vector2(req.ScaleX, req.ScaleY),
            effects,
            req.LayerDepth
        );
    }

    /// <summary>
    /// A single draw request.
    /// </summary>
    public class DrawRequest
    {
        /// <summary>
        /// Determines which renderer handles this request.
        /// </summary>
        public DrawRequestType Type { get; set; }

        /// <summary>
        /// Render position.
        /// </summary>
        public float X { get; set; }
        public float Y { get; set; }

        /// <summary>
        /// Rotation in radians.
        /// </summary>
        public float Rotation { get; set; } = 0f;

        /// <summary>
        /// Global render scale.
        /// </summary>
        public float ScaleX { get; set; } = 1f;
        public float ScaleY { get; set; } = 1f;

        /// <summary>
        /// Pivot/origin point used by renderers.
        /// 
        /// Example:
        /// Sprite:
        /// {
        ///     pivotX,
        ///     pivotY
        /// }
        /// </summary>
        public float PivotX { get; set; } = 0f;
        public float PivotY { get; set; } = 0f;

        /// <summary>
        /// Color channels.
        /// </summary>
        public byte R { get; set; } = 255;
        public byte G { get; set; } = 255;
        public byte B { get; set; } = 255;
        public byte A { get; set; } = 255;

        /// <summary>
        /// Draw ordering value.
        /// </summary>
        public float LayerDepth { get; set; } = 0f;

        public Dictionary<string, object> Data { get; set; } = [];

        public Color GetColor()
        {
            return new Color(this.R, this.G, this.B, this.A);
        }
    }

    public enum DrawRequestType
    {
        Sprite,
        Rectangle,
    }

    #region Get data helpers

    private static int GetIntData(DrawRequest req, string key)
    {
        if (!req.Data.TryGetValue(key, out var value))
            return 0;

        return Convert.ToInt32(value);
    }

    private static float GetFloatData(DrawRequest req, string key)
    {
        if (!req.Data.TryGetValue(key, out var value))
            return 0f;

        return Convert.ToSingle(value);
    }

    private static bool GetBoolData(DrawRequest req, string key)
    {
        if (!req.Data.TryGetValue(key, out var value))
            return false;

        return Convert.ToBoolean(value);
    }

    #endregion
}
