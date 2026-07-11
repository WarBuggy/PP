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
    /// Adds a draw request to the queue.
    /// </summary>
    public void AddRequest(Texture2D texture, Vector2 position,
                      float rotation = 0f, Vector2 scale = default,
                      Color? color = null, float layerDepth = 0f,
                      int width = 0, int height = 0,
                      int spriteOffsetX = 0, int spriteOffsetY = 0,
                      bool flipX = false, bool flipY = false)
    {
        if (texture == null)
            throw new LocalizedErrorCore<ArgumentNullException>("system.drawManager.textureNull");

        if (scale == default)
            scale = Vector2.One;

        var sourceRect = new Rectangle(spriteOffsetX, spriteOffsetY, width, height);
        _drawQueue.Add(new DrawRequest
        {
            Texture = texture,
            Position = position,
            SourceRectangle = sourceRect,
            Rotation = rotation,
            Scale = scale,
            Color = color ?? Color.White,
            LayerDepth = layerDepth,
            FlipX = flipX,
            FlipY = flipY
        });
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
            }
        }

        _drawQueue.Clear();
    }

    public void AddRectangle(Vector2 position,
        float width, float height, float r, float g, float b, float layerDepth = 0f)
    {
        _drawQueue.Add(new DrawRequest
        {
            Type = DrawRequestType.Rectangle,
            Position = position,
            SpecialData = [width, height],
            Color = new Color((byte)r, (byte)g, (byte)b),
            LayerDepth = layerDepth
        });
    }

    private void DrawRectangle(SpriteBatch spriteBatch, DrawRequest req)
    {
        if (req.SpecialData == null || req.SpecialData.Length < 2)
            return;

        spriteBatch.Draw(
            _primitiveTexture,
            req.Position,
            null,
            req.Color,
            0f,
            Vector2.Zero,
           new Vector2(req.SpecialData[0], req.SpecialData[1]),
            SpriteEffects.None,
            req.LayerDepth
        );
    }

    private static void DrawSprite(SpriteBatch spriteBatch, DrawRequest req)
    {
        SpriteEffects effects = SpriteEffects.None;

        if (req.FlipX)
            effects |= SpriteEffects.FlipHorizontally;

        if (req.FlipY)
            effects |= SpriteEffects.FlipVertically;

        spriteBatch.Draw(
            req.Texture,
            req.Position,
            req.SourceRectangle,
            req.Color,
            req.Rotation,
            Vector2.Zero,
            req.Scale,
            effects,
            req.LayerDepth
        );
    }

    /// <summary>
    /// A single draw request.
    /// </summary>
    public class DrawRequest
    {
        public DrawRequestType Type { get; set; }
        public Texture2D Texture { get; set; } = null;
        public Vector2 Position { get; set; }
        public Rectangle SourceRectangle { get; set; }
        public float Rotation { get; set; }
        public Vector2 Scale { get; set; } = Vector2.One;
        public Color Color { get; set; } = Color.White;
        public float LayerDepth { get; set; } = 0f;
        public bool FlipX { get; set; } = false;  // new property
        public bool FlipY { get; set; } = false;  // new property

        // Shape-specific
        public float[] SpecialData { get; set; }
    }

    public enum DrawRequestType
    {
        Sprite,
        Rectangle,
        Line,
        Circle
    }
}
